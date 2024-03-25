import UserNotifications

/// Manages notification scheduling, permission requests, and cancellations.
class NotificationService {
    static let shared = NotificationService()
    
    enum NotificationIdentifier: String {
        case timerFinished = "timerFinished"
    }
    
    private init() {}
    
    /// Requests user permission for sending notifications.
    /// - Parameter completion: A closure called with the result of the permission request.
    func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
    
    /// Schedules a notification to be delivered in the future.
    /// - Parameters:
    ///   - duration: Time interval after which to deliver the notification.
    ///   - completion: An optional closure called after the scheduling request is completed.
    func scheduleFutureNotification(withDuration duration: TimeInterval, completion: (() -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = "Your countdown timer has ended."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(identifier: NotificationIdentifier.timerFinished.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    // Consider more robust error handling or logging strategy here.
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    completion?()
                }
            }
        }
    }
    
    /// Cancels all scheduled notifications with the specified identifier.
    /// - Parameter identifier: The identifier of the notifications to cancel.
    func cancelScheduledNotification(forIdentifier identifier: NotificationIdentifier) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier.rawValue])
    }
}
