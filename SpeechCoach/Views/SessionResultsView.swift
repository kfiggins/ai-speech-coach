//
//  SessionResultsView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct SessionResultsView: View {
    let session: Session
    let sessionStore: SessionStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SessionResultsViewModel

    init(session: Session, sessionStore: SessionStore = MainView.sharedSessionStore) {
        self.session = session
        self.sessionStore = sessionStore
        _viewModel = StateObject(wrappedValue: SessionResultsViewModel(session: session, sessionStore: sessionStore))
    }

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

                // Export buttons
                HStack(spacing: 12) {
                    Button(action: { viewModel.exportTranscript() }) {
                        Label("Export Transcript", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.transcriptText.isEmpty || viewModel.isExporting)

                    Button(action: { viewModel.exportAudio() }) {
                        Label("Export Audio", systemImage: "waveform")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isExporting)
                }

                // Delete button
                Button(role: .destructive, action: { viewModel.confirmDelete() }) {
                    Label("Delete Session", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
        .frame(width: 700, height: 600)
        .alert("Delete Session", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteSession()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Export Successful", isPresented: $viewModel.showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = viewModel.exportSuccessMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Stats Grid

struct StatsGridView: View {
    let stats: SessionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quick stats cards
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

            // Filler words breakdown
            if !stats.fillerWordBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filler Words Breakdown")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(stats.fillerWordBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { word, count in
                            HStack {
                                Text(word)
                                    .font(.body)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(count)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Top words list
            if !stats.topWords.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Used Words")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(Array(stats.topWords.prefix(10).enumerated()), id: \.element.word) { index, wordCount in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, alignment: .leading)

                                Text(wordCount.word)
                                    .font(.body)

                                Spacer()

                                Text("\(wordCount.count)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
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
