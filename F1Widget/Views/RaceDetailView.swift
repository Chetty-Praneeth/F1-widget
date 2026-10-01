import SwiftUI

struct RaceDetailView: View {
    let race: Race
    @State private var circuitPoints: [SerializablePoint] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero Header
                VStack(spacing: 12) {
                    Text(race.countryFlag).font(.system(size: 48))
                    
                    Text(race.raceName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(F1Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("ROUND \(race.round ?? "—")")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(F1Theme.f1Red)
                        .tracking(2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(F1Theme.f1Red.opacity(0.15))
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
                // Circuit Card
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("CIRCUIT INFORMATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(F1Theme.textTertiary)
                            .tracking(2)
                    } icon: {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(F1Theme.f1Red)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(race.circuit.circuitName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(F1Theme.textPrimary)
                        
                        if !race.locality.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(F1Theme.f1Red)
                                Text("\(race.locality), \(race.country)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(F1Theme.textSecondary)
                            }
                        }
                    }
                    
                    if !circuitPoints.isEmpty {
                        HStack {
                            Spacer()
                            CircuitMapShape(points: circuitPoints)
                                .stroke(
                                    LinearGradient(
                                        colors: [F1Theme.f1Red, F1Theme.f1Red.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: F1Theme.f1Red.opacity(0.3), radius: 6, x: 0, y: 3)
                                .frame(height: 180)
                                .padding(.vertical, 10)
                            Spacer()
                        }
                    }
                    
                    if let raceDate = race.raceDate {
                        Divider().background(F1Theme.cardBorder)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(F1Theme.f1Red)
                            Text(raceDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(F1Theme.textPrimary)
                        }
                        
                        if raceDate > Date() {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 14))
                                    .foregroundColor(F1Theme.accentGold)
                                Text(F1DateFormatter.countdown(to: raceDate) + " to go")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(F1Theme.accentGold)
                            }
                        }
                    }
                }
                .f1Card()
                
                // View Results Button
                NavigationLink(destination: SessionResultsView(race: race)) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16))
                            .foregroundColor(F1Theme.accentGold)
                        Text("VIEW QUALIFYING & RACE RESULTS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(F1Theme.textPrimary)
                            .tracking(0.5)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(F1Theme.textTertiary)
                    }
                    .f1Card(gradient: true)
                }
                
                // Session Schedule
                VStack(alignment: .leading, spacing: 14) {
                    Label {
                        Text("SESSION SCHEDULE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(F1Theme.textTertiary)
                            .tracking(2)
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(F1Theme.f1Red)
                    }
                    
                    ForEach(Array(race.sessions.enumerated()), id: \.offset) { index, session in
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(session.name == "Race" ? F1Theme.f1Red : F1Theme.textTertiary)
                                .frame(width: 3, height: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.name)
                                    .font(.system(size: 15, weight: session.name == "Race" ? .bold : .semibold))
                                    .foregroundColor(session.name == "Race" ? F1Theme.f1Red : F1Theme.textPrimary)
                                
                                if let date = session.session.sessionDate {
                                    Text(F1DateFormatter.sessionDateTime(date))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(F1Theme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let date = session.session.sessionDate {
                                if date < Date() {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green.opacity(0.7))
                                } else {
                                    Text(F1DateFormatter.countdown(to: date))
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(F1Theme.textTertiary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if index < race.sessions.count - 1 {
                            Divider().background(F1Theme.cardBorder)
                        }
                    }
                }
                .f1Card()
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .background(F1Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let circuitId = race.circuit.circuitId {
                if let points = await CircuitMapService.shared.fetchCircuitLayout(circuitId: circuitId) {
                    circuitPoints = points.map { SerializablePoint(x: $0.x, y: $0.y) }
                }
            }
        }
    }
}
