//
//  GearViewModel.swift
//  Gear
//
//  Created by Quinton Laurencio on 2/3/24.
//

import Foundation
import Combine
import UserNotifications
import GoogleSignIn

/// ViewModel responsible for managing the timer logic and UI state in the Gear app.
class GearViewModel: ObservableObject {
    // MARK: - Published properties for UI updates
    @Published var timerDuration: TimeInterval = 0
    @Published var timerStartTime: Date? = nil
    @Published var timerEndTime: Date? = nil
    @Published var timerHistory: [TimerHistoryEntry] = []
    @Published var timerRunning: Bool = false
    @Published var timerStarted: Bool = false
    @Published var countDown: Bool = false
    
    // Timer updates will be published through this publisher.
    private var timerSubscription: AnyCancellable?
    
    // MARK: - Lifecycle
    init() {
        // Initialize the timer publisher to emit every second and autoconnect it.
        setupTimerPublisher()
        
        observeAppLifecycleEvents()
        
    }
    
    deinit {
        timerSubscription?.cancel()
    }
    
    // MARK: - Timer Setup
    /// Sets up the timer to update every second.
    private func setupTimerPublisher() {
        // Start the timer and handle its updates within the ViewModel.
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    /// Observes application lifecycle events for handling background and foreground transitions.
    private func observeAppLifecycleEvents() {
        AppLifecycleHandler.shared.setDidEnterBackgroundAction { [weak self] in
            self?.handleDidEnterBackground()
        }
        
        AppLifecycleHandler.shared.setWillEnterForegroundAction { [weak self] in
            self?.handleWillEnterForeground()
        }
    }
    
    // MARK: - Gesture Handlers
    /// Handles tap gesture to start or pause the timer.
    func tapDetected() {
        timerRunning.toggle()
        if timerStartTime == nil {
            timerStartTime = Date()
            timerStarted = true
        }
        if !timerRunning {
            timerEndTime = Date()
        }
        if countDown {
            NotificationService.shared.cancelScheduledNotification(forIdentifier: .timerFinished)
            NotificationService.shared.scheduleFutureNotification(withDuration: timerDuration)
        }
    }
    
    /// Handles double tap gesture to reset the timer.
    func doubleTapDetected() {
        timerRecordMacro()
        timerReset()
    }
    
    //MARK: - Timer Handling
    /// Updates the timer based on its current state and mode (countdown/up).
    func updateTimer() {
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
    /// Resets the timer to its initial state.
    func timerReset() {
        timerDuration = 0
        timerRunning = false
        timerStarted = false
        timerStartTime = nil
        countDown = false
    }
    /// Records a timer macro and resets the timer.
    func timerRecordMacro() {
        if let startTime = timerStartTime {
            timerHistory.append(TimerHistoryEntry(timerStartTime: startTime, timerEndTime: Date()))
        }
        timerReset()
    }
    
    var timerStartTimeDisplay: String {
        return UtilityFunctions.formatDate(timerStarted ? timerStartTime : timerHistory.last?.timerStartTime)
    }
    
    var timerEndTimeDisplay: String {
        return UtilityFunctions.formatDate(timerStarted ? nil : timerHistory.last?.timerEndTime)
    }
    
    //MARK: - Background/Foreground Handling
    func handleDidEnterBackground() {
        print("handle entered background")
        UserDefaults.standard.set(Date(), forKey: "backgroundEntryTime")
        UserDefaults.standard.set(timerDuration, forKey: "savedTimerDuration")
        UserDefaults.standard.set(timerRunning, forKey: "timerRunning")
    }
    
    func handleWillEnterForeground() {
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
}
