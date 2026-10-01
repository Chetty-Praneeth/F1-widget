import Foundation
import SwiftUI

/// Service that connects to f1-dash.com's public realtime API
/// Source: https://github.com/slowlydev/f1-dash
///
/// Endpoints:
///   GET /api/current  → full JSON state snapshot (TimingData, DriverList, SessionInfo, etc.)
///   GET /api/drivers  → array of drivers with team info
///   GET /api/realtime → SSE stream with incremental updates
class F1DashService {
    static let shared = F1DashService()
    
    private let baseURL = "https://rt-api.f1-dash.com"
    
    // MARK: - Fetch Drivers
    func fetchDrivers() async throws -> [F1DashDriver] {
        let url = URL(string: "\(baseURL)/api/drivers")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw F1APIError.noData("f1-dash drivers endpoint unavailable.")
        }
        
        return try JSONDecoder().decode([F1DashDriver].self, from: data)
    }
    
    // MARK: - Fetch Current State (full snapshot)
    func fetchCurrentState() async throws -> F1DashState {
        let url = URL(string: "\(baseURL)/api/current")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw F1APIError.noData("f1-dash current state endpoint unavailable.")
        }
        
        // The state is a large JSON object — we parse it into our model
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return F1DashState(json: json)
    }
    
    // MARK: - Build ordered results from state
    func fetchLiveResults() async throws -> F1DashResults {
        let state = try await fetchCurrentState()
        
        // Extract session info
        let sessionName = state.sessionName
        let meetingName = state.meetingName
        let trackStatus = state.trackStatus
        let sessionStatus = state.sessionStatus
        
        // Build driver results from TimingData
        var results: [LiveSessionResult] = []
        
        for (number, timing) in state.timingData {
            let driver = state.driverList[number]
            
            let result = LiveSessionResult(
                position: timing.position,
                racingNumber: number,
                driverTla: driver?.tla ?? "???",
                firstName: driver?.firstName ?? "",
                lastName: driver?.lastName ?? "",
                teamName: driver?.teamName ?? "",
                teamColour: driver?.teamColour ?? "FFFFFF",
                headshotUrl: driver?.headshotUrl,
                bestLapTime: timing.bestLapTime,
                gapToLeader: timing.gapToLeader,
                q1Time: timing.q1Time,
                q2Time: timing.q2Time,
                q3Time: timing.q3Time
            )
            results.append(result)
        }
        
        results.sort { $0.position < $1.position }
        
        return F1DashResults(
            meetingName: meetingName,
            sessionName: sessionName,
            sessionStatus: sessionStatus,
            trackStatus: trackStatus,
            results: results
        )
    }
}

// MARK: - Models

struct F1DashDriver: Codable, Identifiable {
    let racingNumber: String?
    let broadcastName: String?
    let fullName: String?
    let tla: String?
    let teamName: String?
    let teamColour: String?
    let firstName: String?
    let lastName: String?
    let headshotUrl: String?
    
    var id: String { racingNumber ?? UUID().uuidString }
    
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

struct F1DashResults {
    let meetingName: String
    let sessionName: String
    let sessionStatus: String
    let trackStatus: String
    let results: [LiveSessionResult]
}

// MARK: - State Parsing from raw JSON

struct F1DashTimingEntry {
    var position: Int = 0
    var bestLapTime: String?
    var gapToLeader: String?
    var q1Time: String?
    var q2Time: String?
    var q3Time: String?
}

struct F1DashState {
    let json: [String: Any]
    
    var meetingName: String {
        if let sessionInfo = json["SessionInfo"] as? [String: Any],
           let meeting = sessionInfo["Meeting"] as? [String: Any],
           let name = meeting["Name"] as? String {
            return name
        }
        return "Formula 1"
    }
    
    var sessionName: String {
        if let sessionInfo = json["SessionInfo"] as? [String: Any],
           let name = sessionInfo["Name"] as? String {
            return name
        }
        return "Session"
    }
    
    var sessionStatus: String {
        if let status = json["SessionStatus"] as? [String: Any],
           let statusStr = status["Status"] as? String {
            return statusStr
        }
        return "Unknown"
    }
    
    var trackStatus: String {
        if let track = json["TrackStatus"] as? [String: Any],
           let message = track["Message"] as? String {
            return message
        }
        return ""
    }
    
    var driverList: [String: F1DashDriver] {
        guard let dl = json["DriverList"] as? [String: Any] else { return [:] }
        
        var drivers: [String: F1DashDriver] = [:]
        for (key, value) in dl {
            guard let driverDict = value as? [String: Any] else { continue }
            
            drivers[key] = F1DashDriver(
                racingNumber: driverDict["RacingNumber"] as? String,
                broadcastName: driverDict["BroadcastName"] as? String,
                fullName: driverDict["FullName"] as? String,
                tla: driverDict["Tla"] as? String,
                teamName: driverDict["TeamName"] as? String,
                teamColour: driverDict["TeamColour"] as? String,
                firstName: driverDict["FirstName"] as? String,
                lastName: driverDict["LastName"] as? String,
                headshotUrl: driverDict["HeadshotUrl"] as? String
            )
        }
        return drivers
    }
    
    var timingData: [String: F1DashTimingEntry] {
        guard let td = json["TimingData"] as? [String: Any],
              let lines = td["Lines"] as? [String: Any] else { return [:] }
        
        var entries: [String: F1DashTimingEntry] = [:]
        
        for (number, value) in lines {
            guard let line = value as? [String: Any] else { continue }
            
            var entry = F1DashTimingEntry()
            
            // Position
            if let pos = line["Position"] as? String, let p = Int(pos) {
                entry.position = p
            } else if let pos = line["Position"] as? Int {
                entry.position = pos
            }
            
            // Best lap
            if let best = line["BestLapTime"] as? [String: Any],
               let val = best["Value"] as? String, !val.isEmpty {
                entry.bestLapTime = val
            }
            
            // Gap
            if let gap = line["TimeDiffToFastest"] as? String, !gap.isEmpty {
                entry.gapToLeader = gap
            } else if let gap = line["GapToLeader"] as? String, !gap.isEmpty {
                entry.gapToLeader = gap
            }
            
            // Qualifying times
            if let stats = line["Stats"] as? [[String: Any]] {
                // Stats array: [Q1, Q2, Q3] each with BestLapTime
                if stats.count > 0, let val = stats[0]["BestLapTime"] as? String, !val.isEmpty {
                    entry.q1Time = val
                }
                if stats.count > 1, let val = stats[1]["BestLapTime"] as? String, !val.isEmpty {
                    entry.q2Time = val
                }
                if stats.count > 2, let val = stats[2]["BestLapTime"] as? String, !val.isEmpty {
                    entry.q3Time = val
                }
            }
            
            // Also check BestLapTimes dict (alternative format)
            if let bestLapTimes = line["BestLapTimes"] as? [String: [String: Any]] {
                if let q1 = bestLapTimes["0"], let val = q1["Value"] as? String, !val.isEmpty { entry.q1Time = val }
                if let q2 = bestLapTimes["1"], let val = q2["Value"] as? String, !val.isEmpty { entry.q2Time = val }
                if let q3 = bestLapTimes["2"], let val = q3["Value"] as? String, !val.isEmpty { entry.q3Time = val }
            }
            
            entries[number] = entry
        }
        
        return entries
    }
}
