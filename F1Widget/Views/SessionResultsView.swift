import SwiftUI
import Combine

struct SessionResultsView: View {
    let race: Race
    @State private var qualifyingResults: [QualifyingResult] = []
    @State private var raceResults: [RaceResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: ResultTab = .qualifying
    
    enum ResultTab: String, CaseIterable {
        case qualifying = "Qualifying"
        case race = "Race"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            HStack(spacing: 4) {
                ForEach(ResultTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                            Task { await loadResults() }
                        }
                    }) {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                            .foregroundColor(selectedTab == tab ? .white : F1Theme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? F1Theme.f1Red : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(F1Theme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: F1Theme.f1Red))
                    .scaleEffect(1.3)
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(F1Theme.f1Red)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(F1Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadResults() } }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(F1Theme.f1Red)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        if selectedTab == .qualifying {
                            ForEach(qualifyingResults) { result in
                                qualifyingRow(result)
                            }
                        } else {
                            ForEach(raceResults) { result in
                                raceResultRow(result)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(F1Theme.background.ignoresSafeArea())
        .navigationTitle(race.raceName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Task { await loadResults() } }
    }
    
    // MARK: - Load Results
    private func loadResults() async {
        guard let round = race.round else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            if selectedTab == .qualifying {
                qualifyingResults = try await F1APIService.shared.fetchQualifyingResults(round: round)
            } else {
                raceResults = try await F1APIService.shared.fetchRaceResults(round: round)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Qualifying Row
    private func qualifyingRow(_ result: QualifyingResult) -> some View {
        let teamColor = F1Theme.teamColor(for: result.constructor.constructorId)
        
        return HStack(spacing: 10) {
            // Position
            Text("\(result.positionInt)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(result.positionInt <= 3 ? F1Theme.accentGold : F1Theme.textSecondary)
                .frame(width: 28, alignment: .center)
            
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 4, height: 44)
            
            // Driver
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.driver.code ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                    Text(result.driver.familyName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(F1Theme.textSecondary)
                }
                
                Text(result.constructor.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(teamColor)
            }
            
            Spacer()
            
            // Q times
            VStack(alignment: .trailing, spacing: 2) {
                if let q3 = result.q3 {
                    HStack(spacing: 4) {
                        Text("Q3")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(F1Theme.f1Red)
                        Text(q3)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(F1Theme.textPrimary)
                    }
                } else if let q2 = result.q2 {
                    HStack(spacing: 4) {
                        Text("Q2")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.orange)
                        Text(q2)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(F1Theme.textPrimary)
                    }
                } else if let q1 = result.q1, !q1.isEmpty {
                    HStack(spacing: 4) {
                        Text("Q1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(F1Theme.textTertiary)
                        Text(q1)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(F1Theme.textPrimary)
                    }
                } else {
                    Text("NO TIME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(F1Theme.textTertiary)
                }
                
                if let eliminated = result.eliminatedIn {
                    Text("OUT IN \(eliminated)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.orange)
                        .tracking(0.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(F1Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(F1Theme.cardBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Race Result Row
    private func raceResultRow(_ result: RaceResult) -> some View {
        let teamColor = F1Theme.teamColor(for: result.constructor.constructorId)
        
        return HStack(spacing: 10) {
            // Position
            if result.isRetired {
                Text("RET")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(F1Theme.f1Red)
                    .frame(width: 28, alignment: .center)
            } else {
                Text("\(result.positionInt)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(result.positionInt <= 3 ? F1Theme.accentGold : F1Theme.textSecondary)
                    .frame(width: 28, alignment: .center)
            }
            
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 4, height: 44)
            
            // Driver
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.driver.code ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                    Text(result.driver.familyName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(F1Theme.textSecondary)
                }
                
                Text(result.constructor.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(teamColor)
            }
            
            Spacer()
            
            // Time / Status
            VStack(alignment: .trailing, spacing: 2) {
                if let time = result.time {
                    Text(time.time)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(F1Theme.textPrimary)
                } else if result.isRetired {
                    Text(result.status)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(F1Theme.f1Red)
                }
                
                if result.pointsDouble > 0 {
                    Text("+\(result.points) PTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(F1Theme.accentGold)
                        .tracking(0.5)
                }
                
                if result.fastestLap?.rank == "1" {
                    HStack(spacing: 2) {
                        Circle().fill(Color.purple).frame(width: 6, height: 6)
                        Text("FASTEST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(F1Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(result.isRetired ? F1Theme.f1Red.opacity(0.2) : F1Theme.cardBorder, lineWidth: 1)
                )
        )
    }
}
