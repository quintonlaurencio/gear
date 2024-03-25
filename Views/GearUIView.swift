// GearUIView.swift
import SwiftUI
import Combine
import UserNotifications

struct GearUIView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartTime: Date? = nil
    @State private var timerEndTime: Date? = nil
    @State private var timerHistory: [TimerHistoryEntry] = []
    @State private var timerRunning: Bool = false
    @State private var timerStarted: Bool = false
    @State private var countDown: Bool = false
    @State private var startAngle: Angle?
    
    let gearSize: CGFloat = 300
    var gearRadius: CGFloat { gearSize / 2 }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    timerMacroText
                }
                Spacer()
            }
            buttonCircle
            gearCircle
            timerText
        }
        .onReceive(timerPublisher) { _ in
            updateTimer()
        }
        .onAppear {
            requestNotificationPermission()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                handleDidEnterBackground()
            } else if scenePhase == .active {
                handleWillEnterForeground()
            }
        }
    }
    
    // MARK: - View Components
    private var gearCircle: some View {
        Circle()
            .stroke(lineWidth: 20)
            .foregroundColor(.gray)
            .frame(width: gearSize, height: gearSize)
            .gesture(gearDragGesture)
    }
    
    private var buttonCircle: some View {
        Circle()
            .foregroundColor(.white)
            .frame(width: gearSize, height: gearSize)
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                self.doubleTapDetected()  // Handle double tap
            })
            .simultaneousGesture(TapGesture().onEnded {
                self.tapDetected()  // Handle single tap
            })
    }
    
    private var timerText: some View {
        Text(formatTimeInterval(timerDuration))
            .font(.largeTitle)
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                self.doubleTapDetected()  // Handle double tap
            })
            .simultaneousGesture(TapGesture().onEnded {
                self.tapDetected()  // Handle single tap
            })
    }
    
    private var timerMacroText: some View {
        Text(timerStartTimeDisplay() + "    ->   " + timerEndTimeDisplay())
            .padding(.top)
            .padding(.trailing)
    }
    
    // MARK: - Gestures
    private var gearDragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in rotationChanged(gesture: gesture) }
            .onEnded { gesture in rotationEnded(gesture: gesture) }
    }
    
    private var timerPublisher: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    // MARK: - Gesture Handlers
    private func rotationChanged(gesture: DragGesture.Value) {
        let center = CGPoint(x: gearRadius, y: gearRadius)
        
        // Determine the initial start angle if it's not set
        if self.startAngle == nil {
            self.startAngle = angle(for: gesture.startLocation, relativeTo: center)
        }
        
        let currentAngle = angle(for: gesture.location, relativeTo: center)
        let angleDifference = angleDifferenceBetween(startAngle: self.startAngle!, currentAngle: currentAngle)
        
        // Update the start angle for the next calculation
        self.startAngle = currentAngle
        
        // Translate angle difference to time
        let timeChange = angleDifference.degrees / 360 * 1800
        timerDuration += timeChange
        
        if timerDuration < 0 {
            if timerStartTime != nil {
                timerRecordMacro()
            }
            timerReset()
        } else {
            countDown = true
        }
    }
    
    private func angleDifferenceBetween(startAngle: Angle, currentAngle: Angle) -> Angle {
        // Normalize angles to a range of 0 to 360 degrees
        let normalizedStart = startAngle.degrees.truncatingRemainder(dividingBy: 360)
        let normalizedCurrent = currentAngle.degrees.truncatingRemainder(dividingBy: 360)
        
        // Calculate the raw angle difference
        var difference = normalizedCurrent - normalizedStart
        
        // Adjust the difference for continuous rotation
        // If the difference is greater than 180 degrees, adjust it to account for wrapping
        if difference > 180 {
            difference -= 360
        } else if difference < -180 {
            difference += 360
        }
        
        return .degrees(difference)
    }
    
    private func rotationEnded(gesture: DragGesture.Value) {
        self.startAngle = nil // Reset the start angle
    }
    
    private func tapDetected() {
        timerRunning.toggle()
        if timerStartTime == nil {
            timerStartTime = Date()
            timerStarted = true
        }
        if !timerRunning {
            timerEndTime = Date()
        }
        if countDown {
            cancelScheduledNotification()
            scheduleFutureNotification()
        }
    }
    
    private func doubleTapDetected() {
        timerRecordMacro()
        timerReset()
    }
    
    // MARK: - Notification Handling
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleFutureNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = "Your countdown timer has ended."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timerDuration, repeats: false)
        let request = UNNotificationRequest(identifier: "timerFinished", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerFinished"])
    }
    
    //MARK: - Background/Foreground Handling
    private func handleDidEnterBackground() {
        print("handle entered background")
        UserDefaults.standard.set(Date(), forKey: "backgroundEntryTime")
        UserDefaults.standard.set(timerDuration, forKey: "savedTimerDuration")
        UserDefaults.standard.set(timerRunning, forKey: "timerRunning")
    }
    
    private func handleWillEnterForeground() {
        print("handle entered foreground")
        guard let backgroundEntryTime = UserDefaults.standard.object(forKey: "backgroundEntryTime") as? Date,
              let savedTimerDuration = UserDefaults.standard.object(forKey: "savedTimerDuration") as? TimeInterval,
              let wasTimerRunning = UserDefaults.standard.object(forKey: "timerRunning") as? Bool else {
            return
        }
        
        UserDefaults.standard.removeObject(forKey: "backgroundEntryTime")
        UserDefaults.standard.removeObject(forKey: "savedTimerDuration")
        UserDefaults.standard.removeObject(forKey: "timerRunning")
        
        if wasTimerRunning {
            let timeInBackground = Date().timeIntervalSince(backgroundEntryTime)
            timerDuration = countDown ? max(0, savedTimerDuration - timeInBackground) : savedTimerDuration + timeInBackground
            // If the timer should resume counting down
            print(savedTimerDuration, timeInBackground, timerDuration, backgroundEntryTime)
            if countDown {
                if timerDuration > 0 {
                    timerRunning = true
                } else {
                    // Handle the case where the timer would have finished while in background
                    timerEndTime = backgroundEntryTime.addingTimeInterval(savedTimerDuration)
                    timerFinishedInBackground()
                }
            }
        }
    }
    
    private func timerFinishedInBackground() {
        timerRecordMacro()
        timerReset()
    }

    
    // MARK: - Timer Methods
    private func timerStartTimeDisplay() -> String {
        return formatDate(timerStarted ? timerStartTime : timerHistory.last?.timerStartTime)
    }
    
    private func timerEndTimeDisplay() -> String {
        return formatDate(timerStarted ? nil : timerHistory.last?.timerEndTime)
    }
    
    private func timerReset() {
        timerDuration = 0
        timerRunning = false
        timerStarted = false
        timerStartTime = nil
        countDown = false
    }
    
    private func timerRecordMacro() {
        timerHistory.append(TimerHistoryEntry(timerStartTime: timerStartTime, timerEndTime: Date()))
    }
    
    private func updateTimer() {
        if countDown && timerRunning && timerDuration > 0 {
            timerDuration -= 1
        } else if !countDown && timerRunning {
            timerDuration += 1
        }
        // Check if the timer has hit zero
        if countDown && timerRunning && timerDuration <= 0 {
            timerRecordMacro()
            timerReset()  // Call the method to handle the timer hitting zero
        }
    }
    
    // MARK: - Utility Methods
    private func angle(for location: CGPoint, relativeTo center: CGPoint) -> Angle {
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        return .radians(atan2(deltaY, deltaX))
    }
    
    private func formatTimeInterval(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00:00"
    }
    
    private func formatDate(_ rawTime: Date?) -> String {
        if let formattedTime = rawTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: formattedTime)
        } else {
            return ""
        }
    }
}

struct GearUI_Previews: PreviewProvider {
    static var previews: some View {
        GearUIView()
    }
}

struct TimerHistoryEntry {
    var timerStartTime: Date?
    var timerEndTime: Date
}
