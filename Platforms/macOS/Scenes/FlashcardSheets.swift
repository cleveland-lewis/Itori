#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Add Card Sheet

struct AddCardSheet: View {
    let deck: FlashcardDeck
    
    @ScaledMetric private var emptyIconSize: CGFloat = 48

    
    
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var difficulty: FlashcardDifficulty = .medium
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("ui.add.card", value: "Add Card", comment: "Add Card"))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(NSLocalizedString("ui.button.cancel", value: "Cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Form
            Form {
                Section("Front (Question)") {
                    TextEditor(text: $frontText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(.tertiaryBackground)
                        .cornerRadius(6)
                }
                
                Section("Back (Answer)") {
                    TextEditor(text: $backText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(.tertiaryBackground)
                        .cornerRadius(6)
                }
                
                Section("Difficulty") {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(FlashcardDifficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue.capitalized).tag(diff)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            
            // Actions
            HStack {
                Spacer()
                
                Button(NSLocalizedString("ui.button.cancel", value: "Cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(NSLocalizedString("ui.button.add.card", value: "Add Card", comment: "Add Card")) {
                    addCard()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(frontText.isEmpty || backText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 500)
    }
    
    private func addCard() {
        manager.addCard(
            to: deck.id,
            front: frontText,
            back: backText,
            difficulty: difficulty
        )
        dismiss()
    }
}

// MARK: - Edit Card Sheet

struct EditCardSheet: View {
    let card: Flashcard
    let deckId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var difficulty: FlashcardDifficulty = .medium
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("ui.edit.card", value: "Edit Card", comment: "Edit Card"))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(NSLocalizedString("ui.button.cancel", value: "Cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Form
            Form {
                Section("Front (Question)") {
                    TextEditor(text: $frontText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(.tertiaryBackground)
                        .cornerRadius(6)
                }
                
                Section("Back (Answer)") {
                    TextEditor(text: $backText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(.tertiaryBackground)
                        .cornerRadius(6)
                }
                
                Section("Difficulty") {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(FlashcardDifficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue.capitalized).tag(diff)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Study Progress") {
                    LabeledContent("Repetitions", value: "\(card.repetition)")
                    LabeledContent("Interval", value: "\(card.interval) days")
                    LabeledContent("Ease Factor", value: String(format: "%.2f", card.easeFactor))
                    
                    if let lastReviewed = card.lastReviewed {
                        LabeledContent("Last Reviewed", value: lastReviewed, format: .dateTime)
                    }
                }
            }
            .formStyle(.grouped)
            
            // Actions
            HStack {
                Button(NSLocalizedString("ui.button.reset.progress", value: "Reset Progress", comment: "Reset Progress")) {
                    resetProgress()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.orange)
                
                Spacer()
                
                Button(NSLocalizedString("ui.button.cancel", value: "Cancel", comment: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(NSLocalizedString("ui.button.save", value: "Save", comment: "Save")) {
                    saveCard()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(frontText.isEmpty || backText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            frontText = card.frontText
            backText = card.backText
            difficulty = card.difficulty
        }
    }
    
    private func saveCard() {
        guard let deckIndex = manager.decks.firstIndex(where: { $0.id == deckId }),
              let cardIndex = manager.decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }
        
        var deck = manager.decks[deckIndex]
        deck.cards[cardIndex].frontText = frontText
        deck.cards[cardIndex].backText = backText
        deck.cards[cardIndex].difficulty = difficulty
        
        manager.updateDeck(deck)
        dismiss()
    }
    
    private func resetProgress() {
        guard let deckIndex = manager.decks.firstIndex(where: { $0.id == deckId }),
              let cardIndex = manager.decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }
        
        var deck = manager.decks[deckIndex]
        deck.cards[cardIndex].repetition = 0
        deck.cards[cardIndex].interval = 0
        deck.cards[cardIndex].easeFactor = 2.5
        deck.cards[cardIndex].lastReviewed = nil
        deck.cards[cardIndex].dueDate = Date()
        
        manager.updateDeck(deck)
        dismiss()
    }
}

// MARK: - Deck Settings Sheet

struct DeckSettingsSheet: View {
    let deck: FlashcardDeck
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var title = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingExport = false
    @State private var exportedText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(NSLocalizedString("ui.deck.settings", value: "Deck Settings", comment: "Deck Settings"))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(NSLocalizedString("ui.button.done", value: "Done", comment: "Done")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Form
            Form {
                Section("General") {
                    TextField("Deck Name", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Statistics") {
                    LabeledContent("Total Cards", value: "\(deck.cards.count)")
                    LabeledContent("New Cards", value: "\(deck.cards.filter { $0.repetition == 0 }.count)")
                    LabeledContent("Learning", value: "\(deck.cards.filter { $0.repetition > 0 && $0.repetition < 3 }.count)")
                    LabeledContent("Review", value: "\(deck.cards.filter { $0.repetition >= 3 }.count)")
                }
                
                Section("Export") {
                    Button {
                        exportToAnki()
                    } label: {
                        Label(NSLocalizedString("ui.label.export.to.anki.format", value: "Export to Anki Format", comment: "Export to Anki Format"), systemImage: "square.and.arrow.up")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(NSLocalizedString("ui.label.delete.deck", value: "Delete Deck", comment: "Delete Deck"), systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 500)
        .onAppear {
            title = deck.title
        }
        .onDisappear {
            if title != deck.title {
                saveName()
            }
        }
        .alert("Delete Deck?", isPresented: $showingDeleteConfirmation) {
            Button(NSLocalizedString("Cancel", value: "Cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("Delete", value: "Delete", comment: ""), role: .destructive) {
                deleteDeck()
            }
        } message: {
            Text(String(format: NSLocalizedString("flashcards.delete_deck.warning", value: "This will permanently delete \"%@\" and all its cards. This action cannot be undone.", comment: "Delete deck warning"), deck.title))
        }
        .sheet(isPresented: $showingExport) {
            ExportSheet(text: exportedText, deckName: deck.title)
        }
    }
    
    private func saveName() {
        guard let index = manager.decks.firstIndex(where: { $0.id == deck.id }) else { return }
        var updatedDeck = manager.decks[index]
        updatedDeck.title = title
        manager.updateDeck(updatedDeck)
    }
    
    private func deleteDeck() {
        manager.deleteDeck(deck.id)
        dismiss()
    }
    
    private func exportToAnki() {
        exportedText = manager.exportToAnki(deck: deck)
        showingExport = true
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    let text: String
    let deckName: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(NSLocalizedString("ui.export.to.anki", value: "Export to Anki", comment: "Export to Anki"))
                    .font(.title2.bold())
                
                Spacer()
                
                Button(NSLocalizedString("ui.button.done", value: "Done", comment: "Done")) {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            if text.isEmpty {
                // Empty state when no cards
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: emptyIconSize))
                        .foregroundStyle(.secondary)
                    
                    Text(NSLocalizedString("ui.no.cards.to.export", value: "No Cards to Export", comment: "No Cards to Export"))
                        .font(.title3.weight(.semibold))
                    
                    Text(NSLocalizedString("ui.add.some.cards.to.this", value: "Add some cards to this deck to export them to Anki format.", comment: "Add some cards to this deck to export them to Anki..."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("ui.csv.format.ready.for.anki.import", value: "CSV format ready for Anki import", comment: "CSV format ready for Anki import"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: NSLocalizedString("flashcards.export.cards_count", value: "%d cards", comment: "Exported cards count"), text.components(separatedBy: "\n").count))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    ScrollView {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.tertiaryBackground)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button {
                        saveToFile()
                    } label: {
                        Label(NSLocalizedString("ui.label.download.csv", value: "Download CSV", comment: "Download CSV"), systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 600, height: 400)
    }
    
    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(deckName).csv"
        panel.title = "Export Flashcards to CSV"
        panel.message = "Save your flashcards in Anki-compatible CSV format"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                // Show success feedback
                let alert = NSAlert()
                alert.messageText = "Export Successful"
                alert.informativeText = "Your flashcards have been exported to \(url.lastPathComponent)"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                // Show error
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview("Add Card") {
    AddCardSheet(deck: FlashcardDeck(title: "Sample Deck"))
}
#endif

#if !DISABLE_PREVIEWS
#Preview("Deck Settings") {
    DeckSettingsSheet(deck: FlashcardDeck(title: "Sample Deck", cards: [
        Flashcard(frontText: "Q1", backText: "A1", difficulty: .medium, dueDate: Date()),
        Flashcard(frontText: "Q2", backText: "A2", difficulty: .easy, dueDate: Date())
    ]))
}
#endif
#endif
