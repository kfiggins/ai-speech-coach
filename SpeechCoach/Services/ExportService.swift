//
//  ExportService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Service responsible for exporting session files (transcripts and audio)
class ExportService {

    // MARK: - Errors

    enum ExportError: LocalizedError {
        case sourceFileNotFound
        case exportCancelled
        case copyFailed(Error)
        case invalidDestination

        var errorDescription: String? {
            switch self {
            case .sourceFileNotFound:
                return "Source file not found"
            case .exportCancelled:
                return "Export cancelled"
            case .copyFailed(let error):
                return "Failed to export file: \(error.localizedDescription)"
            case .invalidDestination:
                return "Invalid destination URL"
            }
        }
    }

    // MARK: - Export Methods

    /// Export transcript to user-selected location
    @MainActor
    func exportTranscript(session: Session) async throws -> URL {
        // Verify source file exists
        guard FileManager.default.fileExists(atPath: session.transcriptFileURL.path) else {
            throw ExportError.sourceFileNotFound
        }

        // Generate default filename
        let defaultFilename = generateTranscriptFilename(for: session)

        // Show save panel
        guard let destinationURL = await showSavePanel(
            defaultFilename: defaultFilename,
            allowedContentTypes: [.plainText],
            message: "Choose where to save the transcript"
        ) else {
            throw ExportError.exportCancelled
        }

        // Copy file to destination
        do {
            // If file exists at destination, remove it first
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: session.transcriptFileURL, to: destinationURL)
            return destinationURL
        } catch {
            throw ExportError.copyFailed(error)
        }
    }

    /// Export audio file to user-selected location
    @MainActor
    func exportAudio(session: Session) async throws -> URL {
        // Verify source file exists
        guard FileManager.default.fileExists(atPath: session.audioFileURL.path) else {
            throw ExportError.sourceFileNotFound
        }

        // Generate default filename
        let defaultFilename = generateAudioFilename(for: session)

        // Show save panel
        guard let destinationURL = await showSavePanel(
            defaultFilename: defaultFilename,
            allowedContentTypes: [.mpeg4Audio],
            message: "Choose where to save the audio recording"
        ) else {
            throw ExportError.exportCancelled
        }

        // Copy file to destination
        do {
            // If file exists at destination, remove it first
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: session.audioFileURL, to: destinationURL)
            return destinationURL
        } catch {
            throw ExportError.copyFailed(error)
        }
    }

    /// Reveal file in Finder
    @MainActor
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Helper Methods

    /// Show save panel and return selected URL
    @MainActor
    private func showSavePanel(
        defaultFilename: String,
        allowedContentTypes: [UTType],
        message: String
    ) async -> URL? {
        await withCheckedContinuation { continuation in
            let panel = NSSavePanel()
            panel.allowedContentTypes = allowedContentTypes
            panel.nameFieldStringValue = defaultFilename
            panel.message = message
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false

            panel.begin { response in
                if response == .OK {
                    continuation.resume(returning: panel.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// Generate default transcript filename
    private func generateTranscriptFilename(for session: Session) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = formatter.string(from: session.createdAt)
        return "Transcript_\(dateString).txt"
    }

    /// Generate default audio filename
    private func generateAudioFilename(for session: Session) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = formatter.string(from: session.createdAt)
        return "Recording_\(dateString).m4a"
    }
}
