//
//  MainView.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import SwiftUI

struct MainView: View {
    // Shared session store for both view model and session display
    static let sharedSessionStore = SessionStore()

    @ObservedObject private var sessionStore = MainView.sharedSessionStore
    @StateObject private var viewModel = RecordingViewModel(sessionStore: MainView.sharedSessionStore)
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
                StatusIndicatorView(status: viewModel.status)

                // Recording duration (when recording)
                if viewModel.status.isRecording {
                    RecordingDurationView(duration: viewModel.formattedDuration)
                }

                // Start/Stop button
                Button(action: { viewModel.toggleRecording() }) {
                    HStack {
                        Image(systemName: viewModel.status.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                        Text(viewModel.status.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.headline)
                    }
                    .frame(width: 220, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.status.isRecording ? .red : .blue)
                .disabled(!viewModel.status.canStartRecording && !viewModel.status.isRecording)
                .keyboardShortcut("r", modifiers: .command)

                Divider()
                    .padding(.vertical)

                // Session history
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Sessions")
                        .font(.headline)

                    if sessionStore.sessions.isEmpty {
                        EmptyStateView()
                    } else {
                        SessionListView(
                            sessions: sessionStore.sessions,
                            selectedSession: $selectedSession,
                            onDelete: { session in
                                deleteSession(session)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Privacy notice
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Your recordings stay private on your Mac")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(width: 600, height: 500)
            .navigationDestination(isPresented: $showingResults) {
                if let session = selectedSession {
                    SessionResultsView(session: session, sessionStore: sessionStore)
                }
            }
        }
        .onChange(of: selectedSession) { newValue in
            showingResults = newValue != nil
        }
        .alert("Permission Required", isPresented: $viewModel.showingPermissionAlert) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                openSystemSettings()
            }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .alert("Recording Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteSession(_ session: Session) {
        do {
            try sessionStore.deleteSession(session)
            print("Session deleted from list: \(session.id)")
        } catch {
            print("Failed to delete session: \(error.localizedDescription)")
        }
    }
}

// MARK: - Recording Duration

struct RecordingDurationView: View {
    let duration: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(0.8)

            Text(duration)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Status Indicator

struct StatusIndicatorView: View {
    let status: SessionStatus

    var body: some View {
        HStack(spacing: 10) {
            if status == .processing {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
            }

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
    var onDelete: ((Session) -> Void)?

    var body: some View {
        List {
            ForEach(sessions) { session in
                SessionListItemView(session: session)
                    .onTapGesture {
                        selectedSession = session
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete?(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
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
