//
//  SessionResultsViewModel.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import SwiftUI

/// ViewModel managing session results display, on-demand transcription, and coaching
@MainActor
class SessionResultsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var session: Session
    @Published var showingDeleteConfirmation = false
    @Published var errorMessage: String?
    @Published var showingExportSuccess = false
    @Published var exportSuccessMessage: String?
    @Published var isExporting = false
    @Published var isTranscribing = false
    @Published var isAnalyzingCoaching = false
    @Published var transcriptionProgress: Double = 0

    // MARK: - Properties

    private let sessionStore: SessionStore
    private let exportService: ExportService
    private let transcriptionService: OpenAITranscriptionService
    private let statsService: StatsService
    private let silenceRemovalService: SilenceRemovalService
    private let coachingService: CoachingService
    private let appSettings: AppSettings
    var onDeleted: (() -> Void)?

    // MARK: - Initialization

    init(
        session: Session,
        sessionStore: SessionStore,
        exportService: ExportService = ExportService(),
        transcriptionService: OpenAITranscriptionService = OpenAITranscriptionService(),
        statsService: StatsService = StatsService(),
        silenceRemovalService: SilenceRemovalService = SilenceRemovalService(),
        coachingService: CoachingService = CoachingService(),
        appSettings: AppSettings = AppSettings.shared
    ) {
        self.session = session
        self.sessionStore = sessionStore
        self.exportService = exportService
        self.transcriptionService = transcriptionService
        self.statsService = statsService
        self.silenceRemovalService = silenceRemovalService
        self.coachingService = coachingService
        self.appSettings = appSettings
    }

    // MARK: - On-Demand Transcription

    /// Run silence removal → transcription → stats on the session's audio
    func transcribeSession() async {
        guard !isTranscribing else { return }

        isTranscribing = true
        transcriptionProgress = 0
        errorMessage = nil

        do {
            // Step 1: Silence removal
            transcriptionProgress = 0.1
            let processedURL = try await silenceRemovalService.removeSilence(
                from: session.audioFileURL
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.transcriptionProgress = 0.1 + progress * 0.2
                }
            }

            // Step 2: Transcribe via OpenAI
            transcriptionProgress = 0.3
            transcriptionService.model = appSettings.transcriptionModel
            let transcript = try await transcriptionService.transcribe(audioURL: processedURL)

            // Clean up temp file if silence removal created one
            if processedURL != session.audioFileURL {
                try? FileManager.default.removeItem(at: processedURL)
            }

            transcriptionProgress = 0.7

            // Step 3: Save transcript to file
            try transcriptionService.saveTranscript(transcript, to: session.transcriptFileURL)

            // Step 4: Compute local stats
            let stats = statsService.calculateStats(
                transcript: transcript,
                duration: session.durationSeconds
            )

            transcriptionProgress = 0.9

            // Step 5: Update session
            session.transcriptText = transcript
            session.stats = stats
            try sessionStore.updateSession(session)

            transcriptionProgress = 1.0

        } catch {
            errorMessage = error.localizedDescription
        }

        isTranscribing = false
    }

    // MARK: - On-Demand Coaching

    /// Analyze the session transcript with LLM coaching
    func analyzeCoaching() async {
        guard !isAnalyzingCoaching else { return }
        guard hasTranscript else {
            errorMessage = "No transcript to analyze. Please transcribe the session first."
            return
        }

        isAnalyzingCoaching = true
        errorMessage = nil

        do {
            let result = try await coachingService.analyze(
                transcript: session.transcriptText,
                model: appSettings.coachingModel,
                style: appSettings.coachingStyle,
                speechGoal: appSettings.speechGoal.isEmpty ? nil : appSettings.speechGoal,
                targetAudience: appSettings.targetAudience.isEmpty ? nil : appSettings.targetAudience,
                durationSeconds: session.durationSeconds
            )

            session.coachingResult = result
            try sessionStore.updateSession(session)

        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzingCoaching = false
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

                exportService.revealInFinder(url: exportedURL)
            } catch ExportService.ExportError.exportCancelled {
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

                exportService.revealInFinder(url: exportedURL)
            } catch ExportService.ExportError.exportCancelled {
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
