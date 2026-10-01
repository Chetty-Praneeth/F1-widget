import SwiftUI

struct StandingsView: View {
    @StateObject private var viewModel = StandingsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("STANDINGS")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(F1Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Segmented Control
            HStack(spacing: 4) {
                ForEach(StandingsViewModel.StandingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    }) {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                            .foregroundColor(viewModel.selectedTab == tab ? .white : F1Theme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.selectedTab == tab
                                    ? F1Theme.f1Red
                                    : Color.clear
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(F1Theme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Content
            if viewModel.isLoading && viewModel.driverStandings.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: F1Theme.f1Red))
                    .scaleEffect(1.3)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(F1Theme.textSecondary)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.selectedTab == .drivers {
                            ForEach(viewModel.driverStandings) { standing in
                                driverRow(standing)
                            }
                        } else {
                            ForEach(viewModel.constructorStandings) { standing in
                                constructorRow(standing)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(F1Theme.background.ignoresSafeArea())
        .onAppear { Task { await viewModel.loadStandings() } }
    }
    
    // MARK: - Driver Row
    private func driverRow(_ standing: DriverStanding) -> some View {
        let teamColor = F1Theme.teamColor(for: standing.constructors.first?.constructorId ?? "")
        let progress = standing.pointsDouble / max(viewModel.maxDriverPoints, 1)
        
        return HStack(spacing: 12) {
            // Position
            Text(standing.positionText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(standing.positionInt <= 3 ? F1Theme.accentGold : F1Theme.textSecondary)
                .frame(width: 28, alignment: .center)
            
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 4, height: 40)
            
            // Driver info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(standing.driver.givenName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(F1Theme.textSecondary)
                    Text(standing.driver.familyName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                }
                
                Text(standing.teamName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(teamColor)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(standing.points) PTS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(F1Theme.textPrimary)
                
                if standing.winsInt > 0 {
                    Text("\(standing.winsInt) WIN\(standing.winsInt > 1 ? "S" : "")")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(F1Theme.accentGold)
                        .tracking(0.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(F1Theme.cardBackground)
                
                // Points progress bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(teamColor.opacity(0.08))
                        .frame(width: geo.size.width * progress)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(F1Theme.cardBorder, lineWidth: 1)
            )
        )
    }
    
    // MARK: - Constructor Row
    private func constructorRow(_ standing: ConstructorStanding) -> some View {
        let teamColor = F1Theme.teamColor(for: standing.constructor.constructorId)
        let progress = standing.pointsDouble / max(viewModel.maxConstructorPoints, 1)
        
        return HStack(spacing: 12) {
            // Position
            Text(standing.positionText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(standing.positionInt <= 3 ? F1Theme.accentGold : F1Theme.textSecondary)
                .frame(width: 28, alignment: .center)
            
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 4, height: 40)
            
            // Team info
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.constructor.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(F1Theme.textPrimary)
                
                if let nationality = standing.constructor.nationality {
                    Text(nationality)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(F1Theme.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(standing.points) PTS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(F1Theme.textPrimary)
                
                if standing.winsInt > 0 {
                    Text("\(standing.winsInt) WIN\(standing.winsInt > 1 ? "S" : "")")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(F1Theme.accentGold)
                        .tracking(0.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(F1Theme.cardBackground)
                    
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(teamColor.opacity(0.08))
                        .frame(width: geo.size.width * progress)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(F1Theme.cardBorder, lineWidth: 1)
            )
        )
    }
}
