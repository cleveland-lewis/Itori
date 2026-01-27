import SwiftUI

/// Enhanced timer themes with visual presets
/// Feature: UI Enhancements - Theme System
public struct EnhancedTimerTheme: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var family: ThemeFamily
    public var primaryColorHex: String
    public var secondaryColorHex: String?
    public var accentColorHex: String?
    public var backgroundStyle: BackgroundStyle
    public var ringThickness: RingThickness
    public var animationStyle: AnimationStyle
    public var isDefault: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        family: ThemeFamily = .minimal,
        primaryColorHex: String,
        secondaryColorHex: String? = nil,
        accentColorHex: String? = nil,
        backgroundStyle: BackgroundStyle = .plain,
        ringThickness: RingThickness = .medium,
        animationStyle: AnimationStyle = .smooth,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.family = family
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.accentColorHex = accentColorHex
        self.backgroundStyle = backgroundStyle
        self.ringThickness = ringThickness
        self.animationStyle = animationStyle
        self.isDefault = isDefault
    }
    
    // MARK: - Theme Families
    
    public enum ThemeFamily: String, Codable, CaseIterable, Identifiable {
        case minimal = "Minimal"
        case neon = "Neon"
        case analog = "Analog"
        case nature = "Nature"
        case professional = "Professional"
        
        public var id: String { rawValue }
        
        var description: String {
            switch self {
            case .minimal: return "Clean and simple"
            case .neon: return "Bold and vibrant"
            case .analog: return "Classic and timeless"
            case .nature: return "Calm and organic"
            case .professional: return "Refined and focused"
            }
        }
    }
    
    public enum BackgroundStyle: String, Codable {
        case plain
        case gradient
        case subtle
        case glass
    }
    
    public enum RingThickness: String, Codable, CaseIterable {
        case thin
        case medium
        case thick
        
        var lineWidth: CGFloat {
            switch self {
            case .thin: return 12
            case .medium: return 20
            case .thick: return 28
            }
        }
    }
    
    public enum AnimationStyle: String, Codable, CaseIterable {
        case smooth      // Gentle easing
        case snappy      // Quick and responsive
        case bouncy      // Playful spring
        case minimal     // Reduce motion friendly
        
        var animation: Animation {
            switch self {
            case .smooth:
                return .easeInOut(duration: 0.5)
            case .snappy:
                return .spring(response: 0.3, dampingFraction: 0.7)
            case .bouncy:
                return .spring(response: 0.6, dampingFraction: 0.6)
            case .minimal:
                return .linear(duration: 0.2)
            }
        }
    }
    
    // MARK: - Default Themes
    
    public static let defaults: [EnhancedTimerTheme] = [
        // Minimal Family
        EnhancedTimerTheme(
            name: "Clean",
            family: .minimal,
            primaryColorHex: "#007AFF",
            backgroundStyle: .plain,
            ringThickness: .medium,
            animationStyle: .smooth,
            isDefault: true
        ),
        
        // Neon Family
        EnhancedTimerTheme(
            name: "Neon Blue",
            family: .neon,
            primaryColorHex: "#00F5FF",
            secondaryColorHex: "#0080FF",
            accentColorHex: "#FF00FF",
            backgroundStyle: .gradient,
            ringThickness: .thick,
            animationStyle: .snappy
        ),
        
        EnhancedTimerTheme(
            name: "Neon Pink",
            family: .neon,
            primaryColorHex: "#FF006E",
            secondaryColorHex: "#8338EC",
            accentColorHex: "#FFBE0B",
            backgroundStyle: .gradient,
            ringThickness: .thick,
            animationStyle: .snappy
        ),
        
        // Analog Family
        EnhancedTimerTheme(
            name: "Classic Gold",
            family: .analog,
            primaryColorHex: "#D4AF37",
            secondaryColorHex: "#8B7355",
            backgroundStyle: .subtle,
            ringThickness: .medium,
            animationStyle: .smooth
        ),
        
        EnhancedTimerTheme(
            name: "Vintage",
            family: .analog,
            primaryColorHex: "#704214",
            secondaryColorHex: "#C4A484",
            backgroundStyle: .subtle,
            ringThickness: .thin,
            animationStyle: .minimal
        ),
        
        // Nature Family
        EnhancedTimerTheme(
            name: "Forest",
            family: .nature,
            primaryColorHex: "#2D5016",
            secondaryColorHex: "#6A994E",
            accentColorHex: "#BC4749",
            backgroundStyle: .gradient,
            ringThickness: .medium,
            animationStyle: .smooth
        ),
        
        EnhancedTimerTheme(
            name: "Ocean",
            family: .nature,
            primaryColorHex: "#006D77",
            secondaryColorHex: "#83C5BE",
            accentColorHex: "#E29578",
            backgroundStyle: .gradient,
            ringThickness: .medium,
            animationStyle: .smooth
        ),
        
        EnhancedTimerTheme(
            name: "Sunset",
            family: .nature,
            primaryColorHex: "#FF6B35",
            secondaryColorHex: "#F7931E",
            accentColorHex: "#FDC830",
            backgroundStyle: .gradient,
            ringThickness: .thick,
            animationStyle: .bouncy
        ),
        
        // Professional Family
        EnhancedTimerTheme(
            name: "Corporate",
            family: .professional,
            primaryColorHex: "#2C3E50",
            secondaryColorHex: "#34495E",
            accentColorHex: "#3498DB",
            backgroundStyle: .plain,
            ringThickness: .medium,
            animationStyle: .smooth
        ),
        
        EnhancedTimerTheme(
            name: "Monochrome",
            family: .professional,
            primaryColorHex: "#333333",
            secondaryColorHex: "#666666",
            backgroundStyle: .plain,
            ringThickness: .thin,
            animationStyle: .minimal
        ),
    ]
    
    // MARK: - Color Helpers
    
    var primaryColor: Color {
        Color(hex: primaryColorHex) ?? .blue
    }
    
    var secondaryColor: Color? {
        guard let hex = secondaryColorHex else { return nil }
        return Color(hex: hex)
    }
    
    var accentColor: Color? {
        guard let hex = accentColorHex else { return nil }
        return Color(hex: hex)
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    func backgroundView(for colorScheme: ColorScheme) -> some View {
        switch backgroundStyle {
        case .plain:
            Color.clear
            
        case .gradient:
            if let secondary = secondaryColor {
                LinearGradient(
                    colors: [primaryColor.opacity(0.1), secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                primaryColor.opacity(0.05)
            }
            
        case .subtle:
            primaryColor
                .opacity(colorScheme == .dark ? 0.15 : 0.08)
            
        case .glass:
            if #available(iOS 15.0, macOS 12.0, *) {
                primaryColor
                    .opacity(0.1)
                    .background(.ultraThinMaterial)
            } else {
                primaryColor.opacity(0.1)
            }
        }
    }
}

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @Binding var selectedTheme: EnhancedTimerTheme
    let themes: [EnhancedTimerTheme]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(EnhancedTimerTheme.ThemeFamily.allCases) { family in
                    themeFamilySection(family: family)
                }
            }
            .padding()
        }
        .navigationTitle("Timer Themes")
    }
    
    @ViewBuilder
    private func themeFamilySection(family: EnhancedTimerTheme.ThemeFamily) -> some View {
        let familyThemes = themes.filter { $0.family == family }
        
        if !familyThemes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(family.rawValue)
                        .font(.headline)
                    Text(family.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(familyThemes) { theme in
                        ThemeCard(theme: theme, isSelected: theme.id == selectedTheme.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTheme = theme
                                }
                                HapticFeedbackManager.shared.selectionChanged()
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: EnhancedTimerTheme
    let isSelected: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview circle
            ZStack {
                Circle()
                    .fill(theme.primaryColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(theme.primaryColor, lineWidth: 8)
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
            }
            
            Text(theme.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? theme.primaryColor : Color.clear,
                    lineWidth: 3
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ThemePickerView(
            selectedTheme: .constant(EnhancedTimerTheme.defaults[0]),
            themes: EnhancedTimerTheme.defaults
        )
    }
}
#endif
