import SwiftUI

/// Keyboard shortcuts for timer controls (macOS)
/// Feature: UI Enhancements - Platform Integration
struct TimerKeyboardShortcuts: ViewModifier {
    @ObservedObject var viewModel: TimerPageViewModel
    
    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StartTimer"))) { _ in
                if viewModel.currentSession == nil {
                    viewModel.startSession()
                    LOG_UI(.info, "Shortcuts", "Timer started via keyboard shortcut")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PauseTimer"))) { _ in
                if viewModel.currentSession?.state == .running {
                    viewModel.pauseSession()
                    LOG_UI(.info, "Shortcuts", "Timer paused via keyboard shortcut")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResumeTimer"))) { _ in
                if viewModel.currentSession?.state == .paused {
                    viewModel.resumeSession()
                    LOG_UI(.info, "Shortcuts", "Timer resumed via keyboard shortcut")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StopTimer"))) { _ in
                if viewModel.currentSession != nil {
                    viewModel.endSession(completed: false)
                    LOG_UI(.info, "Shortcuts", "Timer stopped via keyboard shortcut")
                }
            }
            #endif
    }
}

extension View {
    /// Add timer keyboard shortcuts (macOS only)
    func timerKeyboardShortcuts(viewModel: TimerPageViewModel) -> some View {
        self.modifier(TimerKeyboardShortcuts(viewModel: viewModel))
    }
}

#if os(macOS)
/// Menu commands for timer controls
struct TimerMenuCommands: Commands {
    @ObservedObject var viewModel: TimerPageViewModel
    
    var body: some Commands {
        CommandMenu("Timer") {
            Button("Start Timer") {
                NotificationCenter.default.post(name: NSNotification.Name("StartTimer"), object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command])
            .disabled(viewModel.currentSession != nil)
            
            Button("Pause Timer") {
                NotificationCenter.default.post(name: NSNotification.Name("PauseTimer"), object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(viewModel.currentSession?.state != .running)
            
            Button("Resume Timer") {
                NotificationCenter.default.post(name: NSNotification.Name("ResumeTimer"), object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(viewModel.currentSession?.state != .paused)
            
            Divider()
            
            Button("Stop Timer") {
                NotificationCenter.default.post(name: NSNotification.Name("StopTimer"), object: nil)
            }
            .keyboardShortcut(".", modifiers: [.command])
            .disabled(viewModel.currentSession == nil)
            
            Divider()
            
            Button("Add 5 Minutes") {
                addTime(minutes: 5)
            }
            .keyboardShortcut("+", modifiers: [.command])
            .disabled(viewModel.currentSession == nil)
            
            Button("Remove 5 Minutes") {
                removeTime(minutes: 5)
            }
            .keyboardShortcut("-", modifiers: [.command])
            .disabled(viewModel.currentSession == nil)
        }
    }
    
    private func addTime(minutes: Int) {
        guard let session = viewModel.currentSession else { return }
        // This would require adding a method to TimerPageViewModel
        LOG_UI(.info, "Shortcuts", "Add \(minutes) minutes requested")
    }
    
    private func removeTime(minutes: Int) {
        guard let session = viewModel.currentSession else { return }
        // This would require adding a method to TimerPageViewModel
        LOG_UI(.info, "Shortcuts", "Remove \(minutes) minutes requested")
    }
}
#endif

/// Enhanced timer button with micro-interactions
struct EnhancedTimerButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ButtonStyleType = .primary
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return Color(UIColor.secondarySystemBackground)
            case .destructive: return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .destructive: return .white
            }
        }
    }
    
    var body: some View {
        Button(action: {
            HapticFeedbackManager.shared.buttonPressed()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor)
            )
            .foregroundColor(style.foregroundColor)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: style.backgroundColor.opacity(isPressed ? 0.4 : 0.2),
                radius: isPressed ? 8 : 4,
                x: 0,
                y: isPressed ? 4 : 2
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isDisabled {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

#if DEBUG
#Preview("Enhanced Button") {
    VStack(spacing: 20) {
        EnhancedTimerButton(
            title: "Start",
            icon: "play.fill",
            action: {},
            style: .primary
        )
        
        EnhancedTimerButton(
            title: "Pause",
            icon: "pause.fill",
            action: {},
            style: .secondary
        )
        
        EnhancedTimerButton(
            title: "Stop",
            icon: "stop.fill",
            action: {},
            style: .destructive
        )
    }
    .padding()
}
#endif
