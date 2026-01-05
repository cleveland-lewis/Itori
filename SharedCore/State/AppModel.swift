import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var selectedPage: AppPage = .dashboard
    @Published var requestedAssignmentDueDate: Date? = nil
    @Published var isPresentingAddHomework: Bool = false
    @Published var isPresentingAddExam: Bool = false
    @Published var focusDeepLink: FocusDeepLink?
    @Published var focusWindowRequested: Bool = false

    // Reset publisher to coordinate app-level reset actions
    let resetPublisher = PassthroughSubject<Void, Never>()

    func requestReset() {
        resetPublisher.send(())
    }
}

struct FocusDeepLink {
    var mode: LocalTimerMode?
    var activityId: UUID?
}

extension Notification.Name {
    static let selectCalendarEvent = Notification.Name("roots.calendar.selectEvent")
}
