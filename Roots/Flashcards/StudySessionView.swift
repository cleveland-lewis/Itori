import SwiftUI

struct StudySessionView: View {
    @EnvironmentObject var flashManager: FlashcardManager
    @State var deck: FlashcardDeck
    @State private var currentCard: Flashcard?
    @State private var flipped = false

    var body: some View {
        VStack(spacing: 20) {
            Text(deck.title)
                .font(DesignSystem.Typography.header)

            if let card = currentCard {
                cardView(for: card)
                actionBar(for: card)
            } else {
                Text("No due cards right now. You're caught up!")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Layout.padding.card)
        .frame(minWidth: 520, minHeight: 520)
        .onAppear(perform: loadNextCard)
    }

    private func loadNextCard() {
        guard let refreshedDeck = flashManager.deck(withId: deck.id) else { return }
        deck = refreshedDeck
        let due = flashManager.dueCards(for: deck.id)
        currentCard = due.first
        flipped = false
    }

    @ViewBuilder
    private func cardView(for card: Flashcard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignSystem.Materials.card)
                .frame(height: 320)
                .overlay(
                    VStack {
                        if !flipped {
                            Text(card.frontText)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(card.backText)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(DesignSystem.Layout.padding.card)
                )
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .onTapGesture { withAnimation(.spring()) { flipped.toggle() } }
        }
    }

    private func actionBar(for card: Flashcard) -> some View {
        let estimates = intervalEstimates(for: card)
        return HStack(spacing: DesignSystem.Layout.spacing.small) {
            ratingButton(title: "Again", icon: "arrow.counterclockwise", subtitle: "< 1m", color: .red) {
                grade(card: card, rating: .again)
            }
            ratingButton(title: "Hard", icon: "exclamationmark.triangle", subtitle: estimates.hard, color: .orange) {
                grade(card: card, rating: .hard)
            }
            ratingButton(title: "Good", icon: "checkmark.circle", subtitle: estimates.good, color: .green) {
                grade(card: card, rating: .good)
            }
            ratingButton(title: "Easy", icon: "sparkles", subtitle: estimates.easy, color: .blue) {
                grade(card: card, rating: .easy)
            }
        }
        .padding(.horizontal, DesignSystem.Layout.spacing.medium)
        .padding(.vertical, DesignSystem.Layout.spacing.small)
        .background(DesignSystem.Materials.hud, in: Capsule())
    }

    private func ratingButton(title: String, icon: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.body)
                Text(title)
                    .font(DesignSystem.Typography.body)
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .rootsStandardInteraction()
    }

    private func grade(card: Flashcard, rating: FlashcardManager.FlashcardRating) {
        flashManager.grade(cardId: card.id, in: deck.id, rating: rating)
        loadNextCard()
    }

    private func intervalEstimates(for card: Flashcard) -> (hard: String, good: String, easy: String) {
        let hard = flashManager.estimateInterval(card: card, grade: .hard)
        let good = flashManager.estimateInterval(card: card, grade: .good)
        let easy = flashManager.estimateInterval(card: card, grade: .easy)
        return (hard: hard, good: good, easy: easy)
    }
}
