import Foundation
import SwiftUI
import WidgetKit
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var nextRace: Race?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentDate = Date()
    
    private var timer: Timer?
    
    init() {
        startCountdownTimer()
    }
    
    func loadData() async {
        // Load cache first
        nextRace = SharedDataManager.shared.getNextRace()
        
        // Fetch from API
        isLoading = true
        errorMessage = nil
        
        do {
            let race = try await F1APIService.shared.fetchNextRace()
            self.nextRace = race
            SharedDataManager.shared.saveNextRace(race)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            if nextRace == nil {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.currentDate = Date()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
