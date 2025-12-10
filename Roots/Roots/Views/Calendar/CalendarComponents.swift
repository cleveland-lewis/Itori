import SwiftUI

struct CalendarHeader: View {
    @Binding var viewMode: CalendarViewMode
    @Binding var currentMonth: Date
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onToday: () -> Void
    var onSearch: (() -> Void)? = nil
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        ZStack {
            HStack {
                // Left: Month / Year
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(DesignSystem.Typography.header)

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

                    TodayButton(action: onToday)

                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.body.bold())
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Corners.pill, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .font(.body.bold())
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Corners.pill, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Center: View mode picker pinned to center regardless of month text width.
            Picker("", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
        }
    }
}

private struct TodayButton: View {
    var action: () -> Void
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        Button("Today", action: action)
            .font(.caption.bold())
            .foregroundStyle(settings.activeAccentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(settings.activeAccentColor.opacity(0.16))
            .overlay(
                Capsule()
                    .stroke(settings.activeAccentColor.opacity(0.45), lineWidth: 1)
            )
            .clipShape(Capsule())
            .buttonStyle(.plain)
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
