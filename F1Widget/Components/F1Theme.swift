import SwiftUI

// MARK: - F1 Design System
struct F1Theme {
    // MARK: - Colors
    static let background = Color(red: 0.06, green: 0.06, blue: 0.12)
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.19)
    static let cardBorder = Color(red: 0.18, green: 0.18, blue: 0.28)
    static let f1Red = Color(red: 0.88, green: 0.02, blue: 0.0)
    static let accentGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.65, green: 0.65, blue: 0.72)
    static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.55)
    
    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [f1Red.opacity(0.35), cardBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, Color(red: 0.09, green: 0.09, blue: 0.16)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Team Color (2026 grid — 11 teams)
    static func teamColor(for constructorId: String) -> Color {
        let colors: [String: Color] = [
            "mclaren": Color(red: 1.0, green: 0.5, blue: 0.0),        // Orange
            "red_bull": Color(red: 0.21, green: 0.44, blue: 0.78),     // Blue
            "ferrari": Color(red: 0.91, green: 0.0, blue: 0.18),       // Red
            "mercedes": Color(red: 0.15, green: 0.96, blue: 0.82),     // Teal
            "aston_martin": Color(red: 0.13, green: 0.6, blue: 0.44),  // Green
            "alpine": Color(red: 1.0, green: 0.53, blue: 0.74),        // Pink
            "williams": Color(red: 0.39, green: 0.77, blue: 1.0),      // Light Blue
            "rb": Color(red: 0.4, green: 0.57, blue: 1.0),             // Purple-Blue
            "racing_bulls": Color(red: 0.4, green: 0.57, blue: 1.0),   // Racing Bulls
            "sauber": Color(red: 0.32, green: 0.89, blue: 0.32),       // Green
            "audi": Color(red: 0.32, green: 0.89, blue: 0.32),         // Audi (replaces Sauber)
            "haas": Color(red: 0.71, green: 0.73, blue: 0.74),         // Silver
            "cadillac": Color(red: 0.85, green: 0.76, blue: 0.42),     // Gold
            "andretti": Color(red: 0.85, green: 0.76, blue: 0.42),     // Andretti-Cadillac
        ]
        return colors[constructorId] ?? .white
    }
}

// MARK: - Card Style Modifier
struct F1CardModifier: ViewModifier {
    var gradient: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient ? AnyShapeStyle(F1Theme.heroGradient) : AnyShapeStyle(F1Theme.cardBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(F1Theme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func f1Card(gradient: Bool = false) -> some View {
        modifier(F1CardModifier(gradient: gradient))
    }
}
