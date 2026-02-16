//
//  MainView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct MainView: View {
    @State private var status: SessionStatus = .idle
    @State private var sessions: [Session] = []
    @State private var selectedSession: Session?
    @State private var showingResults = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                Text("Speech Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Status indicator
                StatusIndicatorView(status: status)

                // Start/Stop button
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: status.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                        Text(status.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.headline)
                    }
                    .frame(width: 200, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(status.isRecording ? .red : .blue)
                .disabled(!status.canStartRecording && !status.isRecording)

                Divider()
                    .padding(.vertical)

                // Session history
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Sessions")
                        .font(.headline)

                    if sessions.isEmpty {
                        EmptyStateView()
                    } else {
                        SessionListView(sessions: sessions, selectedSession: $selectedSession)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .frame(width: 600, height: 500)
            .navigationDestination(isPresented: $showingResults) {
                if let session = selectedSession {
                    SessionResultsView(session: session)
                }
            }
        }
        .onChange(of: selectedSession) { newValue in
            showingResults = newValue != nil
        }
    }

    private func toggleRecording() {
        if status.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        status = .recording
        // Recording logic will be implemented in Phase 2
    }

    private func stopRecording() {
        status = .processing
        // Stop recording logic will be implemented in Phase 2

        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            status = .ready
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicatorView: View {
    let status: SessionStatus

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            Text("Status: \(status.displayText)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.1))
        .cornerRadius(20)
    }

    private var statusColor: Color {
        switch status {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .processing:
            return .orange
        case .ready:
            return .green
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No sessions yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start recording to create your first session")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Session List

struct SessionListView: View {
    let sessions: [Session]
    @Binding var selectedSession: Session?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    SessionListItemView(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}

struct SessionListItemView: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let stats = session.stats {
                    Text("\(stats.totalWords) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Previews

#Preview {
    MainView()
}
