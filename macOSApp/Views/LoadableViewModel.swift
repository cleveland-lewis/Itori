#if os(macOS)
import Foundation
import Combine
import _Concurrency

@MainActor
protocol LoadableViewModel: AnyObject, ObservableObject {
    var isLoading: Bool { get set }
    var loadingMessage: String? { get set }
    nonisolated var objectWillChange: ObservableObjectPublisher { get }
}

extension LoadableViewModel {
    nonisolated var objectWillChange: ObservableObjectPublisher { ObservableObjectPublisher() }

    func withLoading<T>(
        message: String? = nil,
        work: @escaping () async throws -> T
    ) async rethrows -> T {
        await MainActor.run {
            self.isLoading = true
            self.loadingMessage = message
        }

        defer {
            // Use Task.detached with explicit capture to avoid Swift 6 warnings
            Task.detached { [weak self] in
                await self?.setLoadingComplete()
            }
        }

        return try await work()
    }
    
    private func setLoadingComplete() async {
        await MainActor.run {
            self.isLoading = false
            self.loadingMessage = nil
        }
    }
}
#endif
