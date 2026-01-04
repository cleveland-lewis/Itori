#if os(macOS)
import XCTest
import Combine
@testable import Roots

@MainActor
final class LoadableViewModelTests: XCTestCase {
    
    func testWithLoadingSetsLoadingState() async {
        let viewModel = TestLoadableViewModel()
        
        let result = await viewModel.withLoading {
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testWithLoadingMessage() async {
        let viewModel = TestLoadableViewModel()
        
        let task = Task {
            await viewModel.withLoading(message: "Loading...") {
                try? await Task.sleep(nanoseconds: 100_000_000)
                return "done"
            }
        }
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(viewModel.loadingMessage, "Loading...")
        
        _ = await task.value
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNil(viewModel.loadingMessage)
    }
    
    func testWithLoadingHandlesErrors() async {
        let viewModel = TestLoadableViewModel()
        
        do {
            try await viewModel.withLoading {
                throw TestError.failed
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertFalse(viewModel.isLoading)
        }
    }
}

@MainActor
private class TestLoadableViewModel: LoadableViewModel {
    @Published var isLoading = false
    @Published var loadingMessage: String?
}

private enum TestError: Error {
    case failed
}
#endif
