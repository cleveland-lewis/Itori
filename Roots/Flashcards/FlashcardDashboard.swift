import SwiftUI

struct FlashcardDashboard: View {
    @EnvironmentObject var flashManager: FlashcardManager
    @State private var selectedDeck: FlashcardDeck?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                ForEach(flashManager.decks) { deck in
                    Button {
                        selectedDeck = deck
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(deck.title).font(.headline)
                            Text("\(deck.cards.count) cards")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .sheet(item: $selectedDeck) { deck in
            StudySessionView(deck: deck)
        }
    }
}
