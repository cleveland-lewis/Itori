import Combine
import Foundation
import WatchConnectivity

class WatchTimerSync: NSObject, ObservableObject {
    static let shared = WatchTimerSync()

    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var activityName: String?

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func startTimer(activityName: String) {
        guard let session, session.isReachable else { return }
        session.sendMessage(["action": "start", "activity": activityName], replyHandler: nil)
    }

    func pauseTimer() {
        guard let session, session.isReachable else { return }
        session.sendMessage(["action": "pause"], replyHandler: nil)
    }

    func stopTimer() {
        guard let session, session.isReachable else { return }
        session.sendMessage(["action": "stop"], replyHandler: nil)
    }
}

extension WatchTimerSync: WCSessionDelegate {
    func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error _: Error?) {
        print("Watch session activated: \(activationState.rawValue)")
    }

    #if os(iOS)
        func sessionDidBecomeInactive(_: WCSession) {
            // Required on iOS
        }

        func sessionDidDeactivate(_ session: WCSession) {
            // Required on iOS
            session.activate()
        }
    #endif

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "timerUpdate":
                    self.isRunning = message["isRunning"] as? Bool ?? false
                    self.elapsedTime = message["elapsed"] as? TimeInterval ?? 0
                    self.activityName = message["activity"] as? String
                case "timerStopped":
                    self.isRunning = false
                    self.elapsedTime = 0
                    self.activityName = nil
                default:
                    break
                }
            }
        }
    }
}
