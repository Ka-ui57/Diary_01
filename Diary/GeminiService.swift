//
//  GeminiService.swift
//  Diary
//
//  Created by User on 2025/12/16.
//

import Foundation
import GoogleGenerativeAI

class GeminiService {
    // In a production app, fetch this from a secure plist or environment variable/config.
    private let apiKey = ""
    private let model: GenerativeModel

    init() {
        self.model = GenerativeModel(name: "gemini-flash-latest", apiKey: apiKey)
    }

    /// Generates feedback for a diary entry.
    func generateFeedback(for text: String) async throws -> String {
        let prompt = """
            You are a helpful and empathetic diary assistant.
            Please read the following diary entry and provide a short, encouraging feedback message (max 3 sentences) in Japanese.
            Also, acknowledge the content intimately but maintain a supportive tone.

            Diary Entry: "\(text)"
            """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Could not generate feedback."
    }

    /// Generates a monthly summary based on multiple diary entries.
    func generateMonthlyFeedback(entries: [String]) async throws -> String {
        let joinedEntries = entries.joined(separator: "\n---\n")
        let prompt = """
            You are a helpful diary assistant.
            Here are the diary entries for the past month.
            Please analyze them and provide a distinct summary of the month (max 3-4 sentences) in Japanese.
            Highlight any recurring themes or significant events.

            Diary Entries:
            \(joinedEntries)
            """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Could not generate monthly feedback."
    }

    /// Generates a yearly review based on monthly summaries and statistics.
    func generateYearlyFeedback(monthlySummaries: [String], entryCount: Int, goalProgress: Double)
        async throws -> String
    {
        let joinedSummaries = monthlySummaries.joined(separator: "\n---\n")
        let prompt = """
            You are a wise and reflective diary assistant.
            The year has ended. Here are the summaries of every month for the user:
            \(joinedSummaries)

            Statistics:
            - Total Diary Entries Written: \(entryCount)
            - Goal Completion Rate: \(Int(goalProgress * 100))%

            Please provide a comprehensive Yearly Review in Japanese including:
            1. Evaluation of Goal Achievement.
            2. Reflection on the year (Good points & Areas for improvement).
            3. Advice for the next year.

            Keep the tone warm, encouraging, but honest.
            """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Could not generate yearly feedback."
    }

    /// Generates a final review for a specific goal period.
    func generateGoalCompletionFeedback(
        monthlySummaries: [String], goalTitle: String, goalDescription: String
    ) async throws -> String {
        let joinedSummaries = monthlySummaries.joined(separator: "\n---\n")
        let prompt = """
            You are a wise and reflective diary assistant.
            The user has reached the end of their goal period.

            Goal: "\(goalTitle)"
            Description: "\(goalDescription)"

            Here are the monthly summaries from this period:
            \(joinedSummaries)

            Please provide a comprehensive Final Goal Review in Japanese including:
            1. Evaluation of whether the goal was likely achieved based on the monthly progress.
            2. Key highlights and struggles.
            3. Final words of encouragement.

            Keep the tone warm and celebratory.
            """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Could not generate goal completion feedback."
    }
}
