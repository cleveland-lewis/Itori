//
//  SnapshotTestHarness.swift
//  RootsUITests
//
//  Snapshot harness to record and compare UI screenshots without
//  pulling in a third-party dependency. Set `RECORD_UI_SNAPSHOTS=1`
//  to regenerate baselines under `RootsUITests/__Snapshots__/`.
//

import XCTest

enum SnapshotAppearance: String, CaseIterable {
    case light
    case dark
}

enum SnapshotContentSize: String, CaseIterable {
    case standard = "UICTContentSizeCategoryM"
    case accessibilityXXXL = "UICTContentSizeCategoryAccessibilityXXXL"

    var displayName: String {
        switch self {
        case .standard: return "standard"
        case .accessibilityXXXL: return "dynamic-axxxl"
        }
    }
}

struct SnapshotConfiguration: Hashable {
    let appearance: SnapshotAppearance
    let contentSize: SnapshotContentSize

    var suffix: String {
        "\(appearance.rawValue)-\(contentSize.displayName)"
    }

    static var defaults: [SnapshotConfiguration] {
        [
            SnapshotConfiguration(appearance: .light, contentSize: .standard),
            SnapshotConfiguration(appearance: .dark, contentSize: .standard),
            SnapshotConfiguration(appearance: .light, contentSize: .accessibilityXXXL),
            SnapshotConfiguration(appearance: .dark, contentSize: .accessibilityXXXL)
        ]
    }
}

final class SnapshotAsserter {
    private let recordMode: Bool
    private let snapshotsDirectory: URL
    private let fileManager = FileManager.default

    init(file: StaticString = #filePath) {
        recordMode = ProcessInfo.processInfo.environment["RECORD_UI_SNAPSHOTS"] == "1"
        let sourceFile = URL(fileURLWithPath: "\(file)")
        snapshotsDirectory = sourceFile.deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__", isDirectory: true)
    }

    func assertSnapshot(app: XCUIApplication, name: String, config: SnapshotConfiguration, line: UInt = #line) {
        let screenshot = app.screenshot()
        let data = screenshot.pngRepresentation
        let fileURL = snapshotsDirectory.appendingPathComponent("\(name)__\(config.suffix).png")

        if recordMode {
            writeBaseline(data: data, to: fileURL)
            addAttachment(name: "\(name) [recorded \(config.suffix)]", screenshot: screenshot)
            return
        }

        guard let baseline = try? Data(contentsOf: fileURL) else {
            XCTFail("Missing baseline for \(name) @ \(config.suffix). Run with RECORD_UI_SNAPSHOTS=1 to capture.", line: line)
            addAttachment(name: "\(name) [missing baseline]", screenshot: screenshot)
            return
        }

        guard baseline == data else {
            addAttachment(name: "\(name) [current \(config.suffix)]", screenshot: screenshot)
            addAttachment(name: "\(name) [baseline \(config.suffix)]", data: baseline)
            XCTFail("Snapshot mismatch for \(name) @ \(config.suffix). Re-record if intentional.", line: line)
            return
        }
    }

    private func writeBaseline(data: Data, to url: URL) {
        try? fileManager.createDirectory(at: snapshotsDirectory, withIntermediateDirectories: true)
        try? data.write(to: url)
    }

    private func addAttachment(name: String, screenshot: XCUIScreenshot) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in
            activity.add(attachment)
        }
    }

    private func addAttachment(name: String, data: Data) {
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: name) { activity in
            activity.add(attachment)
        }
    }
}

extension XCUIApplication {
    /// Creates a configured app instance for a snapshot run.
    static func snapshotApp(config: SnapshotConfiguration) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_COLOR_SCHEME"] = config.appearance.rawValue
        app.launchEnvironment["UITEST_CONTENT_SIZE"] = config.contentSize.rawValue
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["UITEST_SNAPSHOT_MODE"] = "1"
        return app
    }
}
