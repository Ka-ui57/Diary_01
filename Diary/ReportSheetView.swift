import SwiftUI

// Simple view for displaying a report in a sheet
struct ReportSheetView: View {
    @Environment(\.dismiss) var dismiss
    let report: Feedback

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(report.date, format: .dateTime.year().month().day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(report.type.rawValue.capitalized + " Report")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)

                    Divider()

                    Text(report.summary)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
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
