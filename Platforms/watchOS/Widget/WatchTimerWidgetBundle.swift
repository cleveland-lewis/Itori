#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

@main
struct WatchTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchTimerWidget()
    }
}
#else
import SwiftUI

@main
struct WatchTimerWidgetBundle {
    static func main() {}
}
#endif
