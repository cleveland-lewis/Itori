#if os(macOS)
import SwiftUI

// MARK: - Add Card Sheet

struct AddCardSheet: View {
    let deck: FlashcardDeck
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var difficulty: FlashcardDifficulty = .medium
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add Card")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Cancel") {
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
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }
                
                Section("Back (Answer)") {
                    TextEditor(text: $backText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
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
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Card") {
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
                Text("Edit Card")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Cancel") {
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
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }
                
                Section("Back (Answer)") {
                    TextEditor(text: $backText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
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
                Button("Reset Progress") {
                    resetProgress()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.orange)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
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
                Text("Deck Settings")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Done") {
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
                        Label("Export to Anki Format", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Deck", systemImage: "trash")
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
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDeck()
            }
        } message: {
            Text("This will permanently delete \"\(deck.title)\" and all its cards. This action cannot be undone.")
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
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Export to Anki")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("CSV format ready for Anki import")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            
            HStack {
                Spacer()
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    copied = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied!" : "Copy to Clipboard", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 600, height: 400)
    }
}

#Preview("Add Card") {
    AddCardSheet(deck: FlashcardDeck(title: "Sample Deck"))
}

#Preview("Deck Settings") {
    DeckSettingsSheet(deck: FlashcardDeck(title: "Sample Deck", cards: [
        Flashcard(frontText: "Q1", backText: "A1", difficulty: .medium, dueDate: Date()),
        Flashcard(frontText: "Q2", backText: "A2", difficulty: .easy, dueDate: Date())
    ]))
}
#endif
