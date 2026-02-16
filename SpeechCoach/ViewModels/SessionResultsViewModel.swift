//
//  SessionResultsViewModel.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import SwiftUI

/// ViewModel managing session results display and actions
@MainActor
class SessionResultsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var showingDeleteConfirmation = false
    @Published var errorMessage: String?

    // MARK: - Properties

    let session: Session
    private let sessionStore: SessionStore
    var onDeleted: (() -> Void)?

    // MARK: - Initialization

    init(session: Session, sessionStore: SessionStore) {
        self.session = session
        self.sessionStore = sessionStore
    }

    // MARK: - Actions

    /// Show delete confirmation dialog
    func confirmDelete() {
        showingDeleteConfirmation = true
    }

    /// Delete the current session
    func deleteSession() {
        do {
            try sessionStore.deleteSession(session)
            print("Session deleted successfully: \(session.id)")
            onDeleted?()
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
            print("Delete session error: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    var hasStats: Bool {
        session.stats != nil
    }

    var hasTranscript: Bool {
        !session.transcriptText.isEmpty
    }

    var formattedDuration: String {
        let minutes = Int(session.durationSeconds) / 60
        let seconds = Int(session.durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
