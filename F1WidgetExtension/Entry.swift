import WidgetKit
import Foundation

/// A single driver position for widget display
struct WidgetDriverPosition: Codable {
    let position: Int
    let driverTla: String
    let teamColour: String
    let lastName: String
}


struct RaceEntry: TimelineEntry {
    let date: Date
    let race: Race?
    let isPlaceholder: Bool
    var widgetFamily: WidgetFamily = .systemSmall
    
    // Live session data
    var isLive: Bool = false
    var liveSessionName: String? = nil
    var driverPositions: [WidgetDriverPosition] = []
    
    // Circuit map data
    var circuitPoints: [SerializablePoint] = []
}
