import UIKit
import SwiftUI

/// Centralized haptic feedback manager
/// Provides consistent tactile feedback across the app
@MainActor
final class FeedbackManager {
    static let shared = FeedbackManager()
    
    private var lastFeedbackTime: [FeedbackEvent: Date] = [:]
    private let minimumInterval: TimeInterval = 0.1 // Debounce threshold
    
    private init() {}
    
    enum FeedbackEvent {
        case taskCompleted
        case taskCreated
        case taskDeleted
        case timerStarted
        case timerStopped
        case timerCompleted
        case navigationChanged
        case errorOccurred
        case successAction
        case warningAction
        case selectionChanged
        case dataRefreshed
        case itemDragged
        case itemDropped
    }
    
    /// Trigger haptic feedback for an event
    /// Automatically debounces to avoid overwhelming the user
    func trigger(event: FeedbackEvent) {
        #if os(iOS)
        // Check debounce
        if let lastTime = lastFeedbackTime[event],
           Date().timeIntervalSince(lastTime) < minimumInterval {
            return
        }
        
        lastFeedbackTime[event] = Date()
        
        // Generate appropriate feedback
        switch event {
        case .taskCompleted, .timerCompleted, .successAction:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        case .taskCreated, .taskDeleted, .timerStarted, .timerStopped:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
        case .errorOccurred:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
        case .warningAction:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            
        case .navigationChanged, .selectionChanged:
            UISelectionFeedbackGenerator().selectionChanged()
            
        case .dataRefreshed:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .itemDragged, .itemDropped:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        #endif
    }
    
    /// Prepare haptic engine for upcoming feedback (reduces latency)
    func prepare(for event: FeedbackEvent) {
        #if os(iOS)
        switch event {
        case .taskCompleted, .timerCompleted, .successAction, .errorOccurred, .warningAction:
            UINotificationFeedbackGenerator().prepare()
            
        case .taskCreated, .taskDeleted, .timerStarted, .timerStopped, .dataRefreshed, .itemDragged, .itemDropped:
            UIImpactFeedbackGenerator(style: .medium).prepare()
            
        case .navigationChanged, .selectionChanged:
            UISelectionFeedbackGenerator().prepare()
        }
        #endif
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Add haptic feedback to a view interaction
    func hapticFeedback(_ event: FeedbackManager.FeedbackEvent, onTrigger: Bool = true) -> some View {
        self.onChange(of: onTrigger) { _, newValue in
            if newValue {
                FeedbackManager.shared.trigger(event: event)
            }
        }
    }
}

// MARK: - Example Usage in Views

/*
 // In IOSAssignmentsView.swift
 
 Button {
     toggleCompletion(task)
     FeedbackManager.shared.trigger(event: .taskCompleted)
 } label: {
     Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
 }
 
 // Or with modifier
 .hapticFeedback(.taskCompleted, onTrigger: task.isCompleted)
 */
