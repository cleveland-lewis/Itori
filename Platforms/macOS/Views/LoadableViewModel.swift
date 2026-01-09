#if os(macOS)
    import _Concurrency
    import Combine
    import Foundation

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

            do {
                let result = try await work()
                self.isLoading = false
                self.loadingMessage = nil
                return result
            } catch {
                self.isLoading = false
                self.loadingMessage = nil
                throw error
            }
        }
    }
#endif
