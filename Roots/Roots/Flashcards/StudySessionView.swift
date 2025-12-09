import SwiftUI

struct StudySessionView: View {
    @EnvironmentObject var flashManager: FlashcardManager
    @State var deck: FlashcardDeck
    @State private var index: Int = 0
    @State private var flipped: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text(deck.title).font(.title2.weight(.semibold))

            if deck.cards.isEmpty {
                Text("No cards in this deck")
                    .foregroundStyle(.secondary)
            } else {
                let card = deck.cards[index % deck.cards.count]
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DesignSystem.Materials.card)
                        .frame(height: 320)
                        .overlay(
                            VStack {
                                if !flipped {
                                    Text(card.frontText).font(.title3).multilineTextAlignment(.center)
                                } else {
                                    Text(card.backText).font(.title3).multilineTextAlignment(.center)
                                }
                            }
                            .padding(DesignSystem.Layout.padding.card)
                        )
                        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        .onTapGesture { withAnimation(.spring()) { flipped.toggle() } }
                }

                if flipped {
                    HStack(spacing: 12) {
                        Button("Hard") { nextCard() }
                        Button("Good") { nextCard() }
                        Button("Easy") { nextCard() }
                    }
                    .buttonStyle(RootsLiquidButtonStyle())
                }

                Button("Export to Anki") {
                    let csv = flashManager.exportToAnki(deck: deck)
                    // write to desktop for now
                    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/\(deck.title)-anki.csv")
                    try? csv.data(using: .utf8)?.write(to: url)
                }
                .buttonStyle(RootsLiquidButtonStyle())
            }

            Spacer()
        }
        .padding(DesignSystem.Layout.padding.card)
        .frame(minWidth: 520, minHeight: 520)
    }

    private func nextCard() {
        index = (index + 1) % max(1, deck.cards.count)
        flipped = false
    }
}
