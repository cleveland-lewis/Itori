#if os(macOS)
import SwiftUI

/// Sheet for creating a new course module
struct CreateModuleSheet: View {
    let courseId: UUID
    let onSave: (CourseOutlineNode) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var moduleName: String = ""
    @State private var moduleType: CourseOutlineNodeType = .module
    
    private var isValidName: Bool {
        !moduleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Create Module")
                    .font(.title2.weight(.semibold))
                Text("Add a new organizational module to this course")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Module Name")
                        .font(.headline.weight(.medium))
                    TextField("e.g., Introduction to Biology", text: $moduleName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.headline.weight(.medium))
                    Picker("Module Type", selection: $moduleType) {
                        ForEach(CourseOutlineNodeType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.secondaryBackground.opacity(0.3))
            )
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    createModule()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidName)
            }
        }
        .padding(24)
        .frame(width: 480, height: 340)
    }
    
    private func createModule() {
        let trimmedName = moduleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let module = CourseOutlineNode(
            courseId: courseId,
            parentId: nil,
            type: moduleType,
            title: trimmedName,
            sortIndex: 0
        )
        
        onSave(module)
        dismiss()
    }
}

#endif
