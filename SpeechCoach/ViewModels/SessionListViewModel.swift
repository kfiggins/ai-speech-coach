//
//  SessionListViewModel.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import SwiftUI

/// ViewModel managing the session history list
@MainActor
class SessionListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var sessions: [Session] = []
    @Published var selectedSession: Session?
    @Published var errorMessage: String?
    @Published var isLoading = false

    // MARK: - Services

    private let sessionStore: SessionStore

    // MARK: - Initialization

    init(sessionStore: SessionStore = SessionStore()) {
        self.sessionStore = sessionStore

        // Observe store changes
        observeSessionStore()

        // Load initial sessions
        loadSessions()
    }

    // MARK: - Session Management

    /// Load sessions from store
    func loadSessions() {
        isLoading = true

        // Sessions are already loaded in the store
        sessions = sessionStore.getAllSessions()

        isLoading = false
    }

    /// Reload sessions from disk
    func reloadSessions() {
        isLoading = true

        do {
            try sessionStore.reloadSessions()
            sessions = sessionStore.getAllSessions()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to reload sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Delete a session
    func deleteSession(_ session: Session) {
        Task {
            do {
                try sessionStore.deleteSession(session)
                sessions = sessionStore.getAllSessions()

                // Clear selection if deleted session was selected
                if selectedSession?.id == session.id {
                    selectedSession = nil
                }

                errorMessage = nil
            } catch {
                errorMessage = "Failed to delete session: \(error.localizedDescription)"
            }
        }
    }

    /// Select a session
    func selectSession(_ session: Session) {
        selectedSession = session
    }

    /// Clear selection
    func clearSelection() {
        selectedSession = nil
    }

    // MARK: - Helpers

    var hasSessions: Bool {
        !sessions.isEmpty
    }

    var sessionCount: Int {
        sessions.count
    }

    // MARK: - Observation

    private func observeSessionStore() {
        // Observe changes to the session store
        Task {
            for await _ in observeStoreSessions() {
                self.sessions = self.sessionStore.getAllSessions()
            }
        }
    }

    private func observeStoreSessions() -> AsyncStream<[Session]> {
        AsyncStream { continuation in
            let cancellable = sessionStore.$sessions
                .sink { sessions in
                    continuation.yield(sessions)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
