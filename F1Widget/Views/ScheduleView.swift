import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = RaceViewModel()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RACE CALENDAR")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(F1Theme.textPrimary)
                            Text("\(viewModel.races.count) RACES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(F1Theme.textTertiary)
                                .tracking(2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if viewModel.isLoading && viewModel.races.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: F1Theme.f1Red))
                            .scaleEffect(1.3)
                            .padding(.top, 100)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(F1Theme.textSecondary)
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.races.enumerated()), id: \.element.id) { index, race in
                                let isActive = viewModel.isActiveWeekend(race)
                                
                                VStack(spacing: 8) {
                                    NavigationLink(destination: RaceDetailView(race: race)) {
                                        raceCard(race, isNext: index == viewModel.nextRaceIndex, isLive: isActive)
                                    }
                                    
                                    // Live results quick-link for active weekend
                                    if isActive {
                                        NavigationLink(destination: LiveResultsView()) {
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(.green)
                                                    .frame(width: 6, height: 6)
                                                
                                                if let session = viewModel.liveSessionName {
                                                    Text("\(session.uppercased()) — TAP FOR LIVE RESULTS")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .tracking(1)
                                                } else {
                                                    Text("TAP FOR LIVE RESULTS")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .tracking(1)
                                                }
                                                
                                                Spacer()
                                                Image(systemName: "antenna.radiowaves.left.and.right")
                                                    .font(.system(size: 10))
                                            }
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.green.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                                .id(index)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(F1Theme.background.ignoresSafeArea())
            .refreshable { await viewModel.loadSchedule() }
            .onAppear {
                Task {
                    await viewModel.loadSchedule()
                    if let nextIndex = viewModel.nextRaceIndex {
                        withAnimation {
                            proxy.scrollTo(nextIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Race Card
    private func raceCard(_ race: Race, isNext: Bool, isLive: Bool = false) -> some View {
        HStack(spacing: 14) {
            // Round number
            VStack {
                Text("R\(race.round ?? "—")")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(isNext ? F1Theme.f1Red : F1Theme.textTertiary)
            }
            .frame(width: 36)
            
            // Race info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(race.countryFlag).font(.system(size: 16))
                    Text(race.raceName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                        .lineLimit(1)
                }
                
                Text(race.circuit.circuitName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(F1Theme.textSecondary)
                    .lineLimit(1)
                
                if !race.locality.isEmpty {
                    Text("\(race.locality), \(race.country)")
                        .font(.system(size: 11))
                        .foregroundColor(F1Theme.textTertiary)
                }
            }
            
            Spacer()
            
            // Date + status
            VStack(alignment: .trailing, spacing: 4) {
                if let date = race.raceDate {
                    Text(F1DateFormatter.shortDate(date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isNext ? F1Theme.f1Red : F1Theme.textPrimary)
                    
                    if isLive {
                        HStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .tracking(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    } else if date < Date() {
                        Text("COMPLETED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                            .tracking(1)
                    } else if isNext {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(F1Theme.f1Red)
                            .tracking(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(F1Theme.f1Red.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(F1Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isNext ? F1Theme.heroGradient : F1Theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isNext ? F1Theme.f1Red.opacity(0.3) : F1Theme.cardBorder, lineWidth: 1)
                )
        )
    }
}
