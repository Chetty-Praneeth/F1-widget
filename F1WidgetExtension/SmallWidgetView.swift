import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    var entry: RaceEntry
    
    private let f1Red = Color(red: 0.88, green: 0.02, blue: 0.0)
    private let bgDark = Color(red: 0.08, green: 0.08, blue: 0.14)
    private let bgCard = Color(red: 0.13, green: 0.13, blue: 0.22)
    private let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.isLive && !entry.driverPositions.isEmpty {
                liveContent
            } else {
                countdownContent
            }
        }
        .padding(14)
        .widgetBackground(
            LinearGradient(
                colors: [
                    entry.isLive
                        ? Color.green.opacity(0.2)
                        : Color(red: 0.88, green: 0.02, blue: 0.0).opacity(0.2),
                    bgDark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Live Content (driver positions)
    private var liveContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: LIVE + Session name
            HStack {
                HStack(spacing: 3) {
                    Circle().fill(.green).frame(width: 5, height: 5)
                    Text(entry.liveSessionName?.uppercased() ?? "LIVE")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.green)
                        .tracking(1)
                }
                
                Spacer()
                
                if let race = entry.race {
                    Text(race.countryFlag).font(.system(size: 14))
                }
            }
            .padding(.bottom, 4)
            
            // Race name
            if let race = entry.race {
                Text(race.raceName.replacingOccurrences(of: "Grand Prix", with: "GP"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.bottom, 4)
            }
            
            // Driver positions (top 5)
            VStack(spacing: 2) {
                ForEach(entry.driverPositions.prefix(5), id: \.driverTla) { driver in
                    HStack(spacing: 6) {
                        Text("\(driver.position)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(driver.position <= 3 ? Color(red: 1.0, green: 0.84, blue: 0.0) : textSecondary)
                            .frame(width: 14, alignment: .trailing)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: driver.teamColour))
                            .frame(width: 3, height: 12)
                        
                        Text(driver.driverTla)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
    
    // MARK: - Countdown Content (default)
    private var countdownContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: NEXT RACE + Flag
            HStack {
                Text("NEXT RACE")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(f1Red)
                    .tracking(1.5)
                
                Spacer()
                
                if let race = entry.race {
                    Text(race.countryFlag)
                        .font(.system(size: 18))
                }
            }
            .padding(.bottom, 6)
            
            if let race = entry.race {
                // Race name
                Text(race.raceName.replacingOccurrences(of: "Grand Prix", with: "GP"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                
                // Circuit name
                Text(race.circuit.circuitName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(textSecondary)
                    .lineLimit(1)
                    .padding(.top, 1)
                
                // Location
                if !race.locality.isEmpty {
                    Text("\(race.locality), \(race.country)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(textSecondary.opacity(0.7))
                }
                
                Spacer()
                
                // Countdown
                if let raceDate = race.raceDate {
                    if raceDate > Date() {
                        countdownView(to: raceDate)
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(f1Red).frame(width: 6, height: 6)
                            Text("RACE WEEK")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(f1Red)
                                .tracking(1)
                        }
                    }
                }
                
                // Round
                if let round = race.round {
                    Text("ROUND \(round)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(textSecondary)
                        .tracking(1.5)
                        .padding(.top, 4)
                }
            } else {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                    Text("Open app\nto refresh")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }
    
    // MARK: - Countdown
    private func countdownView(to date: Date) -> some View {
        let interval = max(0, date.timeIntervalSince(Date()))
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        return HStack(spacing: 4) {
            miniCountdownBlock(value: days, label: "D")
            Text(":")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(f1Red.opacity(0.8))
            miniCountdownBlock(value: hours, label: "H")
            Text(":")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(f1Red.opacity(0.8))
            miniCountdownBlock(value: minutes, label: "M")
        }
    }
    
    private func miniCountdownBlock(value: Int, label: String) -> some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
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

extension View {
    func widgetBackground(_ background: some View) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(for: .widget) {
                background
            }
        } else {
            return self.background(background)
        }
    }
}
