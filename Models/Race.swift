import Foundation

// MARK: - API Response Models
struct ErgastResponse: Codable {
    let mrData: MRData
    
    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct MRData: Codable {
    let raceTable: RaceTable
    
    enum CodingKeys: String, CodingKey {
        case raceTable = "RaceTable"
    }
}

struct RaceTable: Codable {
    let season: String?
    let round: String?
    let races: [Race]
    
    enum CodingKeys: String, CodingKey {
        case season
        case round
        case races = "Races"
    }
}

// MARK: - Location Model
struct Location: Codable {
    let lat: String?
    let long: String?
    let locality: String
    let country: String
}

// MARK: - Circuit Model
struct Circuit: Codable {
    let circuitId: String?
    let circuitName: String
    let location: Location?
    
    enum CodingKeys: String, CodingKey {
        case circuitId
        case circuitName
        case location = "Location"
    }
}

// MARK: - Session Model
struct Session: Codable {
    let date: String
    let time: String?
    
    var sessionDate: Date? {
        let formatter = ISO8601DateFormatter()
        if let time = time {
            return formatter.date(from: "\(date)T\(time)")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        }
    }
}

// MARK: - Race Model
struct Race: Codable, Identifiable {
    let id = UUID()
    let season: String?
    let round: String?
    let raceName: String
    let circuit: Circuit
    let date: String
    let time: String?
    let firstPractice: Session?
    let secondPractice: Session?
    let thirdPractice: Session?
    let qualifying: Session?
    let sprint: Session?
    let sprintQualifying: Session?
    
    enum CodingKeys: String, CodingKey {
        case season, round, raceName, date, time
        case circuit = "Circuit"
        case firstPractice = "FirstPractice"
        case secondPractice = "SecondPractice"
        case thirdPractice = "ThirdPractice"
        case qualifying = "Qualifying"
        case sprint = "Sprint"
        case sprintQualifying = "SprintQualifying"
    }
    
    var raceDate: Date? {
        let formatter = ISO8601DateFormatter()
        if let time = time {
            return formatter.date(from: "\(date)T\(time)")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        }
    }
    
    /// Country flag emoji from country name
    var countryFlag: String {
        guard let country = circuit.location?.country else { return "🏁" }
        let flags: [String: String] = [
            "Australia": "🇦🇺", "Bahrain": "🇧🇭", "Saudi Arabia": "🇸🇦",
            "Japan": "🇯🇵", "China": "🇨🇳", "USA": "🇺🇸",
            "Italy": "🇮🇹", "Monaco": "🇲🇨", "Canada": "🇨🇦",
            "Spain": "🇪🇸", "Austria": "🇦🇹", "UK": "🇬🇧",
            "Hungary": "🇭🇺", "Belgium": "🇧🇪", "Netherlands": "🇳🇱",
            "Azerbaijan": "🇦🇿", "Singapore": "🇸🇬", "Mexico": "🇲🇽",
            "Brazil": "🇧🇷", "UAE": "🇦🇪", "Qatar": "🇶🇦",
            "United States": "🇺🇸", "Great Britain": "🇬🇧"
        ]
        return flags[country] ?? "🏁"
    }
    
    /// Locality name (city)
    var locality: String {
        circuit.location?.locality ?? ""
    }
    
    /// Country name
    var country: String {
        circuit.location?.country ?? ""
    }
    
    /// Days until race
    var daysUntilRace: Int? {
        guard let raceDate = raceDate else { return nil }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: raceDate)
        return components.day
    }
    
    /// Countdown components (days, hours, minutes, seconds)
    var countdownComponents: (days: Int, hours: Int, minutes: Int, seconds: Int)? {
        guard let raceDate = raceDate else { return nil }
        let interval = raceDate.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return (days, hours, minutes, seconds)
    }
    
    /// All sessions in chronological order
    var sessions: [(name: String, session: Session)] {
        var result: [(String, Session)] = []
        if let fp1 = firstPractice { result.append(("FP1", fp1)) }
        if let fp2 = secondPractice { result.append(("FP2", fp2)) }
        if let fp3 = thirdPractice { result.append(("FP3", fp3)) }
        if let sq = sprintQualifying { result.append(("Sprint Quali", sq)) }
        if let sprint = sprint { result.append(("Sprint", sprint)) }
        if let qual = qualifying { result.append(("Qualifying", qual)) }
        // Add race itself as a session
        let raceSession = Session(date: date, time: time)
        result.append(("Race", raceSession))
        return result.sorted { ($0.1.sessionDate ?? .distantFuture) < ($1.1.sessionDate ?? .distantFuture) }
    }
}
