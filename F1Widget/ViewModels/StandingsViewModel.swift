import Foundation
import Combine

@MainActor
class StandingsViewModel: ObservableObject {
    @Published var driverStandings: [DriverStanding] = []
    @Published var constructorStandings: [ConstructorStanding] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab: StandingsTab = .drivers
    
    enum StandingsTab: String, CaseIterable {
        case drivers = "Drivers"
        case constructors = "Constructors"
    }
    
    func loadStandings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let drivers = F1APIService.shared.fetchDriverStandings()
            async let constructors = F1APIService.shared.fetchConstructorStandings()
            
            self.driverStandings = try await drivers
            self.constructorStandings = try await constructors
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Max points for progress bar scaling
    var maxDriverPoints: Double {
        driverStandings.first?.pointsDouble ?? 1
    }
    
    var maxConstructorPoints: Double {
        constructorStandings.first?.pointsDouble ?? 1
    }
}
