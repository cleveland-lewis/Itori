import SwiftUI

/// Editor for creating and customizing timer presets
/// Feature: Phase A - Quick Timer Presets
struct PresetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TimerPageViewModel
    
    @State private var presetName: String = ""
    @State private var durationMinutes: Int = 25
    @State private var selectedEmoji: String = "⏱️"
    @State private var selectedMode: TimerMode = .timer
    @State private var selectedColorHex: String = "#007AFF"
    
    let editingPreset: TimerPreset?
    let onSave: (TimerPreset) -> Void
    
    init(
        viewModel: TimerPageViewModel,
        editingPreset: TimerPreset? = nil,
        onSave: @escaping (TimerPreset) -> Void
    ) {
        self.viewModel = viewModel
        self.editingPreset = editingPreset
        self.onSave = onSave
        
        if let preset = editingPreset {
            _presetName = State(initialValue: preset.name)
            _durationMinutes = State(initialValue: Int(preset.duration / 60))
            _selectedEmoji = State(initialValue: preset.emoji ?? "⏱️")
            _selectedMode = State(initialValue: preset.mode)
            _selectedColorHex = State(initialValue: preset.colorHex ?? "#007AFF")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preset Details") {
                    TextField("Name", text: $presetName)
                        .accessibilityLabel("Preset name")
                    
                    Stepper(
                        "\(durationMinutes) minutes",
                        value: $durationMinutes,
                        in: 1...180
                    )
                    .accessibilityLabel("Duration: \(durationMinutes) minutes")
                    
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(TimerMode.userSelectableModes) { mode in
                            Label(mode.displayName, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("", text: $selectedEmoji)
                            .multilineTextAlignment(.trailing)
                            .font(.title)
                            .frame(width: 60)
                            .accessibilityLabel("Preset emoji")
                    }
                    
                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: selectedColorHex) ?? .blue },
                        set: { selectedColorHex = $0.toHex() ?? "#007AFF" }
                    ))
                }
                
                Section {
                    Button("Save Preset") {
                        savePreset()
                    }
                    .disabled(presetName.isEmpty)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Save preset button")
                }
            }
            .navigationTitle(editingPreset == nil ? "New Preset" : "Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func savePreset() {
        let preset = TimerPreset(
            id: editingPreset?.id ?? UUID(),
            name: presetName,
            duration: TimeInterval(durationMinutes * 60),
            emoji: selectedEmoji.isEmpty ? nil : selectedEmoji,
            colorHex: selectedColorHex,
            mode: selectedMode,
            isDefault: false,
            sortOrder: editingPreset?.sortOrder ?? 100
        )
        
        onSave(preset)
        dismiss()
        
        LOG_UI(.info, "PresetEditor", "Saved preset: \(preset.name)")
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#if DEBUG
#Preview {
    PresetEditorView(viewModel: TimerPageViewModel.shared) { preset in
        print("Saved preset: \(preset.name)")
    }
}
#endif
