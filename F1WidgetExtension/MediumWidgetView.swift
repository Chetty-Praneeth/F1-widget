import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    var entry: RaceEntry
    
    private let f1Red = Color(red: 0.88, green: 0.02, blue: 0.0)
    private let bgDark = Color(red: 0.08, green: 0.08, blue: 0.14)
    private let bgCard = Color(red: 0.13, green: 0.13, blue: 0.22)
    private let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.7)
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Race info
            VStack(alignment: .leading, spacing: 3) {
                // Header
                HStack(spacing: 4) {
                    if entry.isLive {
                        Circle().fill(.green).frame(width: 5, height: 5)
                        Text(entry.liveSessionName?.uppercased() ?? "LIVE")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.green)
                            .tracking(1)
                    } else {
                        Text("NEXT RACE")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(f1Red)
                            .tracking(1.5)
                    }
                }
                
                if let race = entry.race {
                    HStack(spacing: 5) {
                        Text(race.countryFlag).font(.system(size: 16))
                        Text(race.raceName.replacingOccurrences(of: "Grand Prix", with: "GP"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Text(race.circuit.circuitName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(textSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Live positions OR date
                    if entry.isLive && !entry.driverPositions.isEmpty {
                        VStack(spacing: 1) {
                            ForEach(entry.driverPositions.prefix(3), id: \.driverTla) { driver in
                                HStack(spacing: 4) {
                                    Text("P\(driver.position)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(driver.position <= 3 ? Color(red: 1.0, green: 0.84, blue: 0.0) : textSecondary)
                                        .frame(width: 16, alignment: .trailing)
                                    
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color(hex: driver.teamColour))
                                        .frame(width: 2, height: 10)
                                    
                                    Text(driver.driverTla)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        HStack {
                            if let raceDate = race.raceDate {
                                Text(raceDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(textSecondary)
                            }
                            Spacer()
                            if let round = race.round {
                                Text("R\(round)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(textSecondary)
                            }
                        }
                    }
                } else {
                    Spacer()
                    Text("Open app to refresh")
                        .font(.system(size: 11))
                        .foregroundColor(textSecondary)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            
            // Right side - Circuit Map or Countdown
            if !entry.circuitPoints.isEmpty {
                circuitMapPanel
            } else if entry.isLive && !entry.driverPositions.isEmpty {
                livePositionsPanel
            } else if let race = entry.race, let raceDate = race.raceDate, raceDate > Date() {
                countdownPanel(to: raceDate)
            }
        }
        .widgetBackground(
            ZStack {
                LinearGradient(
                    colors: [
                        entry.isLive
                            ? Color.green.opacity(0.15)
                            : Color(red: 0.88, green: 0.02, blue: 0.0).opacity(0.15),
                        bgDark
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }
    
    // MARK: - Circuit Map Panel
    private var circuitMapPanel: some View {
        VStack(spacing: 4) {
            if entry.isLive {
                // During live: show top 2 drivers above the map
                ForEach(entry.driverPositions.prefix(2), id: \.driverTla) { driver in
                    HStack(spacing: 3) {
                        Text("P\(driver.position)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(driver.position == 1 ? Color(red: 1.0, green: 0.84, blue: 0.0) : textSecondary)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: driver.teamColour))
                            .frame(width: 2, height: 8)
                        Text(driver.driverTla)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            
            // Circuit shape
            CircuitMapShape(points: entry.circuitPoints)
                .stroke(
                    entry.isLive
                        ? Color.green.opacity(0.8)
                        : f1Red.opacity(0.7),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Countdown below map when not live
            if !entry.isLive, let race = entry.race, let raceDate = race.raceDate, raceDate > Date() {
                let interval = max(0, raceDate.timeIntervalSince(Date()))
                let days = Int(interval) / 86400
                let hours = (Int(interval) % 86400) / 3600
                
                Text("\(days)D \(hours)H")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 100)
        .padding(.vertical, 10)
        .padding(.trailing, 10)
    }
    
    // MARK: - Live Positions Panel (fallback when no map)
    private var livePositionsPanel: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("TOP 5")
                .font(.system(size: 7, weight: .heavy))
                .foregroundColor(.green)
                .tracking(1.5)
                .padding(.bottom, 2)
            
            ForEach(entry.driverPositions.prefix(5), id: \.driverTla) { driver in
                HStack(spacing: 4) {
                    Text("\(driver.position)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(driver.position <= 3 ? Color(red: 1.0, green: 0.84, blue: 0.0) : textSecondary)
                        .frame(width: 12, alignment: .trailing)
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: driver.teamColour))
                        .frame(width: 2, height: 12)
                    
                    Text(driver.driverTla)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .padding(.trailing, 12)
    }
    
    // MARK: - Countdown Panel (fallback when no map)
    private func countdownPanel(to raceDate: Date) -> some View {
        VStack(spacing: 8) {
            Text("STARTS IN")
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(f1Red)
                .tracking(1.5)
            
            let interval = max(0, raceDate.timeIntervalSince(Date()))
            let days = Int(interval) / 86400
            let hours = (Int(interval) % 86400) / 3600
            let minutes = (Int(interval) % 3600) / 60
            
            VStack(spacing: 6) {
                countdownItem(value: days, label: "DAYS")
                countdownItem(value: hours, label: "HRS")
                countdownItem(value: minutes, label: "MIN")
            }
        }
        .frame(width: 80)
        .padding(.vertical, 14)
        .padding(.trailing, 14)
    }
    
    private func countdownItem(value: Int, label: String) -> some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(bgCard.opacity(0.8))
        .cornerRadius(6)
    }
}

