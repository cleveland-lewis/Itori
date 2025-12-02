import SwiftUI

struct ActivityEditorView: View {
    @Binding var activity: TimerActivity?
    var onSave: (TimerActivity) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedCategory: StudyCategory = .other
    @State private var emoji: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text(activity == nil ? "New Activity" : "Edit Activity")
                .font(.title2).fontWeight(.semibold)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $selectedCategory) {
                ForEach(StudyCategory.allCases, id: \.self) { c in Text(c.rawValue.capitalized).tag(c) }
            }
            .pickerStyle(.menu)

            HStack {
                TextField("Emoji", text: $emoji)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Spacer()
            }

            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                Button("Save") {
                    let act = TimerActivity(id: activity?.id ?? UUID(), name: name.isEmpty ? "Untitled" : name, studyCategory: selectedCategory, emoji: emoji.isEmpty ? nil : emoji, collectionID: activity?.collectionID)
                    onSave(act)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(20)
        .onAppear {
            if let a = activity {
                name = a.name
                selectedCategory = a.studyCategory ?? .other
                emoji = a.emoji ?? ""
            }
        }
        .frame(minWidth: 420)
    }
}
