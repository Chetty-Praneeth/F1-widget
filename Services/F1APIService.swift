import Foundation

class F1APIService {
    static let shared = F1APIService()
    
    private let baseURL = "https://api.jolpi.ca/ergast/f1"
    
    // MARK: - Generic Fetch
    private func fetch<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Next Race
    func fetchNextRace() async throws -> Race {
        let url = URL(string: "\(baseURL)/current/next.json")!
        let response: ErgastResponse = try await fetch(url: url)
        
        guard let race = response.mrData.raceTable.races.first else {
            throw F1APIError.noData("No upcoming races found.")
        }
        
        return race
    }
    
    // MARK: - Season Schedule
    func fetchSeasonSchedule() async throws -> [Race] {
        let url = URL(string: "\(baseURL)/current.json")!
        let response: ErgastResponse = try await fetch(url: url)
        return response.mrData.raceTable.races
    }
    
    // MARK: - Driver Standings (2026 only)
    func fetchDriverStandings() async throws -> [DriverStanding] {
        let url = URL(string: "\(baseURL)/current/driverStandings.json")!
        let response: StandingsResponse = try await fetch(url: url)
        
        guard let standings = response.mrData.standingsTable.standingsLists.first?.driverStandings,
              !standings.isEmpty else {
            throw F1APIError.noData("No standings yet — check back after the first race.")
        }
        
        return standings
    }
    
    // MARK: - Constructor Standings (2026 only)
    func fetchConstructorStandings() async throws -> [ConstructorStanding] {
        let url = URL(string: "\(baseURL)/current/constructorStandings.json")!
        let response: StandingsResponse = try await fetch(url: url)
        
        guard let standings = response.mrData.standingsTable.standingsLists.first?.constructorStandings,
              !standings.isEmpty else {
            throw F1APIError.noData("No standings yet — check back after the first race.")
        }
        
        return standings
    }
    
    // MARK: - Qualifying Results (2026 only)
    func fetchQualifyingResults(season: String = "current", round: String) async throws -> [QualifyingResult] {
        let url = URL(string: "\(baseURL)/\(season)/\(round)/qualifying.json")!
        let response: QualifyingResponse = try await fetch(url: url)
        
        guard let results = response.mrData.raceTable.races.first?.qualifyingResults,
              !results.isEmpty else {
            throw F1APIError.noData("Qualifying results not yet available — try refreshing soon.")
        }
        
        return results
    }
    
    // MARK: - Race Results (2026 only)
    func fetchRaceResults(season: String = "current", round: String) async throws -> [RaceResult] {
        let url = URL(string: "\(baseURL)/\(season)/\(round)/results.json")!
        let response: ResultsResponse = try await fetch(url: url)
        
        guard let results = response.mrData.raceTable.races.first?.results,
              !results.isEmpty else {
            throw F1APIError.noData("Race results not yet available — try refreshing soon.")
        }
        
        return results
    }
}

// MARK: - Error Types
enum F1APIError: LocalizedError {
    case noData(String)
    
    var errorDescription: String? {
        switch self {
        case .noData(let message):
            return message
        }
    }
}
