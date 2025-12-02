import SwiftUI

struct TimerGraphsView: View {
    enum GraphMode { case live, history }

    let mode: GraphMode
    let sessions: [FocusSession]
    let currentSession: FocusSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if mode == .live {
                if let s = currentSession {
                    ProgressView(value: progress(for: s))
                        .progressViewStyle(.linear)
                    Text("Live session progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No active session")
                        .foregroundColor(.secondary)
                }
            } else {
                // Placeholder historical summary
                VStack(alignment: .leading) {
                    Text("History Summary")
                        .font(.headline)
                    ForEach(lastDays(7), id: \.self) { d in
                        HStack {
                            Text(d.shortString)
                            Spacer()
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: CGFloat(arc4random_uniform(100)), height: 10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func progress(for s: FocusSession) -> Double {
        guard let start = s.startedAt, let planned = s.plannedDuration else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return min(max(elapsed / planned, 0), 1)
    }

    private func lastDays(_ n: Int) -> [Date] {
        (0..<n).map { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? Date() }
    }
}

fileprivate extension Date {
    var shortString: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: self)
    }
}
