import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    
    // App Group must be configured in Xcode under Signing & Capabilities for BOTH targets
    private let appGroupID = "group.com.praneeth.F1Widget"
    private let nextRaceKey = "nextRaceData"
    
    // Fall back to standard defaults if app group isn't setup during early development
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }
    
    func saveNextRace(_ race: Race) {
        if let encoded = try? JSONEncoder().encode(race) {
            userDefaults.set(encoded, forKey: nextRaceKey)
        }
    }
    
    func getNextRace() -> Race? {
        if let data = userDefaults.data(forKey: nextRaceKey),
           let race = try? JSONDecoder().decode(Race.self, from: data) {
            return race
        }
        return nil
    }
}

