//
//  HistoryView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack {
                // Calendar Interface
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Divider()

                // Entry Display
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Diary Entry
                        if let entry = store.getEntry(for: selectedDate) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(entry.date, style: .date)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text(entry.content)
                                    .font(.body)
                                    .padding(.vertical, 4)

                                if let feedback = entry.aiFeedback {
                                    Divider()
                                    HStack(alignment: .top) {
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(.purple)
                                        VStack(alignment: .leading) {
                                            Text("AI Feedback")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.purple)
                                            Text(feedback)
                                                .font(.callout)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            ContentUnavailableView(
                                "No Entry",
                                systemImage: "note.text.badge.plus",
                                description: Text("No diary entry found for this date.")
                            )
                            .padding(.top, 20)
                        }

                        // 2. Reports (Monthly / Goal / Other)
                        let reports = store.getFeedbacks(for: selectedDate)
                        if !reports.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reports from this day")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(reports) { report in
                                    // Skip daily reports here as they are shown with the entry above usually,
                                    // OR show them if they are distinct objects.
                                    // User asked for Monthly/Final specifically.
                                    // Let's show all for completeness, but distinct style.
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(report.type.rawValue.capitalized + " Report")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(
                                                report.type == .goalCompletion ? .orange : .blue)

                                        Text(report.summary)
                                            .font(.body)

                                        Text("Score: \(report.score)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(DiaryStore())
}
