import SwiftUI

struct CalendarHeader: View {
    @Binding var viewMode: CalendarViewMode
    @Binding var currentMonth: Date
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onToday: () -> Void
    var onSearch: (() -> Void)? = nil

    var body: some View {
        HStack {
            // Left: Month / Year
            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(DesignSystem.Typography.header)

            Spacer()

            // Center: View mode picker
            Picker("", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Spacer()

            HStack(spacing: DesignSystem.Layout.spacing.small) {
                if let onSearch {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.body.bold())
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }

                Button("Today") { onToday() }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)

                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onNext) {
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
