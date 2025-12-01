//
//  ContentView.swift
//  Roots
//
//  Created by Cleveland Lewis III on 11/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                // Sidebar: Assignments entry
                NavigationLink("Assignments", destination: AssignmentsView())

                // Sidebar: Planner entry
                NavigationLink("Planner", destination: PlannerView())

                // Sidebar: Courses entry
                NavigationLink("Courses", destination: CoursesView())

                // Sidebar: Grades entry
                NavigationLink("Grades", destination: GradesView())

                // Sidebar: Calendar entry
                NavigationLink("Calendar", destination: CalendarView())

                // Sidebar: Dashboard entry
                NavigationLink("Dashboard", destination: DashboardView())

            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                // Settings button: navigationBarLeading on iOS, automatic on macOS
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    NavigationLink("Settings", destination: SettingsView())
                }
                #endif

                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                #endif

                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            DashboardView()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
