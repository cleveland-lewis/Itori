#if os(macOS)
import SwiftUI

/// View modifier to add global context menu on right-click
struct GlobalContextMenuModifier: ViewModifier {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var calendarManager: CalendarManager
    @EnvironmentObject private var plannerCoordinator: PlannerCoordinator
    @EnvironmentObject private var settingsCoordinator: SettingsCoordinator
    
    var pageSpecificItems: (() -> AnyView)?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Global items
                Button("Refresh Calendar") {
                    GlobalMenuActions.shared.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Go to Planner") {
                    GlobalMenuActions.shared.navigateToPlanner()
                }
                
                Button("Add Assignment") {
                    GlobalMenuActions.shared.addAssignment()
                }
                
                Button("Add Grade") {
                    GlobalMenuActions.shared.addGrade()
                }
            }
    }
}

/// Timer-specific context menu modifier
struct TimerContextMenuModifier: ViewModifier {
    @Binding var isRunning: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onEnd: () -> Void
    
    @EnvironmentObject private var appModel: AppModel
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Timer-specific items
                Button("Start clock") {
                    TimerMenuActions.shared.startClock()
                }
                .disabled(isRunning)
                
                Button("Stop clock") {
                    TimerMenuActions.shared.stopClock()
                }
                .disabled(!isRunning)
                
                Button("End clock") {
                    TimerMenuActions.shared.endClock()
                }
                .disabled(!isRunning)
                
                Divider()
                
                // Global items
                Button("Refresh Calendar") {
                    GlobalMenuActions.shared.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Go to Planner") {
                    GlobalMenuActions.shared.navigateToPlanner()
                }
                
                Button("Add Assignment") {
                    GlobalMenuActions.shared.addAssignment()
                }
                
                Button("Add Grade") {
                    GlobalMenuActions.shared.addGrade()
                }
            }
    }
}

// MARK: - Action Handlers

/// Global menu action handler
class GlobalMenuActions: NSObject {
    static let shared = GlobalMenuActions()
    
    @objc func refresh() {
        NotificationCenter.default.post(name: .refreshRequested, object: nil)
    }
    
    @objc func navigateToCalendar() {
        NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": "calendar"])
    }
    
    @objc func navigateToPlanner() {
        NotificationCenter.default.post(name: .navigateToTab, object: nil, userInfo: ["tab": "planner"])
    }
    
    @objc func addAssignment() {
        NotificationCenter.default.post(name: .addAssignmentRequested, object: nil)
    }
    
    @objc func addGrade() {
        NotificationCenter.default.post(name: .addGradeRequested, object: nil)
    }
}

/// Timer-specific menu action handler
class TimerMenuActions: NSObject {
    static let shared = TimerMenuActions()
    
    @objc func startClock() {
        NotificationCenter.default.post(name: .timerStartRequested, object: nil)
    }
    
    @objc func stopClock() {
        NotificationCenter.default.post(name: .timerStopRequested, object: nil)
    }
    
    @objc func endClock() {
        NotificationCenter.default.post(name: .timerEndRequested, object: nil)
    }
}

// MARK: - Notification Names

// MARK: - View Extensions

extension View {
    func globalContextMenu(pageSpecificItems: (() -> AnyView)? = nil) -> some View {
        modifier(GlobalContextMenuModifier(pageSpecificItems: pageSpecificItems))
    }
    
    func timerContextMenu(isRunning: Binding<Bool>, onStart: @escaping () -> Void, onStop: @escaping () -> Void, onEnd: @escaping () -> Void) -> some View {
        modifier(TimerContextMenuModifier(isRunning: isRunning, onStart: onStart, onStop: onStop, onEnd: onEnd))
    }
}

#endif

