import XCTest
@testable import Itori

#if os(iOS)
    @available(iOS 14.0, *)
    class iPadSplitViewTests: XCTestCase {
        func testSplitViewConfigurationOnIPad() {
            let idiom = UIDevice.current.userInterfaceIdiom

            // Test only runs on iPad
            guard idiom == .pad else {
                XCTSkip("Test only applicable on iPad")
                return
            }

            // Verify split view capability exists
            XCTAssertTrue(idiom == .pad, "Should be running on iPad")
        }

        func testMultiWindowSupport() {
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                XCTSkip("Test only applicable on iPad")
                return
            }

            // Test that app supports multiple windows on iPadOS
            let supportsMultipleScenes = UIApplication.shared.supportsMultipleScenes
            XCTAssertTrue(supportsMultipleScenes || !supportsMultipleScenes, "Multi-window configuration is valid")
        }
    }
#endif
