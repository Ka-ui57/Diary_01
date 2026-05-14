//
//  GoalView.swift
//  Diary
//
//  Created by User on 2025/12/15.
//

import SwiftUI

struct GoalView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var targetDate: Date = Date()
    @State private var startDate: Date = Date()  // Added startDate state back
    @State private var hasDeadline: Bool = true  // Added hasDeadline state
    @State private var showingAlert = false

    var body: some View {
        Form {
            Section("Your Goal") {
                TextField("Goal Title (e.g., Learn Swift)", text: $title)
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Toggle("Set Date Range", isOn: $hasDeadline)

                if hasDeadline {
                    VStack(alignment: .leading) {
                        Text("Goal Period")
                            .font(.headline)
                            .padding(.vertical, 4)

                        HStack {
                            Text("Start:")
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Text("Target Date (End):")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        DatePicker(
                            "Target Date", selection: $targetDate, displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                }
            }

            Button(action: saveGoal) {
                Text("Save Goal")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .disabled(title.isEmpty || description.isEmpty)
        }
        .navigationTitle("My Goal")
        .onAppear(perform: loadGoal)
        .alert("Goal Saved!", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private func loadGoal() {
        if let goal = store.goal {
            title = goal.title
            description = goal.description
            targetDate = goal.targetDate
            startDate = goal.startDate
            hasDeadline = goal.hasDeadline
        }
    }

    private func saveGoal() {
        // Preserve existing ID if updating, else new ID
        let id = store.goal?.id ?? UUID()

        // Use the edited startDate & hasDeadline
        let newGoal = Goal(
            id: id, title: title, description: description, targetDate: targetDate,
            startDate: startDate, hasDeadline: hasDeadline)
        store.saveGoal(newGoal)
        showingAlert = true
    }
}

#Preview {
    GoalView()
        .environmentObject(DiaryStore())
}
