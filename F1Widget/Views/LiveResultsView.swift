import SwiftUI

struct LiveResultsView: View {
    @State private var dashResults: F1DashResults?
    @State private var results: [LiveSessionResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var autoRefreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Session Header
            if let info = dashResults {
                VStack(spacing: 4) {
                    Text(info.meetingName.uppercased())
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(F1Theme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(info.sessionName.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(F1Theme.f1Red)
                            .tracking(1)
                        
                        sessionStatusBadge(info.sessionStatus)
                    }
                    
                    if !info.trackStatus.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(trackStatusColor(info.trackStatus))
                                .frame(width: 6, height: 6)
                            Text(info.trackStatus.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(trackStatusColor(info.trackStatus))
                                .tracking(1)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 12)
            }
            
            if isLoading && results.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: F1Theme.f1Red))
                        .scaleEffect(1.3)
                    Text("CONNECTING TO LIVE FEED...")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(F1Theme.textTertiary)
                        .tracking(2)
                }
                Spacer()
            } else if let error = errorMessage, results.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 36))
                        .foregroundColor(F1Theme.f1Red)
                    Text("No Live Data")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(F1Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadData() } }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(F1Theme.f1Red)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                Spacer()
            } else {
                ScrollView {
                    // Source attribution
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(F1Theme.textTertiary)
                            .tracking(0.5)
                        Spacer()
                        Text("Auto-refreshing")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(F1Theme.textTertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    
                    LazyVStack(spacing: 6) {
                        ForEach(results) { result in
                            liveResultRow(result)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .refreshable { await loadData() }
            }
        }
        .background(F1Theme.background.ignoresSafeArea())
        .navigationTitle("Live")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadData() }
            startAutoRefresh()
        }
        .onDisappear { stopAutoRefresh() }
    }
    
    // MARK: - Load Data
    private func loadData() async {
        if results.isEmpty { isLoading = true }
        errorMessage = nil
        
        do {
            let dashData = try await F1DashService.shared.fetchLiveResults()
            dashResults = dashData
            results = dashData.results
        } catch {
            // Fallback to F1 live timing if f1-dash is down
            do {
                let info = try await F1LiveTimingService.shared.fetchCurrentSessionInfo()
                let index = try await F1LiveTimingService.shared.fetchSeasonIndex()
                
                if let meeting = index.meetings.first(where: { $0.key == info.meeting.key }) {
                    for session in meeting.sessions.filter({ $0.path != nil }).reversed() {
                        if let path = session.path {
                            let sessionResults = try await F1LiveTimingService.shared.fetchSessionResults(sessionPath: path)
                            if !sessionResults.isEmpty {
                                results = sessionResults
                                dashResults = F1DashResults(
                                    meetingName: info.meeting.name,
                                    sessionName: session.name,
                                    sessionStatus: info.sessionStatus ?? "Unknown",
                                    trackStatus: "",
                                    results: sessionResults
                                )
                                isLoading = false
                                return
                            }
                        }
                    }
                }
                
                errorMessage = "No session data available right now. Try again during a session."
            } catch {
                errorMessage = "Could not connect to live data feed. Check your internet and try again."
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Auto Refresh (10 seconds for live data)
    private func startAutoRefresh() {
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task { await loadData() }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    // MARK: - Track Status Color
    private func trackStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "allclear", "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        case "safetycar", "sc": return .orange
        case "vsc", "vscdeployed": return .orange
        default: return F1Theme.textTertiary
        }
    }
    
    // MARK: - Status Badge
    private func sessionStatusBadge(_ status: String) -> some View {
        let (color, icon): (Color, String) = {
            switch status.lowercased() {
            case "started": return (.green, "circle.fill")
            case "inactive": return (.orange, "clock.fill")
            case "finished", "finalised", "ends": return (.blue, "checkmark.circle.fill")
            default: return (F1Theme.textTertiary, "circle")
            }
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 6))
            Text(status.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
    
    // MARK: - Result Row
    private func liveResultRow(_ result: LiveSessionResult) -> some View {
        HStack(spacing: 10) {
            // Position
            Text("\(result.position)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(result.position <= 3 ? F1Theme.accentGold : F1Theme.textSecondary)
                .frame(width: 28, alignment: .center)
            
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(result.teamColor)
                .frame(width: 4, height: 44)
            
            // Driver info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(result.driverTla)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                    Text(result.lastName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(F1Theme.textSecondary)
                }
                
                Text(result.teamName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(result.teamColor)
            }
            
            Spacer()
            
            // Times
            VStack(alignment: .trailing, spacing: 2) {
                if let q3 = result.q3Time, !q3.isEmpty {
                    HStack(spacing: 4) {
                        Text("Q3").font(.system(size: 8, weight: .bold)).foregroundColor(F1Theme.f1Red)
                        Text(q3).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.textPrimary)
                    }
                } else if let q2 = result.q2Time, !q2.isEmpty {
                    HStack(spacing: 4) {
                        Text("Q2").font(.system(size: 8, weight: .bold)).foregroundColor(.orange)
                        Text(q2).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.textPrimary)
                    }
                } else if let q1 = result.q1Time, !q1.isEmpty {
                    HStack(spacing: 4) {
                        Text("Q1").font(.system(size: 8, weight: .bold)).foregroundColor(F1Theme.textTertiary)
                        Text(q1).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(F1Theme.textPrimary)
                    }
                } else if let best = result.bestLapTime, !best.isEmpty {
                    Text(best)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(F1Theme.textPrimary)
                } else if let gap = result.gapToLeader, !gap.isEmpty {
                    Text(gap)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(F1Theme.textSecondary)
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
}
