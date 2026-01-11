#if os(macOS)
    import SwiftUI

    struct PermissionHelpPopup: View {
        enum PermissionKind { case calendar, reminders }
        let kind: PermissionKind
        let action: () -> Void
        @Environment(\.dismiss) var dismiss

        var body: some View {
            AppPopupContainer(title: "Permission Required", subtitle: "Itori needs permission to access your data") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString(
                        "ui.1.click.the.button.below.to.open.system.settings",
                        value: "1. Click the button below to open System Settings.",
                        comment: "1. Click the button below to open System Settings."
                    ))
                    Text(NSLocalizedString(
                        "ui.2.find.itori.in.the.list",
                        value: "2. Find 'Itori' in the list.",
                        comment: "2. Find 'Itori' in the list."
                    ))
                    Text(NSLocalizedString(
                        "ui.3.toggle.the.switch.to.on",
                        value: "3. Toggle the switch to ON.",
                        comment: "3. Toggle the switch to ON."
                    ))
                    Text(NSLocalizedString(
                        "ui.4.return.here.to.sync",
                        value: "4. Return here to sync.",
                        comment: "4. Return here to sync."
                    ))

                    Spacer()

                    HStack {
                        Spacer()
                        Button(kind == .calendar ? "Open Calendar Settings" : "Open Reminders Settings") {
                            action()
                            dismiss()
                        }
                        .buttonStyle(AppLiquidButtonStyle())
                    }
                }
            } footer: {
                EmptyView()
            }
        }
    }
#endif
