import Foundation

struct TimerHistoryEntry: Identifiable, Codable {
    let id: UUID
    var timerStartTime: Date?
    var timerEndTime: Date

    init(timerStartTime: Date? = nil, timerEndTime: Date) {
        self.id = UUID()
        self.timerStartTime = timerStartTime
        self.timerEndTime = timerEndTime
    }
}
