import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var circuitPoints: [SerializablePoint] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                
                if viewModel.isLoading && viewModel.nextRace == nil {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage, viewModel.nextRace == nil {
                    errorView(errorMessage)
                } else if let race = viewModel.nextRace {
                    VStack(spacing: 16) {
                        heroCountdownCard(race)
                        sessionScheduleCard(race)
                        circuitInfoCard(race)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                } else {
                    emptyStateView
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(F1Theme.background.ignoresSafeArea())
        .refreshable { await viewModel.loadData() }
        .onAppear { Task { await viewModel.loadData() } }
        .task(id: viewModel.nextRace?.circuit.circuitId) {
            guard let circuitId = viewModel.nextRace?.circuit.circuitId else {
                circuitPoints = []
                return
            }
            if let points = await CircuitMapService.shared.fetchCircuitLayout(circuitId: circuitId) {
                circuitPoints = points.map { SerializablePoint(x: $0.x, y: $0.y) }
            } else {
                circuitPoints = []
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("PIT")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(F1Theme.f1Red)
                    Text("WALL")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(F1Theme.textPrimary)
                }
                
                if let race = viewModel.nextRace, let season = race.season {
                    Text("SEASON \(season)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(F1Theme.textTertiary)
                        .tracking(2)
                }
            }
            
            Spacer()
            
            if viewModel.nextRace != nil {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("LIVE DATA")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(F1Theme.textTertiary)
                        .tracking(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(F1Theme.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Hero Countdown Card
    private func heroCountdownCard(_ race: Race) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("ROUND \(race.round ?? "—")")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(F1Theme.f1Red)
                    .tracking(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(F1Theme.f1Red.opacity(0.15))
                    .cornerRadius(6)
                Spacer()
                Text(race.countryFlag).font(.system(size: 32))
            }
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(race.raceName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(F1Theme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(F1Theme.f1Red)
                    Text(race.circuit.circuitName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(F1Theme.textSecondary)
                }
                
                if !race.locality.isEmpty {
                    Text("\(race.locality), \(race.country)")
                        .font(.system(size: 12))
                        .foregroundColor(F1Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)
            
            if let raceDate = race.raceDate {
                if raceDate > viewModel.currentDate {
                    countdownView(to: raceDate)
                } else {
                    HStack(spacing: 8) {
                        Circle().fill(F1Theme.f1Red).frame(width: 10, height: 10)
                        Text("RACE WEEKEND LIVE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(F1Theme.f1Red)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                
                HStack {
                    Image(systemName: "calendar").font(.system(size: 12)).foregroundColor(F1Theme.textTertiary)
                    Text(raceDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(F1Theme.textTertiary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(F1Theme.heroGradient)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(F1Theme.cardBorder, lineWidth: 1))
        )
    }
    
    // MARK: - Countdown
    private func countdownView(to date: Date) -> some View {
        let interval = date.timeIntervalSince(viewModel.currentDate)
        let days = max(0, Int(interval) / 86400)
        let hours = max(0, (Int(interval) % 86400) / 3600)
        let minutes = max(0, (Int(interval) % 3600) / 60)
        let seconds = max(0, Int(interval) % 60)
        
        return HStack(spacing: 10) {
            countdownBlock(value: days, label: "DAYS")
            Text(":").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.f1Red)
            countdownBlock(value: hours, label: "HRS")
            Text(":").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.f1Red)
            countdownBlock(value: minutes, label: "MIN")
            Text(":").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.f1Red)
            countdownBlock(value: seconds, label: "SEC")
        }
        .frame(maxWidth: .infinity)
    }
    
    private func countdownBlock(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(F1Theme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(F1Theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(F1Theme.background.opacity(0.6))
        .cornerRadius(10)
    }
    
    // MARK: - Session Schedule
    private func sessionScheduleCard(_ race: Race) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCHEDULE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(F1Theme.textTertiary)
                .tracking(2)
            
            ForEach(Array(race.sessions.enumerated()), id: \.offset) { index, session in
                HStack {
                    Circle()
                        .fill(session.name == "Race" ? F1Theme.f1Red : F1Theme.textTertiary)
                        .frame(width: 6, height: 6)
                    
                    Text(session.name)
                        .font(.system(size: 14, weight: session.name == "Race" ? .bold : .semibold))
                        .foregroundColor(session.name == "Race" ? F1Theme.f1Red : F1Theme.textPrimary)
                        .frame(width: 90, alignment: .leading)
                    
                    Spacer()
                    
                    if let date = session.session.sessionDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(F1Theme.textSecondary)
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(session.name == "Race" ? F1Theme.f1Red : F1Theme.textPrimary)
                        }
                    }
                    
                    if let date = session.session.sessionDate {
                        if date < viewModel.currentDate {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green.opacity(0.7))
                        } else {
                            Image(systemName: "circle")
                                .font(.system(size: 14))
                                .foregroundColor(F1Theme.textTertiary.opacity(0.4))
                        }
                    }
                }
                .padding(.vertical, 4)
                
                if index < race.sessions.count - 1 {
                    Divider().background(F1Theme.cardBorder)
                }
            }
        }
        .f1Card()
    }
    
    // MARK: - Circuit Info
    private func circuitInfoCard(_ race: Race) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 24))
                .foregroundColor(F1Theme.f1Red)
                .frame(width: 44, height: 44)
                .background(F1Theme.f1Red.opacity(0.12))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("CIRCUIT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(F1Theme.textTertiary)
                    .tracking(1.5)
                Text(race.circuit.circuitName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(F1Theme.textPrimary)
                    .lineLimit(2)
            }
            Spacer()
            
            if !circuitPoints.isEmpty {
                CircuitMapShape(points: circuitPoints)
                    .stroke(F1Theme.f1Red.opacity(0.85), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 55, height: 55)
                    .padding(.trailing, 4)
            }
        }
        .f1Card()
    }
    
    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: F1Theme.f1Red))
                .scaleEffect(1.3)
            Text("LOADING RACE DATA...")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(F1Theme.textTertiary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Error
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(F1Theme.f1Red)
            Text("Connection Error")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(F1Theme.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(F1Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: { Task { await viewModel.loadData() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(F1Theme.f1Red)
                .cornerRadius(12)
            }
        }
        .f1Card()
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }
    
    // MARK: - Empty
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.system(size: 48))
                .foregroundColor(F1Theme.textTertiary)
            Text("No Race Data")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(F1Theme.textPrimary)
            Text("Pull down to refresh")
                .font(.system(size: 13))
                .foregroundColor(F1Theme.textSecondary)
        }
        .padding(.top, 80)
    }
}
