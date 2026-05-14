# Diary App with AI Feedback

This is an iOS Diary Application enhanced by Google Gemini AI, designed to help you build a habit of reflection and achieve your goals.

## Core Features

### 1. Daily Diary & AI Analysis
-   **Write freely**: Simple and clean interface for daily journaling.
-   **Smart Feedback**: The app adapts its feedback frequency based on your journey:
    -   **First Week**: receive **Daily AI Feedback** to help you build the habit.
    -   **Routine**: After the first week, feedback shifts to a **Monthly Report**, summarizing your progress and themes for the month.

### 2. Goal Management
-   **Set Your Goal**: Define a specific goal and description (e.g., "Learn Swift").
-   **Flexible Deadlines**: 
    -   **Set Date Range (Optional)**: Define a Start and Target End Date.
    -   **Goal Completion Report**: If a deadline is set, the AI will generate a comprehensive **Final Review** on the Target Date, analyzing all your monthly reports to confirm if you achieved your goal.
    -   **Open-Ended**: You can turn off the deadline for a continuous journaling experience without a final review.

### 3. Integrated Reports
-   **Instant Analysis**: All feedback (Daily, Monthly, Goal Completion) is saved as a "Report".
-   **Review**: Browse your history of reports to see how your thoughts and progress have evolved over time.

## Technical Details
-   **AI Engine**: Google Gemini (gemini-flash-latest).
-   **Framework**: SwiftUI.
-   **Data**: Local persistence via UserDefaults (MVP).

## How to Use
1.  **Start**: Open the app and write your first entry.
2.  **Set Goal**: Go to the Menu -> "My Goal" to define what you want to achieve. Toggle "Set Date Range" if you want a detailed final evaluation on a specific date.
3.  **Reflect**: Check the "Reports" section to see AI insights.

---
*Built with Gemini.*
