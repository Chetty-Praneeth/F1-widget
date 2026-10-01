import Foundation
import Combine

@MainActor
class RaceViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var liveSessionName: String?
    @Published var liveSessionStatus: String?
    
    func loadSchedule() async {
        isLoading = true
        errorMessage = nil
        
        do {
            races = try await F1APIService.shared.fetchSeasonSchedule()
            
            // Also fetch live session info from f1-dash
            await fetchLiveSession()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchLiveSession() async {
        do {
            let info = try await F1LiveTimingService.shared.fetchCurrentSessionInfo()
            liveSessionName = info.name
            liveSessionStatus = info.sessionStatus
        } catch {
            // Not critical if this fails
        }
    }
    
    /// Find next upcoming race index
    var nextRaceIndex: Int? {
        races.firstIndex { race in
            guard let date = race.raceDate else { return false }
            return date > Date()
        }
    }
    
    /// Check if a race is the currently active weekend
    func isActiveWeekend(_ race: Race) -> Bool {
        // Check if the race weekend spans the current time
        // A race weekend typically starts 2 days before the race
        guard let raceDate = race.raceDate else { return false }
        let now = Date()
        let weekendStart = Calendar.current.date(byAdding: .day, value: -2, to: raceDate) ?? raceDate
        let weekendEnd = Calendar.current.date(byAdding: .hour, value: 3, to: raceDate) ?? raceDate
        return now >= weekendStart && now <= weekendEnd
    }
}
