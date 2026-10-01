import SwiftUI

/// Serializable point for circuit layout
struct SerializablePoint: Codable, Hashable {
    let x: Double
    let y: Double
}

// MARK: - Circuit Map Shape
struct CircuitMapShape: Shape {
    let points: [SerializablePoint]
    
    func path(in rect: CGRect) -> Path {
        guard points.count > 2 else { return Path() }
        
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1
        
        let dataWidth = maxX - minX
        let dataHeight = maxY - minY
        
        guard dataWidth > 0, dataHeight > 0 else { return Path() }
        
        // Fit into rect with padding
        let padding: CGFloat = 4
        let availWidth = rect.width - padding * 2
        let availHeight = rect.height - padding * 2
        
        let scale = min(availWidth / dataWidth, availHeight / dataHeight)
        
        let offsetX = rect.midX - (minX + maxX) / 2 * scale
        let offsetY = rect.midY - (minY + maxY) / 2 * scale
        
        var path = Path()
        
        // Draw with downsampling for performance
        let step = max(1, points.count / 150)
        var isFirst = true
        
        for i in stride(from: 0, to: points.count, by: step) {
            let x = points[i].x * scale + offsetX
            let y = points[i].y * scale + offsetY
            
            if isFirst {
                path.move(to: CGPoint(x: x, y: y))
                isFirst = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Close the circuit
        path.closeSubpath()
        
        return path
    }
}
