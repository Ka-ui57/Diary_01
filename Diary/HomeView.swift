//
//  HomeView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var showingMenu = false

    // Daily Entry State
    @State private var content: String = ""
    @State private var isEditing: Bool = true
    @State private var showingFeedback = false
    @State private var feedbackText = ""
    // Feedback Sheet State
    @State private var showingReportSheet = false
    @State private var reportToDisplay: Feedback?
    @State private var currentDetails: (id: UUID, date: Date)? = nil

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    VStack(spacing: 0) {
                        // Header: Date
                        Text(Date(), format: .dateTime.weekday(.wide).month().day())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                            .frame(maxWidth: .infinity)

                        // Editor
                        TextEditor(text: $content)
                            .padding()
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(maxHeight: .infinity)

                        // Footer
                        VStack {
                            if isLoading {
                                ProgressView("Consulting AI...")
                                    .padding()
                            } else {
                                Button(action: saveAndEvaluate) {
                                    Text("Complete Entry")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            content.trimmingCharacters(in: .whitespacesAndNewlines)
                                                .isEmpty
                                                ? Color.gray : Color.blue
                                        )
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                .disabled(
                                    content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Daily Write")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showingMenu = true }) {
                                Image(systemName: "line.3.horizontal")
                                    .imageScale(.large)
                            }
                        }
                    }
                } else {
                    // Report / Analysis Mode
                    FeedbackView(isEditing: $isEditing)
                        .toolbar {
                            // Add Menu Button here as well since FeedbackView is now the root content
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { showingMenu = true }) {
                                    Image(systemName: "line.3.horizontal")
                                        .imageScale(.large)
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingMenu) {
                MenuView(isEditing: $isEditing)
                    .presentationDetents([.medium, .large])
                    .environmentObject(store)
            }
            .sheet(item: $reportToDisplay) { report in
                ReportSheetView(report: report)
                    .presentationDetents([.medium, .large])
            }
            // Removed Alert: Transition directly to view
            .onAppear(perform: loadTodayEntry)
        }
    }

    private func loadTodayEntry() {
        if let todayEntry = store.getEntry(for: Date()) {
            content = todayEntry.content
            currentDetails = (todayEntry.id, todayEntry.date)
            isEditing = false  // If entry exists, default to Read Mode
        } else {
            // New day, new entry
            content = ""
            currentDetails = nil
            isEditing = true
        }
    }

    @State private var isLoading = false
    private let geminiService = GeminiService()

    private func saveAndEvaluate() {
        // Use existing ID/Date if updating, or new if creating
        let id = currentDetails?.id ?? UUID()
        let currentEntryDate = currentDetails?.date ?? Date()

        // Create base entry (updated later if feedback exists)
        let entry = DiaryEntry(id: id, date: currentEntryDate, content: content, aiFeedback: nil)

        isLoading = true

        Task {
            var dailyFeedback: String? = nil
            var shouldGenerateDailyFeedback = true

            // Check if we are updating an existing entry that already has feedback
            if let existingEntry = store.getEntry(for: currentEntryDate),
                existingEntry.aiFeedback != nil
            {
                // Determine if we should preserve it. User requested: "Edit content, but don't re-do daily feedback"
                dailyFeedback = existingEntry.aiFeedback
                shouldGenerateDailyFeedback = false
            }

            // 1. Daily Feedback (Only First Week AND if we need to generate it)
            if store.isFirstWeek && shouldGenerateDailyFeedback {
                do {
                    dailyFeedback = try await geminiService.generateFeedback(for: content)
                    // Append Goal Progress
                    if store.goal != nil {
                        let progressPercent = Int(store.progress * 100)
                        dailyFeedback? += "\n\nGoal Progress: \(progressPercent)%"
                    }
                } catch {
                    print("Gemini Daily Error: \(error)")
                }
            }

            // 2. Monthly Feedback Check (Check Previous Month)
            let calendar = Calendar.current
            // Look at month before "today" (assuming usage is near-time).
            // Actually, we should check if we just crossed a month boundary?
            // Simplest: Check if previous month has a report. If not, and we have entries, generate it.
            if let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: Date()) {
                let comps = calendar.dateComponents([.year, .month], from: prevMonthDate)
                if let year = comps.year, let month = comps.month {
                    if !store.hasMonthlyReport(forMonth: month, year: year) {
                        let monthEntries = store.getEntries(forMonth: month, year: year)
                        if !monthEntries.isEmpty {
                            do {
                                let summary = try await geminiService.generateMonthlyFeedback(
                                    entries: monthEntries.map(\.content))
                                let report = Feedback(
                                    id: UUID(), date: Date(), summary: summary, score: 80,
                                    type: .monthly)
                                await MainActor.run {
                                    store.addFeedback(report)
                                    reportToDisplay = report
                                    showingReportSheet = true
                                }
                            } catch {
                                print("Gemini Monthly Error: \(error)")
                            }
                        }
                    }
                }
            }

            // 3. Goal Completion Feedback Check (Check if Today == Target Date)
            // Replaces Yearly Feedback
            if store.isGoalEndDate(date: currentEntryDate), let goal = store.goal {
                let monthlySummaries = store.getMonthlyFeedbacks(for: goal)
                // (Optional: Check if we already did this? For now, allow re-trigger if they edit the last day entry)

                if !monthlySummaries.isEmpty {
                    do {
                        let review = try await geminiService.generateGoalCompletionFeedback(
                            monthlySummaries: monthlySummaries,
                            goalTitle: goal.title,
                            goalDescription: goal.description
                        )

                        let report = Feedback(
                            id: UUID(), date: Date(), summary: review, score: 100,
                            type: .goalCompletion)
                        await MainActor.run {
                            store.addFeedback(report)
                            reportToDisplay = report
                            showingReportSheet = true
                        }
                    } catch {
                        print("Gemini Goal Completion Error: \(error)")
                    }
                }
            }

            // 4. Save Entry & Daily Report
            var newEntry = entry
            newEntry.aiFeedback = dailyFeedback  // Might be nil if not first week

            await MainActor.run {
                store.addEntry(newEntry)

                // Only save Daily Feedback Report if it exists AND it's new
                if let feedback = dailyFeedback, shouldGenerateDailyFeedback {
                    let report = Feedback(
                        id: UUID(),
                        date: currentEntryDate,
                        summary: feedback,
                        score: 100,
                        type: .daily
                    )
                    store.addFeedback(report)

                    // Show Daily Feedback immediately
                    reportToDisplay = report
                    showingReportSheet = true
                }

                isLoading = false
                isEditing = false
                currentDetails = (id, currentEntryDate)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DiaryStore())
}
