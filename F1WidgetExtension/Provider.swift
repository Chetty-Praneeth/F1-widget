import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RaceEntry {
        let mockLocation = Location(lat: "-37.8497", long: "144.968", locality: "Melbourne", country: "Australia")
        let mockCircuit = Circuit(circuitId: "albert_park", circuitName: "Albert Park Grand Prix Circuit", location: mockLocation)
        let race = Race(
            season: "2026", round: "1",
            raceName: "Australian Grand Prix",
            circuit: mockCircuit,
            date: "2026-03-08", time: "04:00:00Z",
            firstPractice: Session(date: "2026-03-06", time: "01:30:00Z"),
            secondPractice: Session(date: "2026-03-06", time: "05:00:00Z"),
            thirdPractice: Session(date: "2026-03-07", time: "01:30:00Z"),
            qualifying: Session(date: "2026-03-07", time: "05:00:00Z"),
            sprint: nil,
            sprintQualifying: nil
        )
        return RaceEntry(date: Date(), race: race, isPlaceholder: true, widgetFamily: context.family)
    }

    func getSnapshot(in context: Context, completion: @escaping (RaceEntry) -> ()) {
        let race = SharedDataManager.shared.getNextRace() ?? placeholder(in: context).race
        let entry = RaceEntry(date: Date(), race: race, isPlaceholder: false, widgetFamily: context.family)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RaceEntry>) -> ()) {
        Task {
            // 1. Fetch race data
            var race: Race? = SharedDataManager.shared.getNextRace()
            
            do {
                let fetchedRace = try await F1APIService.shared.fetchNextRace()
                SharedDataManager.shared.saveNextRace(fetchedRace)
                race = fetchedRace
            } catch {
                if race == nil {
                    race = placeholder(in: context).race
                }
            }
            
            // 2. Try to fetch live positions from f1-dash
            var isLive = false
            var liveSessionName: String? = nil
            var positions: [WidgetDriverPosition] = []
            
            do {
                let results = try await F1DashService.shared.fetchLiveResults()
                let status = results.sessionStatus.lowercased()
                
                if status == "started" || status == "inactive" || status == "finished" || status == "finalised" {
                    isLive = true
                    liveSessionName = results.sessionName
                    
                    positions = results.results.prefix(5).map { result in
                        WidgetDriverPosition(
                            position: result.position,
                            driverTla: result.driverTla,
                            teamColour: result.teamColour,
                            lastName: result.lastName
                        )
                    }
                }
            } catch {
                // Not critical
            }
            
            // 3. Fetch circuit map (for medium widget)
            var circuitPoints: [SerializablePoint] = []
            if let circuitId = race?.circuit.circuitId {
                if let points = await CircuitMapService.shared.fetchCircuitLayout(circuitId: circuitId) {
                    circuitPoints = points.map { SerializablePoint(x: $0.x, y: $0.y) }
                }
            }
            
            let entry = RaceEntry(
                date: Date(),
                race: race,
                isPlaceholder: false,
                widgetFamily: context.family,
                isLive: isLive,
                liveSessionName: liveSessionName,
                driverPositions: positions,
                circuitPoints: circuitPoints
            )
            
            let refreshInterval: TimeInterval = isLive ? 15 * 60 : 6 * 60 * 60
            let nextUpdate = Date().addingTimeInterval(refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }
}
