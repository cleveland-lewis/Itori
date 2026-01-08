//
//  ContentView.swift
//  ItoriWatch Watch App
//
//  Created by Cleveland Lewis III on 1/7/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var connectivityManager = WatchTimerSync.shared
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 12) {
            if connectivityManager.isRunning {
                if let activity = connectivityManager.activityName {
                    Text(activity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(formatTime(elapsedTime))
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("Timer")
                    .accessibilityValue(formatTimeForVoiceOver(elapsedTime))
                
                HStack(spacing: 20) {
                    Button(action: pauseTimer) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Pause timer")
                    
                    Button(action: stopTimer) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .accessibilityLabel("Stop timer")
                }
            } else {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 8)
                    .accessibilityHidden(true)
                
                Text(elapsedTime > 0 ? formatTime(elapsedTime) : "Ready")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(elapsedTime > 0 ? "Previous time: \(formatTimeForVoiceOver(elapsedTime))" : "Timer ready")
                
                Button(action: startTimer) {
                    Label("Start Timer", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            setupTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: connectivityManager.isRunning) { _, isRunning in
            if isRunning {
                startLocalTimer()
            } else {
                timer?.invalidate()
            }
        }
        .onChange(of: connectivityManager.elapsedTime) { _, newTime in
            elapsedTime = newTime
        }
    }
    
    private func setupTimer() {
        elapsedTime = connectivityManager.elapsedTime
        if connectivityManager.isRunning {
            startLocalTimer()
        }
    }
    
    private func startTimer() {
        connectivityManager.startTimer(activityName: "Study Session")
        startLocalTimer()
    }
    
    private func pauseTimer() {
        connectivityManager.pauseTimer()
        timer?.invalidate()
    }
    
    private func stopTimer() {
        connectivityManager.stopTimer()
        timer?.invalidate()
        elapsedTime = 0
    }
    
    private func startLocalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatTimeForVoiceOver(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        var components: [String] = []
        
        if hours > 0 {
            components.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        if minutes > 0 || hours > 0 {
            components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }
        components.append("\(seconds) second\(seconds == 1 ? "" : "s")")
        
        return components.joined(separator: ", ")
    }
}

#Preview {
    ContentView()
}
