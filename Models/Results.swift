import Foundation

// MARK: - Qualifying Result
struct QualifyingResult: Codable, Identifiable {
    let number: String
    let position: String
    let driver: Driver
    let constructor: Constructor
    let q1: String?
    let q2: String?
    let q3: String?
    
    var id: String { driver.driverId }
    var positionInt: Int { Int(position) ?? 0 }
    
    enum CodingKeys: String, CodingKey {
        case number, position
        case driver = "Driver"
        case constructor = "Constructor"
        case q1 = "Q1"
        case q2 = "Q2"
        case q3 = "Q3"
    }
    
    /// Best qualifying time
    var bestTime: String? {
        q3 ?? q2 ?? q1
    }
    
    /// Which qualifying session the driver was eliminated in
    var eliminatedIn: String? {
        if q3 != nil { return nil } // Made it to Q3
        if q2 != nil { return "Q2" }
        if q1 != nil { return "Q1" }
        return nil
    }
}

// MARK: - Race Result
struct RaceResult: Codable, Identifiable {
    let number: String
    let position: String
    let positionText: String
    let points: String
    let driver: Driver
    let constructor: Constructor
    let grid: String?
    let laps: String
    let status: String
    let time: RaceTime?
    let fastestLap: FastestLap?
    
    var id: String { driver.driverId }
    var positionInt: Int { Int(position) ?? 0 }
    var pointsDouble: Double { Double(points) ?? 0 }
    
    enum CodingKeys: String, CodingKey {
        case number, position, positionText, points, grid, laps, status
        case driver = "Driver"
        case constructor = "Constructor"
        case time = "Time"
        case fastestLap = "FastestLap"
    }
    
    var isRetired: Bool { positionText == "R" }
}

struct RaceTime: Codable {
    let millis: String?
    let time: String
}

struct FastestLap: Codable {
    let rank: String?
    let lap: String?
    let time: FastestLapTime?
    
    enum CodingKeys: String, CodingKey {
        case rank, lap
        case time = "Time"
    }
}

struct FastestLapTime: Codable {
    let time: String
}

// MARK: - API Response Wrappers
struct QualifyingResponse: Codable {
    let mrData: QualifyingMRData
    enum CodingKeys: String, CodingKey { case mrData = "MRData" }
}

struct QualifyingMRData: Codable {
    let raceTable: QualifyingRaceTable
    enum CodingKeys: String, CodingKey { case raceTable = "RaceTable" }
}

struct QualifyingRaceTable: Codable {
    let races: [QualifyingRace]
    enum CodingKeys: String, CodingKey { case races = "Races" }
}

struct QualifyingRace: Codable {
    let raceName: String
    let qualifyingResults: [QualifyingResult]?
    enum CodingKeys: String, CodingKey {
        case raceName
        case qualifyingResults = "QualifyingResults"
    }
}

struct ResultsResponse: Codable {
    let mrData: ResultsMRData
    enum CodingKeys: String, CodingKey { case mrData = "MRData" }
}

struct ResultsMRData: Codable {
    let raceTable: ResultsRaceTable
    enum CodingKeys: String, CodingKey { case raceTable = "RaceTable" }
}

struct ResultsRaceTable: Codable {
    let races: [ResultsRace]
    enum CodingKeys: String, CodingKey { case races = "Races" }
}

struct ResultsRace: Codable {
    let raceName: String
    let results: [RaceResult]?
    enum CodingKeys: String, CodingKey {
        case raceName
        case results = "Results"
    }
}
