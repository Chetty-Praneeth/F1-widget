import Foundation

/// Fetches circuit layout data from the multiviewer API
/// Used to draw track maps in the widget
class CircuitMapService {
    static let shared = CircuitMapService()
    
    /// Mapping from Ergast circuitId to multiviewer circuitKey
    private let circuitKeyMap: [String: Int] = [
        "albert_park": 10,
        "bahrain": 63,
        "jeddah": 149,
        "suzuka": 46,
        "shanghai": 49,
        "miami": 151,
        "imola": 6,
        "monaco": 22,
        "villeneuve": 23,  // Montreal
        "catalunya": 15,
        "red_bull_ring": 19,
        "silverstone": 2,
        "hungaroring": 4,
        "spa": 7,
        "zandvoort": 55,
        "monza": 39,
        "baku": 144,
        "marina_bay": 61,
        "americas": 9,     // COTA
        "rodriguez": 65,   // Mexico City
        "interlagos": 14,
        "vegas": 152,      // Las Vegas
        "losail": 150,     // Qatar
        "yas_marina": 70,
    ]
    
    struct CircuitLayout: Codable {
        let x: [Double]
        let y: [Double]
        let rotation: Double?
        let circuitName: String?
    }
    
    func fetchCircuitLayout(circuitId: String) async -> [CGPoint]? {
        guard let key = circuitKeyMap[circuitId] else { return nil }
        
        let urlString = "https://api.multiviewer.app/api/v1/circuits/\(key)/2026"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Try previous year if 2026 not available
                return await fetchCircuitLayoutFallback(key: key)
            }
            
            let layout = try JSONDecoder().decode(CircuitLayout.self, from: data)
            return zip(layout.x, layout.y).map { CGPoint(x: $0, y: $1) }
        } catch {
            return await fetchCircuitLayoutFallback(key: key)
        }
    }
    
    private func fetchCircuitLayoutFallback(key: Int) async -> [CGPoint]? {
        // Try 2025, then 2024
        for year in [2025, 2024, 2023, 2022] {
            let urlString = "https://api.multiviewer.app/api/v1/circuits/\(key)/\(year)"
            guard let url = URL(string: urlString) else { continue }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }
                
                let layout = try JSONDecoder().decode(CircuitLayout.self, from: data)
                return zip(layout.x, layout.y).map { CGPoint(x: $0, y: $1) }
            } catch {
                continue
            }
        }
        return nil
    }
}
