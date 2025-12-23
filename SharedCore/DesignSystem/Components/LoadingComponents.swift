import SwiftUI

// MARK: - Loading Overlay (Page-Level)

/// Full-page loading overlay with glass background
public struct LoadingOverlay: View {
    let message: String?
    
    public init(message: String? = nil) {
        self.message = message
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .loadingTransition()
    }
}

// MARK: - Inline Loading Row

/// Inline loading indicator for list items or sections
public struct LoadingInlineRow: View {
    let message: String?
    
    public init(message: String? = nil) {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            
            if let message {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .loadingTransition()
    }
}

// MARK: - Skeleton Card

/// Skeleton placeholder for loading content
public struct SkeletonCard: View {
    let height: CGFloat
    
    @State private var isAnimating = false
    
    public init(height: CGFloat = 100) {
        self.height = height
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.15),
                        Color.secondary.opacity(0.25),
                        Color.secondary.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .offset(x: isAnimating ? 400 : -400)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .transition(DesignSystem.Transitions.skeleton)
    }
}

// MARK: - Skeleton Text Lines

/// Skeleton text lines for loading text content
public struct SkeletonTextLines: View {
    let lineCount: Int
    let lineHeight: CGFloat
    
    public init(lineCount: Int = 3, lineHeight: CGFloat = 12) {
        self.lineCount = lineCount
        self.lineHeight = lineHeight
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lineCount, id: \.self) { index in
                SkeletonLine(
                    width: index == lineCount - 1 ? .random(in: 0.5...0.8) : 1.0,
                    height: lineHeight
                )
            }
        }
    }
}

private struct SkeletonLine: View {
    let width: CGFloat
    let height: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.15),
                        Color.secondary.opacity(0.25),
                        Color.secondary.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(maxWidth: .infinity)
            .frame(width: UIScreen.main.bounds.width * width, height: height)
            .offset(x: isAnimating ? 400 : -400)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Loading State Container

/// Container that shows loading, error, or content based on state
public struct LoadingStateContainer<Content: View>: View {
    let state: LoadingState
    let content: () -> Content
    let onRetry: (() -> Void)?
    
    public init(
        state: LoadingState,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
    }
    
    public var body: some View {
        switch state {
        case .idle:
            content()
            
        case .loading(let message):
            LoadingInlineRow(message: message)
            
        case .loaded:
            content()
            
        case .error(let message):
            ErrorStateView(message: message, onRetry: onRetry)
        }
    }
}

public enum LoadingState: Equatable {
    case idle
    case loading(message: String? = nil)
    case loaded
    case error(message: String)
}

// MARK: - Error State View

/// Standard error state view with retry option
public struct ErrorStateView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    public init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let onRetry {
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

// MARK: - View Modifiers

extension View {
    /// Show loading overlay conditionally
    public func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        ZStack {
            self
            
            if isLoading {
                LoadingOverlay(message: message)
            }
        }
    }
    
    /// Replace content with loading indicator
    public func replaceWithLoading(_ isLoading: Bool, message: String? = nil) -> some View {
        Group {
            if isLoading {
                LoadingInlineRow(message: message)
                    .contentReplacementTransition(value: isLoading)
            } else {
                self
                    .contentReplacementTransition(value: isLoading)
            }
        }
    }
}

// MARK: - Platform Compatibility

#if os(iOS)
extension UIScreen {
    static var main: UIScreen {
        UIScreen.main
    }
}
#elseif os(macOS)
extension UIScreen {
    struct main {
        static var bounds: CGRect {
            NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
        }
    }
}
#endif
