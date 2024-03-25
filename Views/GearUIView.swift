// GearUIView.swift
import SwiftUI
import Combine
import UserNotifications
import GoogleSignIn
import GoogleSignInSwift

struct GearUIView: View {
    @ObservedObject var gearViewModel: GearViewModel
    @StateObject var authViewModel = AuthenticationViewModel()
    @ObservedObject var signInButtonViewModel = GoogleSignInButtonViewModel()


    @State private var startAngle: Angle?
    
    init(viewModel: GearViewModel) {
        self.gearViewModel = viewModel
    }
    
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
            GoogleSignInButton(viewModel: signInButtonViewModel, action: authViewModel.signIn)
              .accessibilityIdentifier("GoogleSignInButton")
              .accessibility(hint: Text("Sign in with Google button."))
              .padding()
        }
        .onAppear {
            NotificationService.shared.requestNotificationPermission { granted, error in
                if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
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
                gearViewModel.doubleTapDetected()  // Handle double tap
            })
            .simultaneousGesture(TapGesture().onEnded {
                gearViewModel.tapDetected()  // Handle single tap
            })
    }
    
    private var timerText: some View {
        Text(UtilityFunctions.formatTimeInterval(gearViewModel.timerDuration))
            .font(.largeTitle)
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                gearViewModel.doubleTapDetected()  // Handle double tap
            })
            .simultaneousGesture(TapGesture().onEnded {
                gearViewModel.tapDetected()  // Handle single tap
            })
    }
    
    private var timerMacroText: some View {
        Text("\(gearViewModel.timerStartTimeDisplay) -> \(gearViewModel.timerEndTimeDisplay)")
            .padding(.top)
            .padding(.trailing)
    }
    
    // MARK: - Gestures
    private var gearDragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in rotationChanged(gesture: gesture) }
            .onEnded { gesture in rotationEnded(gesture: gesture) }
    }
    
    // MARK: - Gesture Handlers
    private func rotationChanged(gesture: DragGesture.Value) {
        let center = CGPoint(x: gearRadius, y: gearRadius)
        
        // Determine the initial start angle if it's not set
        if self.startAngle == nil {
            self.startAngle = UtilityFunctions.angle(for: gesture.startLocation, relativeTo: center)
        }
        
        let currentAngle = UtilityFunctions.angle(for: gesture.location, relativeTo: center)
        let angleDifference = angleDifferenceBetween(startAngle: self.startAngle!, currentAngle: currentAngle)
        
        // Update the start angle for the next calculation
        self.startAngle = currentAngle
        
        // Translate angle difference to time
        let timeChange = angleDifference.degrees / 360 * 1800
        gearViewModel.timerDuration += timeChange
        
        if gearViewModel.timerDuration < 0 {
            if gearViewModel.timerStartTime != nil {
                gearViewModel.timerRecordMacro()
            }
            gearViewModel.timerReset()
        } else {
            gearViewModel.countDown = true
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
}

struct GearUI_Previews: PreviewProvider {
    static var previews: some View {
        GearUIView(viewModel: GearViewModel())
    }
}
