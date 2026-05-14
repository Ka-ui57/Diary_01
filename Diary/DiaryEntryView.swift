//
//  DiaryEntryView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct DiaryEntryView: View {
    @EnvironmentObject var store: DiaryStore
    @Environment(\.dismiss) var dismiss

    @State private var content: String = ""
    @State private var showingFeedback = false
    @State private var feedbackText = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $content)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding()

                Button(action: saveAndEvaluate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Save & Evaluate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("AI Feedback", isPresented: $showingFeedback) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(feedbackText)
            }
        }
    }

    private func saveAndEvaluate() {
        // Generate Mock Feedback
        let entry = DiaryEntry(date: Date(), content: content, aiFeedback: nil as String?)
        let feedback = store.generateMockFeedback(for: entry)

        // Save Entry with feedback
        var newEntry = entry
        newEntry.aiFeedback = feedback
        store.addEntry(newEntry)

        // Show feedback
        feedbackText = feedback
        showingFeedback = true

        // Check if we need to generate monthly feedback (Mock Logic: e.g., every 5 entries or random)
        // For now, let's keep it simple: just save the entry.
        // The feedback view will likely just show list of entries or feedbacks.
    }
}

#Preview {
    DiaryEntryView()
        .environmentObject(DiaryStore())
}
