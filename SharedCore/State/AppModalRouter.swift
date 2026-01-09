import Combine
import Foundation

@MainActor
final class AppModalRouter: ObservableObject {
    static let shared = AppModalRouter()

    @Published var route: AppModalRoute? = nil

    func present(_ route: AppModalRoute) {
        self.route = route
    }

    func clear() {
        route = nil
    }
}

enum AppModalRoute: Hashable, Identifiable {
    case addAssignment
    case addGrade
    case planner

    var id: String {
        switch self {
        case .addAssignment: "addAssignment"
        case .addGrade: "addGrade"
        case .planner: "planner"
        }
    }
}
