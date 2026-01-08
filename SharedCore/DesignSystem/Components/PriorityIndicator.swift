import SwiftUI

/// Priority indicator that supports "Differentiate Without Color" accessibility setting
/// Shows both color and icon to ensure information is accessible to all users
public struct PriorityIndicator: View {
    let priority: AssignmentUrgency
    let showLabel: Bool
    
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    public init(priority: AssignmentUrgency, showLabel: Bool = false) {
        self.priority = priority
        self.showLabel = showLabel
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            if differentiateWithoutColor {
                // When differentiate without color is enabled, show icon
                Image(systemName: priority.systemIcon)
                    .font(.caption)
                    .foregroundStyle(priority.color)
                    .accessibilityHidden(true)
            } else {
                // When disabled, just show colored circle
                Circle()
                    .fill(priority.color)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
            
            if showLabel {
                Text(priority.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(priority.label) priority")
    }
}

/// Status indicator that supports "Differentiate Without Color" accessibility setting
public struct StatusIndicator: View {
    let status: AssignmentStatus
    let showLabel: Bool
    
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    public init(status: AssignmentStatus, showLabel: Bool = false) {
        self.status = status
        self.showLabel = showLabel
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            if differentiateWithoutColor {
                // Show icon when differentiate without color is enabled
                Image(systemName: status.systemIcon)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
            } else {
                // Just show color indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
            
            if showLabel {
                Text(status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
    }
    
    private var statusColor: Color {
        switch status {
        case .notStarted: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .gray
        }
    }
}

/// Course color indicator that supports "Differentiate Without Color" accessibility setting
/// Shows course code or first letter as pattern when differentiate is enabled
public struct CourseColorIndicator: View {
    let color: Color
    let courseCode: String
    let size: CGFloat
    
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    public init(color: Color, courseCode: String = "", size: CGFloat = 8) {
        self.color = color
        self.courseCode = courseCode
        self.size = size
    }
    
    public var body: some View {
        if differentiateWithoutColor && !courseCode.isEmpty {
            // Show first letter/digit of course code
            Text(courseInitial)
                .font(.system(size: size * 1.2, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size * 2, height: size * 2)
                .background(color.opacity(0.2))
                .clipShape(Circle())
                .accessibilityHidden(true)
        } else {
            // Just show colored circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
    
    private var courseInitial: String {
        // Extract first letter or digit from course code
        let alphanumeric = courseCode.filter { $0.isLetter || $0.isNumber }
        return alphanumeric.isEmpty ? "•" : String(alphanumeric.prefix(1)).uppercased()
    }
}

#Preview("Priority Indicators") {
    VStack(spacing: 16) {
        Text("Differentiate Without Color: OFF")
            .font(.headline)
        
        ForEach(AssignmentUrgency.allCases) { priority in
            HStack {
                PriorityIndicator(priority: priority)
                PriorityIndicator(priority: priority, showLabel: true)
                Spacer()
            }
        }
        
        Divider()
        
        Text("Differentiate Without Color: ON")
            .font(.headline)
        
        ForEach(AssignmentUrgency.allCases) { priority in
            HStack {
                PriorityIndicator(priority: priority)
                    .environment(\.accessibilityDifferentiateWithoutColor, true)
                PriorityIndicator(priority: priority, showLabel: true)
                    .environment(\.accessibilityDifferentiateWithoutColor, true)
                Spacer()
            }
        }
        
        Divider()
        
        Text("Course Color Indicators")
            .font(.headline)
        
        HStack(spacing: 16) {
            VStack {
                Text("Normal")
                CourseColorIndicator(color: .blue, courseCode: "CS101")
                CourseColorIndicator(color: .red, courseCode: "MATH201")
                CourseColorIndicator(color: .green, courseCode: "PHY301")
            }
            
            VStack {
                Text("Differentiate")
                CourseColorIndicator(color: .blue, courseCode: "CS101")
                    .environment(\.accessibilityDifferentiateWithoutColor, true)
                CourseColorIndicator(color: .red, courseCode: "MATH201")
                    .environment(\.accessibilityDifferentiateWithoutColor, true)
                CourseColorIndicator(color: .green, courseCode: "PHY301")
                    .environment(\.accessibilityDifferentiateWithoutColor, true)
            }
        }
    }
    .padding()
}
