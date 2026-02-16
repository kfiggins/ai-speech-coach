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
    @Published var showingExportSuccess = false
    @Published var exportSuccessMessage: String?
    @Published var isExporting = false

    // MARK: - Properties

    let session: Session
    private let sessionStore: SessionStore
    private let exportService: ExportService
    var onDeleted: (() -> Void)?

    // MARK: - Initialization

    init(session: Session, sessionStore: SessionStore, exportService: ExportService = ExportService()) {
        self.session = session
        self.sessionStore = sessionStore
        self.exportService = exportService
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

    /// Export transcript to user-selected location
    func exportTranscript() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let exportedURL = try await exportService.exportTranscript(session: session)
                exportSuccessMessage = "Transcript exported successfully"
                showingExportSuccess = true
                print("Transcript exported to: \(exportedURL.path)")

                // Optionally reveal in Finder
                exportService.revealInFinder(url: exportedURL)
            } catch ExportService.ExportError.exportCancelled {
                // User cancelled, no error to show
                print("Export cancelled by user")
            } catch {
                errorMessage = error.localizedDescription
                print("Export transcript error: \(error.localizedDescription)")
            }
        }
    }

    /// Export audio to user-selected location
    func exportAudio() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let exportedURL = try await exportService.exportAudio(session: session)
                exportSuccessMessage = "Audio exported successfully"
                showingExportSuccess = true
                print("Audio exported to: \(exportedURL.path)")

                // Optionally reveal in Finder
                exportService.revealInFinder(url: exportedURL)
            } catch ExportService.ExportError.exportCancelled {
                // User cancelled, no error to show
                print("Export cancelled by user")
            } catch {
                errorMessage = error.localizedDescription
                print("Export audio error: \(error.localizedDescription)")
            }
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
