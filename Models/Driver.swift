import Foundation

// MARK: - Driver Model
struct Driver: Codable, Identifiable {
    let driverId: String
    let permanentNumber: String?
    let code: String?
    let givenName: String
    let familyName: String
    let dateOfBirth: String?
    let nationality: String?
    
    var id: String { driverId }
    
    var fullName: String {
        "\(givenName) \(familyName)"
    }
    
    var initials: String {
        let first = givenName.prefix(1)
        let last = familyName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Constructor Model
struct Constructor: Codable, Identifiable {
    let constructorId: String
    let name: String
    let nationality: String?
    
    var id: String { constructorId }
    
    /// Team color based on constructor ID
    var teamColorHex: String {
        let colors: [String: String] = [
            "mclaren": "#FF8000",
            "red_bull": "#3671C6",
            "ferrari": "#E8002D",
            "mercedes": "#0cffd7ff",
            "aston_martin": "#229971",
            "alpine": "#FF87BC",
            "williams": "#64C4FF",
            "rb": "#6692FF",
            "Audi": "#52E252",
            "cadillac": "#ffffffff",
            "haas": "#B6BABD"
        ]
        return colors[constructorId] ?? "#FFFFFF"
    }
}

// MARK: - Driver Standing
struct DriverStanding: Codable, Identifiable {
    let position: String?
    let positionText: String
    let points: String
    let wins: String
    let driver: Driver
    let constructors: [Constructor]
    
    var id: String { driver.driverId }
    
    var positionInt: Int { Int(position ?? "") ?? 99 }
    var pointsDouble: Double { Double(points) ?? 0 }
    var winsInt: Int { Int(wins) ?? 0 }
    
    var teamName: String {
        constructors.first?.name ?? "Unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case position, positionText, points, wins
        case driver = "Driver"
        case constructors = "Constructors"
    }
}

// MARK: - Constructor Standing
struct ConstructorStanding: Codable, Identifiable {
    let position: String?
    let positionText: String
    let points: String
    let wins: String
    let constructor: Constructor
    
    var id: String { constructor.constructorId }
    
    var positionInt: Int { Int(position ?? "") ?? 99 }
    var pointsDouble: Double { Double(points) ?? 0 }
    var winsInt: Int { Int(wins) ?? 0 }
    
    enum CodingKeys: String, CodingKey {
        case position, positionText, points, wins
        case constructor = "Constructor"
    }
}

// MARK: - Standings API Response Models
struct StandingsResponse: Codable {
    let mrData: StandingsMRData
    
    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct StandingsMRData: Codable {
    let standingsTable: StandingsTable
    
    enum CodingKeys: String, CodingKey {
        case standingsTable = "StandingsTable"
    }
}

struct StandingsTable: Codable {
    let season: String?
    let round: String?
    let standingsLists: [StandingsList]
    
    enum CodingKeys: String, CodingKey {
        case season, round
        case standingsLists = "StandingsLists"
    }
}

struct StandingsList: Codable {
    let season: String?
    let round: String?
    let driverStandings: [DriverStanding]?
    let constructorStandings: [ConstructorStanding]?
    
    enum CodingKeys: String, CodingKey {
        case season, round
        case driverStandings = "DriverStandings"
        case constructorStandings = "ConstructorStandings"
    }
}
