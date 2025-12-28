import SwiftUI

struct FlashcardsView: View {
    @StateObject private var manager = FlashcardManager.shared
    @StateObject private var coursesStore = CoursesStore.shared!
    @State private var selectedDeck: FlashcardDeck?
    @State private var showingAddDeck = false
    @State private var showingStudySession = false
    @State private var searchText = ""
    
    private var filteredDecks: [FlashcardDeck] {
        if searchText.isEmpty {
            return manager.decks
        }
        return manager.decks.filter { deck in
            deck.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var currentSemesterCourses: [Course] {
        coursesStore.currentSemesterCourses
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            if let deck = selectedDeck {
                DeckDetailView(deck: deck)
            } else {
                emptyDetailView
            }
        }
        .sheet(isPresented: $showingAddDeck) {
            AddDeckSheet()
        }
        .navigationTitle("Flashcards")
    }
    
    // MARK: - Sidebar
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Text("Decks")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button {
                        showingAddDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Create new deck")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                TextField("Search decks", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Current Semester Courses
                    if !currentSemesterCourses.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Semester")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 4) {
                                ForEach(currentSemesterCourses) { course in
                                    CourseRowView(
                                        course: course,
                                        isSelected: false
                                    ) {
                                        createDeckForCourse(course)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Deck list
                    if !filteredDecks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All Decks")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 4) {
                                ForEach(filteredDecks) { deck in
                                    DeckRowView(
                                        deck: deck,
                                        isSelected: selectedDeck?.id == deck.id
                                    ) {
                                        selectedDeck = deck
                                    }
                                }
                            }
                        }
                    } else if currentSemesterCourses.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 250)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func createDeckForCourse(_ course: Course) {
        // Check if deck already exists for this course
        if let existingDeck = manager.decks.first(where: { $0.courseID == course.id }) {
            selectedDeck = existingDeck
        } else {
            let newDeck = manager.createDeck(title: course.title, courseID: course.id)
            selectedDeck = newDeck
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(searchText.isEmpty ? "No Decks" : "No Results")
                .font(.headline)
            
            if searchText.isEmpty {
                Text("Create your first flashcard deck to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    showingAddDeck = true
                } label: {
                    Label("New Deck", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text("Select a Deck")
                .font(.title2.bold())
            
            Text("Choose a deck from the sidebar to view cards and study")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Course Row

struct CourseRowView: View {
    let course: Course
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with course color
                Circle()
                    .fill(courseColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                
                // Course info
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(course.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Add deck indicator
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Create flashcard deck for \(course.title)")
    }
    
    private var courseColor: Color {
        if let hex = course.colorHex {
            return Color(hex: hex) ?? .accentColor
        }
        return .accentColor
    }
}

// MARK: - Deck Row

struct DeckRowView: View {
    let deck: FlashcardDeck
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var manager = FlashcardManager.shared
    
    private var dueCount: Int {
        manager.dueCards(for: deck.id).count
    }
    
    private var newCount: Int {
        deck.cards.filter { $0.repetition == 0 }.count
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isSelected ? .white : .secondary)
                    }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? .primary : .primary)
                    
                    HStack(spacing: 8) {
                        if dueCount > 0 {
                            Label("\(dueCount)", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if newCount > 0 {
                            Label("\(newCount)", systemImage: "sparkle")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("\(deck.cards.count) cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Deck Sheet

struct AddDeckSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = FlashcardManager.shared
    
    @State private var title = ""
    @State private var selectedCourse: UUID?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("New Deck")
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
                Section {
                    TextField("Deck Name", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Link to Course (Optional)") {
                    Text("Course selection coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            
            Spacer()
            
            // Actions
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    createDeck()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 300)
    }
    
    private func createDeck() {
        _ = manager.createDeck(title: title, courseID: selectedCourse)
        dismiss()
    }
}

#Preview {
    FlashcardsView()
}
