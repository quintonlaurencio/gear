import Foundation
import SwiftUI

struct UtilityFunctions {
    /// Calculates the angle for a given location relative to a center point.
    static func angle(for location: CGPoint, relativeTo center: CGPoint) -> Angle {
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        return .radians(atan2(deltaY, deltaX))
    }
    
    /// Formats a TimeInterval into a string.
    static func formatTimeInterval(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00:00"
    }
    
    /// Formats a Date into a string.
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
