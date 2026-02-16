//
//  SessionResultsView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct SessionResultsView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Session Results")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(session.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Close") {
                        dismiss()
                    }
                }

                Divider()

                // Transcript section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transcript")
                        .font(.headline)

                    if session.transcriptText.isEmpty {
                        Text("Transcript will be available after processing...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        ScrollView {
                            Text(session.transcriptText)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 200)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }

                Divider()

                // Statistics section (placeholder for Phase 4)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)

                    if let stats = session.stats {
                        StatsGridView(stats: stats)
                    } else {
                        Text("Statistics will be calculated after transcription...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                Divider()

                // Export buttons (placeholder for Phase 7)
                HStack(spacing: 12) {
                    Button(action: { /* Export transcript - Phase 7 */ }) {
                        Label("Export Transcript", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.transcriptText.isEmpty)

                    Button(action: { /* Export audio - Phase 7 */ }) {
                        Label("Export Audio", systemImage: "waveform")
                    }
                    .buttonStyle(.bordered)
                }

                // Delete button
                Button(role: .destructive, action: { /* Delete session - Phase 5 */ }) {
                    Label("Delete Session", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
        .frame(width: 700, height: 600)
    }
}

// MARK: - Stats Grid

struct StatsGridView: View {
    let stats: SessionStats

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCardView(title: "Total Words", value: "\(stats.totalWords)", icon: "text.alignleft")
            StatCardView(title: "Unique Words", value: "\(stats.uniqueWords)", icon: "character.book.closed")
            StatCardView(title: "Filler Words", value: "\(stats.fillerWordCount)", icon: "exclamationmark.triangle")

            if let wpm = stats.wordsPerMinute {
                StatCardView(title: "Words/Min", value: String(format: "%.0f", wpm), icon: "speedometer")
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview {
    SessionResultsView(session: Session(id: "preview"))
}

#Preview("With Stats") {
    var session = Session(id: "preview")
    session.transcriptText = "This is a sample transcript with some filler words like um and uh that we can analyze."
    session.stats = SessionStats(
        totalWords: 15,
        uniqueWords: 12,
        fillerWordCount: 2,
        fillerWordBreakdown: ["um": 1, "uh": 1],
        topWords: [
            WordCount(word: "sample", count: 3),
            WordCount(word: "words", count: 2)
        ],
        wordsPerMinute: 120
    )

    return SessionResultsView(session: session)
}
