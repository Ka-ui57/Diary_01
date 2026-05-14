//
//  MenuView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var store: DiaryStore
    @Environment(\.dismiss) var dismiss
    @Binding var isEditing: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let goal = store.goal {
                        NavigationLink(destination: GoalView()) {
                            VStack(alignment: .leading) {
                                Text("Current Goal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(goal.title)
                                    .font(.headline)
                            }
                        }
                    } else {
                        NavigationLink(destination: GoalView()) {
                            Text("Tap to set your yearly goal")
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Menu") {
                    // Edit Today's Entry Button
                    Button(action: {
                        isEditing = true
                        dismiss()
                    }) {
                        Label("Edit Today's Entry", systemImage: "pencil.and.scribble")
                    }
                    // Only enable if it's actually today?
                    // The HomeView logic handles "Entry Locked" but here we can just allow triggering the state.
                    // HomeView will decide if it's editable, but usually "today" is implied for this context.

                    NavigationLink(destination: HistoryView()) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                    NavigationLink(destination: FeedbackView(isEditing: .constant(false))) {
                        Label("Reports & Analysis", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                Section {
                    Text("About Diary App")
                    Text("Version 1.0.0")
                        .foregroundStyle(.secondary)
                }

            }
            .listStyle(.plain)
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MenuView(isEditing: .constant(false))
        .environmentObject(DiaryStore())
}
