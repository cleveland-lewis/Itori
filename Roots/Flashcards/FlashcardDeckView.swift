import SwiftUI

struct FlashcardDeckView: View {
    @EnvironmentObject var flashManager: FlashcardManager
    var deck: FlashcardDeck

    var body: some View {
        StudySessionView(deck: deck)
    }
}
