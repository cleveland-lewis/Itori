import SwiftUI

/// Visual status badge for scheduled practice tests
struct TestStatusBadge: View {
    let status: ScheduledTestStatus
    let isCompact: Bool
    
    init(status: ScheduledTestStatus, isCompact: Bool = false) {
        self.status = status
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(isCompact ? .caption2 : .caption)
            
            if !isCompact {
                Text(localizedText)
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch status {
        case .scheduled:
            return "clock"
        case .completed:
            return "checkmark.circle.fill"
        case .missed:
            return "exclamationmark.triangle.fill"
        case .archived:
            return "archivebox"
        }
    }
    
    private var localizedText: String {
        switch status {
        case .scheduled:
            return NSLocalizedString("practice.status.scheduled", comment: "Scheduled")
        case .completed:
            return NSLocalizedString("practice.status.completed", comment: "Completed")
        case .missed:
            return NSLocalizedString("practice.status.missed", comment: "Missed")
        case .archived:
            return NSLocalizedString("practice.status.archived", comment: "Archived")
        }
    }
    
    private var textColor: Color {
        switch status {
        case .scheduled:
            return .blue
        case .completed:
            return .green
        case .missed:
            return .orange
        case .archived:
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .scheduled:
            return Color.blue.opacity(0.12)
        case .completed:
            return Color.green.opacity(0.12)
        case .missed:
            return Color.orange.opacity(0.12)
        case .archived:
            return Color.secondary.opacity(0.08)
        }
    }
    
    private var borderColor: Color {
        switch status {
        case .scheduled:
            return Color.blue.opacity(0.3)
        case .completed:
            return Color.green.opacity(0.3)
        case .missed:
            return Color.orange.opacity(0.3)
        case .archived:
            return Color.secondary.opacity(0.2)
        }
    }
}

/// Extension to compute test status based on scheduled time and attempts
extension ScheduledPracticeTest {
    /// Determines the current status based on scheduled time and completion
    func currentStatus(hasCompletedAttempt: Bool) -> ScheduledTestStatus {
        // Archived status overrides everything
        if status == .archived {
            return .archived
        }
        
        // If there's a completed attempt, it's completed
        if hasCompletedAttempt {
            return .completed
        }
        
        // If scheduled time has passed and not completed, it's missed
        let now = Date()
        if scheduledAt < now {
            return .missed
        }
        
        // Otherwise it's scheduled
        return .scheduled
    }
}

#if !DISABLE_PREVIEWS
struct TestStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TestStatusBadge(status: .scheduled)
            TestStatusBadge(status: .completed)
            TestStatusBadge(status: .missed)
            TestStatusBadge(status: .archived)
            
            Divider()
            
            HStack(spacing: 8) {
                TestStatusBadge(status: .scheduled, isCompact: true)
                TestStatusBadge(status: .completed, isCompact: true)
                TestStatusBadge(status: .missed, isCompact: true)
                TestStatusBadge(status: .archived, isCompact: true)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
#endif
