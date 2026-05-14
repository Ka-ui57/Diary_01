//
//  FeedbackView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject var store: DiaryStore
    @Binding var isEditing: Bool
    @State private var showingMenu = false
    @State private var reportToDisplay: Feedback?

    // If used as a standalone tab or root, we might want to wrap it in NavStack,
    // but if used inside HomeView's stack, we don't.
    // For simplicity, we'll assume the PARENT provides the NavigationStack.
    // We will just provide the List and Toolbar.

    var body: some View {
        // Filter for ONLY active reports for TODAY
        let todaysReports = store.feedbacks.filter {
            Calendar.current.isDateInToday($0.date)
        }

        List {
            if todaysReports.isEmpty {
                ContentUnavailableView(
                    "No Reports for Today",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Reports regenerate daily based on your activity.")
                )
            } else {
                Section("Today's Analysis") {
                    ForEach(todaysReports) { feedback in
                        VStack(alignment: .leading) {
                            Text(feedback.type.rawValue.capitalized + " Report")
                                .font(.headline)
                                .foregroundStyle(
                                    feedback.type == .goalCompletion ? .orange : .primary)

                            Text(feedback.date, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if feedback.score > 0 {
                                Text("Score: \(feedback.score)")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }

                            Text(feedback.summary)
                                .font(.body)
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }

        .sheet(item: $reportToDisplay) { report in
            ReportSheetView(report: report)
                .presentationDetents([.medium, .large])
        }
        .listStyle(.plain)
        .navigationTitle("Reports & Analysis")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Generate Monthly Report") {
                        let report = store.generateMonthlyFeedback()
                        reportToDisplay = report
                    }
                    Button("Generate Yearly Evaluation") {
                        if let report = store.generateYearlyFeedback() {
                            reportToDisplay = report
                        }
                    }
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            }

            // Add Menu Button if we are in a context that needs it (HomeView replacement)
            // We can detect this if we have a way... or just always add it as 'topBarLeading'?
            // If we are pushed from Menu, 'topBarLeading' is the Back button.
            // If we add a button item, it might sit next to it.
            // But we only want this if we are acting as the Root View.
            // Simplest heuristic: If we are passed a workable binding for editing, we are likely in HomeView.
            // But MenuView also passes a binding (constant false).
            // Let's rely on the parent (HomeView) to add the toolbar item?
            // No, HomeView's current toolbar is attached to the VStack.
            // If we replace VStack with FeedbackView, we need to attach toolbar to FeedbackView.
        }
    }
}

#Preview {
    NavigationView {  // Wrap in NavStack/View for preview context
        FeedbackView(isEditing: .constant(false))
            .environmentObject(DiaryStore())
    }
}
