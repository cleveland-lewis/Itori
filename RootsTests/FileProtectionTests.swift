import Foundation
import XCTest

final class FileProtectionTests: XCTestCase {
    func testWritesUseCompleteFileProtection() throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("file_protection_test-\(UUID().uuidString)")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let data = Data("hello".utf8)
        try data.write(to: tempURL, options: [.atomic, .completeFileProtection])

        let attributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
        let protection = attributes[.protectionKey] as? FileProtectionType

        XCTAssertEqual(protection, .complete, "Data writes should set .completeFileProtection")
    }
}
