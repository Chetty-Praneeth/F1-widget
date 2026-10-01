import Foundation
import SwiftUI

/// Service for fetching data from the official F1 Live Timing API
/// Base URL: https://livetiming.formula1.com/static/
class F1LiveTimingService {
    static let shared = F1LiveTimingService()
    
    private let baseURL = "https://livetiming.formula1.com/static"
    
    // MARK: - Current Session Info
    func fetchCurrentSessionInfo() async throws -> LiveSessionInfo {
        let url = URL(string: "\(baseURL)/SessionInfo.json")!
        return try await fetchJSON(from: url)
    }
    
    // MARK: - Season Index (all meetings & sessions with paths)
    func fetchSeasonIndex(year: Int = 2026) async throws -> LiveSeasonIndex {
        let url = URL(string: "\(baseURL)/\(year)/Index.json")!
        return try await fetchJSON(from: url)
    }
    
    // MARK: - Driver List for a session
    func fetchDriverList(sessionPath: String) async throws -> [String: LiveDriver] {
        let url = URL(string: "\(baseURL)/\(sessionPath)DriverList.jsonStream")!
        let rawString = try await fetchRawString(from: url)
        
        // jsonStream format: "00:00:07.686{json_data}\r\n..."
        // We parse the FIRST line which has the complete initial driver list
        guard let firstLine = rawString.components(separatedBy: "\r\n").first,
              let jsonStart = firstLine.firstIndex(of: "{") else {
            throw F1APIError.noData("Could not parse driver list.")
        }
        
        let jsonString = String(firstLine[jsonStart...])
        let data = Data(jsonString.utf8)
        return try JSONDecoder().decode([String: LiveDriver].self, from: data)
    }
    
    // MARK: - Session Classification (final results of a completed session)
    func fetchTimingAppData(sessionPath: String) async throws -> [LiveTimingEntry] {
        let url = URL(string: "\(baseURL)/\(sessionPath)TimingAppData.jsonStream")!
        let rawString = try await fetchRawString(from: url)
        return parseTimingAppData(rawString)
    }
    
    // MARK: - Combined: Fetch qualifying/session results with driver info
    func fetchSessionResults(sessionPath: String) async throws -> [LiveSessionResult] {
        // Fetch drivers and timing in parallel
        async let driversTask = fetchDriverList(sessionPath: sessionPath)
        async let timingTask = fetchTimingAppData(sessionPath: sessionPath)
        
        let drivers = try await driversTask
        let timing = try await timingTask
        
        // Merge driver info with timing data
        var results: [LiveSessionResult] = []
        for entry in timing {
            if let driver = drivers[entry.racingNumber] {
                results.append(LiveSessionResult(
                    position: entry.position,
                    racingNumber: entry.racingNumber,
                    driverTla: driver.tla,
                    firstName: driver.firstName,
                    lastName: driver.lastName,
                    teamName: driver.teamName,
                    teamColour: driver.teamColour,
                    headshotUrl: driver.headshotUrl,
                    bestLapTime: entry.bestLapTime,
                    gapToLeader: entry.gapToLeader,
                    q1Time: entry.q1Time,
                    q2Time: entry.q2Time,
                    q3Time: entry.q3Time
                ))
            }
        }
        
        return results.sorted { $0.position < $1.position }
    }
    
    // MARK: - Helpers
    private func fetchJSON<T: Decodable>(from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // F1 JSON sometimes has BOM, strip it
        let cleanData: Data
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            cleanData = data.dropFirst(3)
        } else {
            cleanData = data
        }
        
        return try JSONDecoder().decode(T.self, from: cleanData)
    }
    
    private func fetchRawString(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Strip BOM if present
        let cleanData: Data
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            cleanData = data.dropFirst(3)
        } else {
            cleanData = data
        }
        
        guard let str = String(data: cleanData, encoding: .utf8) else {
            throw F1APIError.noData("Could not decode response.")
        }
        
        return str
    }
    
    /// Parse TimingAppData.jsonStream — incremental JSON patches
    /// The last complete state for each driver is what we want
    private func parseTimingAppData(_ raw: String) -> [LiveTimingEntry] {
        var driverData: [String: LiveTimingEntry] = [:]
        
        let lines = raw.components(separatedBy: "\r\n")
        for line in lines {
            guard !line.isEmpty,
                  let jsonStart = line.firstIndex(of: "{") else { continue }
            
            let jsonString = String(line[jsonStart...])
            
            // Try to parse the Lines data which has driver timing
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let linesData = json["Lines"] as? [String: Any] else { continue }
            
            for (number, driverInfo) in linesData {
                guard let info = driverInfo as? [String: Any] else { continue }
                
                var entry = driverData[number] ?? LiveTimingEntry(racingNumber: number)
                
                if let pos = info["Position"] as? String, let p = Int(pos) {
                    entry.position = p
                }
                if let pos = info["Position"] as? Int {
                    entry.position = pos
                }
                if let bestLap = info["BestLapTime"] as? [String: Any],
                   let value = bestLap["Value"] as? String {
                    entry.bestLapTime = value
                }
                if let gap = info["GapToLeader"] as? String {
                    entry.gapToLeader = gap
                }
                
                // Qualifying-specific times
                if let stats = info["Stats"] as? [[String: Any]] {
                    for stat in stats {
                        if let value = stat["BestLapTime"] as? String, !value.isEmpty {
                            if stat.keys.contains("TimeDiffToFastest") || stat.keys.contains("TimeDifftoPositionAhead") {
                                // Stats array: index 0=Q1, 1=Q2, 2=Q3
                            }
                        }
                    }
                }
                
                // Try BestLapTimes for qualifying
                if let bestLapTimes = info["BestLapTimes"] as? [String: [String: Any]] {
                    if let q1 = bestLapTimes["0"], let val = q1["Value"] as? String { entry.q1Time = val }
                    if let q2 = bestLapTimes["1"], let val = q2["Value"] as? String { entry.q2Time = val }
                    if let q3 = bestLapTimes["2"], let val = q3["Value"] as? String { entry.q3Time = val }
                }
                
                driverData[number] = entry
            }
        }
        
        return Array(driverData.values)
    }
}

// MARK: - Live Timing Models
struct LiveSessionInfo: Codable {
    let meeting: LiveMeeting
    let sessionStatus: String?
    let archiveStatus: LiveArchiveStatus?
    let key: Int
    let type: String
    let name: String
    let startDate: String
    let endDate: String
    let gmtOffset: String
    let path: String?
    
    enum CodingKeys: String, CodingKey {
        case meeting = "Meeting"
        case sessionStatus = "SessionStatus"
        case archiveStatus = "ArchiveStatus"
        case key = "Key"
        case type = "Type"
        case name = "Name"
        case startDate = "StartDate"
        case endDate = "EndDate"
        case gmtOffset = "GmtOffset"
        case path = "Path"
    }
}

struct LiveMeeting: Codable {
    let key: Int
    let name: String
    let officialName: String
    let location: String
    let number: Int
    let country: LiveCountry
    let circuit: LiveCircuit
    
    enum CodingKeys: String, CodingKey {
        case key = "Key", name = "Name", officialName = "OfficialName"
        case location = "Location", number = "Number"
        case country = "Country", circuit = "Circuit"
    }
}

struct LiveCountry: Codable {
    let key: Int
    let code: String
    let name: String
    enum CodingKeys: String, CodingKey { case key = "Key", code = "Code", name = "Name" }
}

struct LiveCircuit: Codable {
    let key: Int
    let shortName: String
    enum CodingKeys: String, CodingKey { case key = "Key", shortName = "ShortName" }
}

struct LiveArchiveStatus: Codable {
    let status: String
    enum CodingKeys: String, CodingKey { case status = "Status" }
}

struct LiveSeasonIndex: Codable {
    let year: Int
    let meetings: [LiveMeetingIndex]
    
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case meetings = "Meetings"
    }
}

struct LiveMeetingIndex: Codable {
    let sessions: [LiveSessionIndex]
    let key: Int
    let name: String
    let location: String
    let officialName: String
    let country: LiveCountry
    
    enum CodingKeys: String, CodingKey {
        case sessions = "Sessions", key = "Key", name = "Name"
        case location = "Location", officialName = "OfficialName"
        case country = "Country"
    }
}

struct LiveSessionIndex: Codable {
    let key: Int
    let type: String
    let name: String
    let startDate: String
    let endDate: String
    let gmtOffset: String
    let path: String?
    
    enum CodingKeys: String, CodingKey {
        case key = "Key", type = "Type", name = "Name"
        case startDate = "StartDate", endDate = "EndDate"
        case gmtOffset = "GmtOffset", path = "Path"
    }
}

struct LiveDriver: Codable {
    let racingNumber: String
    let broadcastName: String
    let fullName: String
    let tla: String
    let teamName: String
    let teamColour: String
    let firstName: String
    let lastName: String
    let headshotUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case racingNumber = "RacingNumber"
        case broadcastName = "BroadcastName"
        case fullName = "FullName"
        case tla = "Tla"
        case teamName = "TeamName"
        case teamColour = "TeamColour"
        case firstName = "FirstName"
        case lastName = "LastName"
        case headshotUrl = "HeadshotUrl"
    }
}

struct LiveTimingEntry {
    var racingNumber: String
    var position: Int = 0
    var bestLapTime: String?
    var gapToLeader: String?
    var q1Time: String?
    var q2Time: String?
    var q3Time: String?
}

struct LiveSessionResult: Identifiable {
    let id = UUID()
    let position: Int
    let racingNumber: String
    let driverTla: String
    let firstName: String
    let lastName: String
    let teamName: String
    let teamColour: String
    let headshotUrl: String?
    let bestLapTime: String?
    let gapToLeader: String?
    let q1Time: String?
    let q2Time: String?
    let q3Time: String?
    
    var teamColor: Color {
        Color(hex: teamColour)
    }
}

// MARK: - Color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
