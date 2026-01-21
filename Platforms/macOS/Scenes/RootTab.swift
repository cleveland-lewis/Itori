#if os(macOS)
    import Foundation

    public enum RootTab: String, CaseIterable, Identifiable {
        case dashboard
        case calendar
        case planner
        case assignments
        case courses
        case grades
        case timer
        case flashcards
        // v1.1: Practice tests disabled - feature coming in v2.0
        // case practice

        public var id: String { rawValue }
    }
#endif
