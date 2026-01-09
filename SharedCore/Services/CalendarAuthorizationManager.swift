import Combine
import EventKit
import Foundation
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

@MainActor
final class CalendarAuthorizationManager: ObservableObject {
    static let shared = CalendarAuthorizationManager()

    @Published private(set) var eventStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

    private var hasLoggedDenied: Bool = false

    private init() {}

    var isAuthorized: Bool {
        eventStatus == .fullAccess || eventStatus == .writeOnly
    }

    var isDenied: Bool {
        eventStatus == .denied || eventStatus == .restricted
    }

    var isNotDetermined: Bool {
        eventStatus == .notDetermined
    }

    func refreshStatus() {
        eventStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess(using store: EKEventStore) async -> Bool {
        refreshStatus()
        switch eventStatus {
        case .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            let granted: Bool
            if #available(macOS 14.0, *) {
                do {
                    granted = try await store.requestFullAccessToEvents()
                } catch {
                    granted = false
                }
            } else {
                granted = await withCheckedContinuation { cont in
                    store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
                }
            }
            refreshStatus()
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func logDeniedOnce(context: String) {
        guard !hasLoggedDenied else { return }
        hasLoggedDenied = true
        DebugLogger.log("CalendarAuthDenied: \(context)")
    }

    func openSettings() {
        #if os(iOS)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        #elseif os(macOS)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                NSWorkspace.shared.open(url)
            }
        #endif
    }
}
