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
            Task { @MainActor in
                self.isLoading = false
                self.loadingMessage = nil
            }
        }

        return try await work()
    }
}
#endif
