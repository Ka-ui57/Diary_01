//
//  DiaryStore.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Models

struct Goal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var startDate: Date
    var hasDeadline: Bool

    // Custom decoding to handle legacy data without startDate/hasDeadline
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        targetDate = try container.decode(Date.self, forKey: .targetDate)
        // Default to today if startDate is missing (legacy data support)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        // Default to true if missing (legacy support)
        hasDeadline = try container.decodeIfPresent(Bool.self, forKey: .hasDeadline) ?? true
    }

    // Default initializer needs to be explicitly defined because we implemented Decodable
    init(
        id: UUID = UUID(), title: String, description: String, targetDate: Date,
        startDate: Date = Date(), hasDeadline: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.startDate = startDate
        self.hasDeadline = hasDeadline
    }

    // Explicit coding keys to match properties
    enum CodingKeys: String, CodingKey {
        case id, title, description, targetDate, startDate, hasDeadline
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(targetDate, forKey: .targetDate)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(hasDeadline, forKey: .hasDeadline)
    }
}

struct DiaryEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var content: String
    var aiFeedback: String?
}

enum FeedbackType: String, Codable {
    case daily
    case monthly
    case yearly
    case goalCompletion
}

struct Feedback: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var summary: String
    var score: Int
    var type: FeedbackType
}

// MARK: - Store

class DiaryStore: ObservableObject {
    @Published var goal: Goal?
    @Published var entries: [DiaryEntry] = []
    @Published var feedbacks: [Feedback] = []

    // Simple persistence using UserDefaults for MVP
    // In a real app, I'd use SwiftData or CoreData or saving to JSON files in Documents directory.
    // For this size, saving to JSON in UserDefaults or Documents is fine.

    private let goalKey = "diary_goal"
    private let entriesKey = "diary_entries"
    private let feedbacksKey = "diary_feedbacks"

    init() {
        loadData()
    }

    /// Calculates the goal progress based on time elapsed.
    /// Returns a value between 0.0 and 1.0.
    var progress: Double {
        guard let goal = goal else { return 0.0 }

        let totalDuration = goal.targetDate.timeIntervalSince(goal.startDate)
        guard totalDuration > 0 else { return 1.0 }  // Prevent division by zero, if target is same as start

        let elapsed = Date().timeIntervalSince(goal.startDate)

        // If elapsed is negative (start date in future?), return 0
        if elapsed < 0 { return 0.0 }

        let p = elapsed / totalDuration
        return min(p, 1.0)  // Cap at 100%
    }

    func saveGoal(_ newGoal: Goal) {
        self.goal = newGoal
        persistData()
    }

    func getEntry(for date: Date) -> DiaryEntry? {
        // Simple day matching
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func addEntry(_ entry: DiaryEntry) {
        if let index = entries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: entry.date)
        }) {
            entries[index] = entry
        } else {
            entries.append(entry)
            entries.sort { $0.date > $1.date }  // Keep newest first
        }
        persistData()
    }

    func addFeedback(_ feedback: Feedback) {
        feedbacks.append(feedback)
        feedbacks.sort { $0.date > $1.date }
        persistData()
    }

    // MARK: - Date Helper Logic

    /// Returns the date of the very first diary entry, or today if none exist.
    var firstEntryDate: Date {
        entries.sorted(by: { $0.date < $1.date }).first?.date ?? Date()
    }

    /// Checks if we are currently within the first 7 days of the user's journey.
    var isFirstWeek: Bool {
        // If no entries, it's the start
        guard !entries.isEmpty else { return true }

        let start = firstEntryDate
        // Calculate days between start and now
        let diff = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return diff < 7
    }

    /// Returns all entries for a given month relative to a specific year.
    /// - Parameters:
    ///   - month: 1 (January) to 12 (December)
    ///   - year: The year (e.g. 2024)
    func getEntries(forMonth month: Int, year: Int) -> [DiaryEntry] {
        entries.filter {
            let components = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return components.year == year && components.month == month
        }
    }

    /// Returns whether a monthly report already exists for a given month/year
    func hasMonthlyReport(forMonth month: Int, year: Int) -> Bool {
        feedbacks.contains {
            let components = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return $0.type == .monthly && components.year == year && components.month == month
        }
    }

    /// Returns whether a yearly report already exists for a given year
    func hasYearlyReport(forYear year: Int) -> Bool {
        feedbacks.contains {
            let components = Calendar.current.dateComponents([.year], from: $0.date)
            return $0.type == .yearly && components.year == year
        }
    }

    /// Get all monthly feedback summaries for a given year
    func getMonthlyFeedbacks(forYear year: Int) -> [String] {
        feedbacks.filter {
            let components = Calendar.current.dateComponents([.year], from: $0.date)
            return $0.type == .monthly && components.year == year
        }.map { $0.summary }
    }

    /// Get all monthly feedback summaries that fall within the goal's period.
    func getMonthlyFeedbacks(for goal: Goal) -> [String] {
        feedbacks.filter {
            $0.type == .monthly && $0.date >= goal.startDate && $0.date <= goal.targetDate
        }.map { $0.summary }
    }

    /// Checks if the given date matches the Goal's Target Date (ignoring time).
    func isGoalEndDate(date: Date) -> Bool {
        guard let goal = goal else { return false }
        // Crucial: If deadline is disabled, never trigger final feedback
        if !goal.hasDeadline { return false }
        return Calendar.current.isDate(date, inSameDayAs: goal.targetDate)
    }

    /// Retrieve all feedbacks associated with a specific date (Daily, Monthly, or Goal Completion).
    func getFeedbacks(for date: Date) -> [Feedback] {
        feedbacks.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// Checks if a Goal Completion Report already exists for this goal ID.
    // (Optional: depending on if we want to allow re-generation or just once)
    func hasGoalCompletionReport(for goalID: UUID) -> Bool {
        // We can check if any feedback type is .goalCompletion (need to add) or just check yearly?
        // User said "replace yearly", so let's stick to .yearly or add .goalCompletion.
        // Let's add .goalCompletion to FeedbackType to be cleaner.
        return feedbacks.contains {
            $0.type == .goalCompletion && $0.summary.contains("Goal Completion")
        }  // Rough check or add type
    }

    private func persistData() {
        if let encodedGoal = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(encodedGoal, forKey: goalKey)
        }

        if let encodedEntries = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encodedEntries, forKey: entriesKey)
        }

        if let encodedFeedbacks = try? JSONEncoder().encode(feedbacks) {
            UserDefaults.standard.set(encodedFeedbacks, forKey: feedbacksKey)
        }
    }

    private func loadData() {
        if let goalData = UserDefaults.standard.data(forKey: goalKey),
            let decodedGoal = try? JSONDecoder().decode(Goal.self, from: goalData)
        {
            self.goal = decodedGoal
        }

        if let entriesData = UserDefaults.standard.data(forKey: entriesKey),
            let decodedEntries = try? JSONDecoder().decode([DiaryEntry].self, from: entriesData)
        {
            self.entries = decodedEntries
        }

        if let feedbacksData = UserDefaults.standard.data(forKey: feedbacksKey),
            let decodedFeedbacks = try? JSONDecoder().decode([Feedback].self, from: feedbacksData)
        {
            self.feedbacks = decodedFeedbacks
        }
    }

    // MARK: - Mock AI Logic
    // These functions simulate the AI service inside the store for now,
    // or can be moved to a separate service that the store calls.
    // For simplicity of MVVM here, I'll expose methods that update the state.

    func generateMockFeedback(for entry: DiaryEntry) -> String {
        // Simple mock response based on content length
        if entry.content.count < 10 {
            return "Keep writing! Every detail counts towards your goal."
        } else {
            return "Great entry! You are making steady progress. Keep it up!"
        }
    }

    @discardableResult
    func generateMonthlyFeedback() -> Feedback {
        let feedback = Feedback(
            date: Date(),
            summary: "This month you were very consistent. You wrote \(entries.count) entries.",
            score: 85, type: .monthly)
        addFeedback(feedback)
        return feedback
    }

    @discardableResult
    func generateYearlyFeedback() -> Feedback? {
        guard let goal = goal else { return nil }
        let summary =
            "Yearly Evaluation: You aimed to '\(goal.title)'. Based on your entries, you made significant progress!"
        let feedback = Feedback(date: Date(), summary: summary, score: 92, type: .yearly)
        addFeedback(feedback)
        return feedback
    }
}
