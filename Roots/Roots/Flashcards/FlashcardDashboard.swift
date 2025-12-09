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
                        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                            Text(deck.title).font(DesignSystem.Typography.subHeader)
                            Text("\(deck.cards.count) cards")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(DesignSystem.Layout.padding.card)
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(DesignSystem.Layout.padding.card)
        }
        .sheet(item: $selectedDeck) { deck in
            StudySessionView(deck: deck)
        }
    }
}
