//
//  CoachingResultsView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct CoachingResultsView: View {
    let result: CoachingResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Overall score
            HStack {
                Text("Overall Score")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", result.scores.overall))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForScore(result.scores.overall))
                Text("/ 10")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Scores grid
            ScoresGridView(scores: result.scores)

            // Highlights
            if !result.highlights.isEmpty {
                HighlightsListView(highlights: result.highlights)
            }

            // Action plan
            if !result.actionPlan.isEmpty {
                ActionPlanView(steps: result.actionPlan)
            }

            // Rewrite (collapsible)
            if let rewrite = result.rewrite {
                RewriteSectionView(rewrite: rewrite)
            }
        }
    }

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 8...: return .green
        case 6..<8: return .blue
        case 4..<6: return .orange
        default: return .red
        }
    }
}

// MARK: - Scores Grid

private struct ScoresGridView: View {
    let scores: CoachingScores

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ScoreCardView(label: "Clarity", score: scores.clarity)
            ScoreCardView(label: "Confidence", score: scores.confidence)
            ScoreCardView(label: "Conciseness", score: scores.conciseness)
            ScoreCardView(label: "Structure", score: scores.structure)
            ScoreCardView(label: "Persuasion", score: scores.persuasion)
        }
    }
}

private struct ScoreCardView: View {
    let label: String
    let score: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorForScore(score))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(colorForScore(score).opacity(0.1))
        .cornerRadius(10)
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .blue
        case 4..<6: return .orange
        default: return .red
        }
    }
}

// MARK: - Highlights

private struct HighlightsListView: View {
    let highlights: [CoachingHighlight]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Highlights")
                .font(.headline)

            ForEach(Array(highlights.enumerated()), id: \.offset) { _, highlight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: highlight.type == .strength ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(highlight.type == .strength ? .green : .orange)
                        .font(.body)

                    Text(highlight.text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background((highlight.type == .strength ? Color.green : Color.orange).opacity(0.08))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Action Plan

private struct ActionPlanView: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Action Plan")
                .font(.headline)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(width: 24, alignment: .leading)

                    Text(step)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Rewrite Section

private struct RewriteSectionView: View {
    let rewrite: CoachingRewrite
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("Suggested Rewrite")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(rewrite.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        CoachingResultsView(result: CoachingResult(
            scores: CoachingScores(clarity: 8, confidence: 7, conciseness: 6, structure: 9, persuasion: 5),
            metrics: CoachingMetrics(durationSeconds: 120, estimatedWPM: 130, fillerWords: ["um": 3], repeatPhrases: []),
            highlights: [
                CoachingHighlight(type: .strength, text: "Clear and well-organized opening"),
                CoachingHighlight(type: .improvement, text: "Consider reducing filler words")
            ],
            actionPlan: ["Practice your opening statement", "Record and review filler words", "Work on pacing"],
            rewrite: CoachingRewrite(version: "improved", text: "Here is an improved version of your speech..."),
            raw: nil
        ))
        .padding()
    }
    .frame(width: 600)
}
