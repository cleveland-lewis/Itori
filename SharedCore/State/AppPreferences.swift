import SwiftUI
import Combine

@MainActor
final class AppPreferences: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    private var settings: AppSettingsModel { AppSettingsModel.shared }
    private var cancellables = Set<AnyCancellable>()

    // Interaction
    @AppStorage("preferences.enableHoverWiggle") var enableHoverWiggle: Bool = true

    init() {
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // Interaction
    var enableHaptics: Bool {
        get { settings.enableHaptics }
        set {
            settings.objectWillChange.send()
            settings.enableHaptics = newValue
            settings.save()
        }
    }

    // Accessibility
    var reduceMotion: Bool {
        get { settings.reduceMotion }
        set {
            settings.objectWillChange.send()
            settings.reduceMotion = newValue
            settings.save()
        }
    }

    var highContrast: Bool {
        get { settings.increaseContrast }
        set {
            settings.objectWillChange.send()
            settings.increaseContrast = newValue
            settings.save()
        }
    }

    var reduceTransparency: Bool {
        get { settings.reduceTransparency }
        set {
            settings.objectWillChange.send()
            settings.reduceTransparency = newValue
            settings.save()
        }
    }

    // Appearance
    var glassIntensity: Double {
        get { settings.glassIntensity }
        set {
            settings.objectWillChange.send()
            settings.glassIntensity = newValue
            settings.save()
        }
    }

    var accentColorName: String {
        get { settings.accentColorChoice.label }
        set {
            if let match = AppAccentColor.allCases.first(where: { $0.label == newValue }) {
                settings.objectWillChange.send()
                settings.accentColorChoice = match
                settings.save()
            }
        }
    }

    // Layout
    var tabBarMode: TabBarMode {
        get { settings.tabBarMode }
        set {
            settings.objectWillChange.send()
            settings.tabBarMode = newValue
            settings.save()
        }
    }

    @AppStorage("preferences.sidebarBehavior") var sidebarBehaviorRaw: String = SidebarBehavior.automatic.rawValue

    var sidebarBehavior: SidebarBehavior {
        SidebarBehavior(rawValue: sidebarBehaviorRaw) ?? .automatic
    }

    // AppAccent enum and derived color
    enum AppAccent: String, CaseIterable, Identifiable {
        case blue = "Blue"
        case purple = "Purple"
        case pink = "Pink"
        case red = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green = "Green"
        case mint = "Mint"
        case teal = "Teal"
        case cyan = "Cyan"
        case indigo = "Indigo"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .mint: return .mint
            case .teal: return .teal
            case .cyan: return .cyan
            case .indigo: return .indigo
            }
        }
    }

    var currentAccentColor: Color {
        settings.activeAccentColor
    }
}

// MARK: - View Modifiers

struct WiggleOnHoverModifier: ViewModifier {
    @EnvironmentObject private var preferences: AppPreferences
    @State private var hovering = false

    func body(content: Content) -> some View {
        Group {
            if preferences.enableHoverWiggle {
                content
                    .scaleEffect(hovering ? 1.015 : 1.0)
                    .rotationEffect(.degrees(hovering ? 0.6 : 0))
                    .animation(.easeOut(duration: 0.16), value: hovering)
                    .onHover { hovering = $0 }
            } else {
                content
            }
        }
    }
}

struct RootsGlassBackgroundModifier: ViewModifier {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var settings: AppSettingsModel
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        #if os(macOS)
        let background: AnyShapeStyle = AnyShapeStyle(Color(nsColor: NSColor.windowBackgroundColor))
        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
        #else
        // If reduceTransparency is set, use a solid background (less transparency). Otherwise use material.
        if preferences.reduceTransparency || !settings.enableGlassEffects {
            let background: AnyShapeStyle = AnyShapeStyle(Color(nsColor: NSColor.windowBackgroundColor))
            return content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(background)
                )
        }

        let intensity = preferences.highContrast ? 1.0 : preferences.glassIntensity
        let background: AnyShapeStyle = preferences.highContrast
            ? AnyShapeStyle(Color.primary.opacity(0.08))
            : AnyShapeStyle(DesignSystem.Materials.hud.opacity(intensity))

        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
        #endif
    }
}

extension View {
    func wiggleOnHover() -> some View {
        modifier(WiggleOnHoverModifier())
    }

    func rootsGlassBackground(cornerRadius: CGFloat = 20) -> some View {
        modifier(RootsGlassBackgroundModifier(cornerRadius: cornerRadius))
    }
}
