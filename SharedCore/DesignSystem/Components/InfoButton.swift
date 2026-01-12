import SwiftUI

/// Info button that shows help text on hover
struct InfoButton: View {
    let text: String
    @State private var isHovering = false

    var body: some View {
        Button {
            // No action - hover only
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(text)
        .popover(isPresented: $isHovering, arrowEdge: .trailing) {
            Text(text)
                .font(.system(size: 12))
                .padding(12)
                .frame(maxWidth: 240)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onHover { hovering in
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isHovering {
                        isHovering = hovering
                    }
                }
            } else {
                isHovering = false
            }
        }
    }
}

/// Label with optional info button
struct LabelWithInfo: View {
    let title: String
    let info: String?

    init(_ title: String, info: String? = nil) {
        self.title = title
        self.info = info
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            if let info {
                InfoButton(text: info)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InfoButton(text: "This is helpful information that appears when you hover over the info icon.")

        LabelWithInfo("Course Code", info: "A short identifier for the course, like CS101 or MATH240")

        VStack(alignment: .leading, spacing: 6) {
            LabelWithInfo("Estimated Time", info: "How long you think this assignment will take. Used for scheduling.")
            TextField("", text: .constant("60"))
                .textFieldStyle(.roundedBorder)
        }
    }
    .padding()
    .frame(width: 400)
}
