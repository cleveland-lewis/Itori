//
//  SheetShellView.swift
//  Roots
//
//  PHASE 3: Instant Sheet Presentation
//  Two-step sheet that shows immediately with placeholder, loads content async
//

import SwiftUI

/// PHASE 3: Lightweight shell that presents instantly before heavy content loads
/// Usage:
/// ```swift
/// .sheet(isPresented: $showSheet) {
///     SheetShellView(title: "Add Assignment") {
///         AddAssignmentView(...)  // Heavy view
///     }
/// }
/// ```
struct SheetShellView<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content
    
    @State private var showContent = false
    @State private var isLoading = true
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
    
    var body: some View {
        Group {
            if showContent {
                // Real content - loaded after shell appears
                content()
            } else {
                // Lightweight shell - shows instantly
                shellView
            }
        }
        .task {
            // PHASE 3: Yield to allow shell to render, then load content
            await Task.yield()
            
            // Small delay to ensure shell is visible
            try? await Task.sleep(nanoseconds: 16_000_000) // ~1 frame at 60fps
            
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = true
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private var shellView: some View {
        #if os(iOS)
        iOSShellView
        #elseif os(macOS)
        macOSShellView
        #endif
    }
    
    // MARK: - iOS Shell
    
    #if os(iOS)
    private var iOSShellView: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityLabel("\(title), loading")
            .accessibilityHint("Content is loading")
        }
    }
    #endif
    
    // MARK: - macOS Shell
    
    #if os(macOS)
    private var macOSShellView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Loading content
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.2)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("\(title), loading")
            .accessibilityHint("Content is loading")
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    #endif
}

// MARK: - Skeleton Placeholders

/// PHASE 3: Reusable skeleton placeholder for list items
struct SkeletonListRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 10)
            }
            
            Spacer()
        }
        .shimmer()
    }
}

/// PHASE 3: Shimmer effect for skeleton views
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Instant Tap Feedback

/// PHASE 3: Button style with immediate pressed feedback
struct InstantFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InstantFeedbackButtonStyle {
    static var instantFeedback: InstantFeedbackButtonStyle {
        InstantFeedbackButtonStyle()
    }
}

// MARK: - Prewarm Coordinator

/// PHASE 3: Manages prewarming of hot views on idle
@MainActor
class PrewarmCoordinator {
    static let shared = PrewarmCoordinator()
    
    private var isPrewarmed = false
    private var prewarmTask: Task<Void, Never>?
    
    private init() {}
    
    /// Start prewarming after app becomes idle (call after launch + 1-1.5s)
    func startPrewarming(
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore
    ) {
        guard !isPrewarmed else { return }
        
        prewarmTask = Task { [weak self] in
            guard let self = self else { return }
            
            LOG_UI(.info, "Prewarm", "Starting view prewarming")
            
            // Wait for ideal time (after launch, before user interaction)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            
            // Check if app is still active
            #if os(iOS)
            guard await UIApplication.shared.applicationState == .active else {
                LOG_UI(.debug, "Prewarm", "App inactive, cancelling prewarm")
                return
            }
            #endif
            
            // Prewarm expensive formatters
            await self.prewarmFormatters()
            
            // Prewarm common view state
            await self.prewarmViewState(coursesStore: coursesStore, assignmentsStore: assignmentsStore)
            
            self.isPrewarmed = true
            LOG_UI(.info, "Prewarm", "View prewarming complete")
        }
    }
    
    /// Cancel prewarming (e.g., app going to background)
    func cancelPrewarming() {
        prewarmTask?.cancel()
        prewarmTask = nil
        LOG_UI(.debug, "Prewarm", "Prewarming cancelled")
    }
    
    private func prewarmFormatters() async {
        // Prewarm date formatters (expensive first access)
        let _ = DateFormatter.iso8601Full
        let _ = DateFormatter.shortDate
        let _ = DateFormatter.shortTime
        
        // Prewarm number formatters
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let _ = formatter.string(from: 3.5)
        
        LOG_UI(.debug, "Prewarm", "Formatters prewarmed")
    }
    
    private func prewarmViewState(
        coursesStore: CoursesStore,
        assignmentsStore: AssignmentsStore
    ) async {
        // Compute expensive derived data
        let activeCourses = coursesStore.activeCourses
        // let upcomingTasks = assignmentsStore.upcomingAssignments
        
        // Cache counts for dashboard
        // let _ = upcomingTasks.count
        let _ = activeCourses.count
        
        LOG_UI(.debug, "Prewarm", "View state prewarmed: \(activeCourses.count) courses")
    }
}

// MARK: - DateFormatter Extensions (for prewarming)

extension DateFormatter {
    static let iso8601Full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
