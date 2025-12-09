import SwiftUI

struct CalendarHeader: View {
    @Binding var currentMonth: Date
    
    var body: some View {
        HStack {
            // Month Title
            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(DesignSystem.Typography.header)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: DesignSystem.Layout.spacing.small) {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button("Today") {
                    withAnimation {
                        currentMonth = Date()
                    }
                }
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
                .buttonStyle(.plain)
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.body.bold())
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation {
                currentMonth = newDate
            }
        }
    }
}

struct StatCardSmall: View {
    let icon: String
    let label: String
    let mainValue: String
    let subtext: String
    
    var body: some View {
        RootsCard { // Uses existing RootsCard wrapper
            HStack(spacing: 12) {
                // Icon Box
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Material.ultraThin)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mainValue)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text(subtext)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: 200) // Fixed width for uniform look
        }
    }
}
