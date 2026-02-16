//
//  SessionStore.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import Combine

/// Service responsible for persisting and loading session data
class SessionStore: ObservableObject {

    // MARK: - Published Properties

    @Published var sessions: [Session] = []

    // MARK: - Storage Paths

    private let fileManager = FileManager.default
    private let storageDirectory: URL?

    private var sessionsFileURL: URL {
        let baseDir: URL
        if let storageDirectory = storageDirectory {
            baseDir = storageDirectory
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            baseDir = appSupport.appendingPathComponent("SpeechCoach")
        }
        return baseDir.appendingPathComponent("sessions.json")
    }

    // MARK: - Errors

    enum StorageError: LocalizedError {
        case failedToCreateDirectory
        case failedToSaveSession
        case failedToLoadSessions
        case failedToDeleteSession
        case sessionNotFound

        var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory:
                return "Failed to create storage directory"
            case .failedToSaveSession:
                return "Failed to save session to storage"
            case .failedToLoadSessions:
                return "Failed to load sessions from storage"
            case .failedToDeleteSession:
                return "Failed to delete session"
            case .sessionNotFound:
                return "Session not found in storage"
            }
        }
    }

    // MARK: - Initialization

    init(storageDirectory: URL? = nil) {
        self.storageDirectory = storageDirectory

        do {
            try createStorageDirectoryIfNeeded()
            try loadSessions()
        } catch {
            print("SessionStore initialization error: \(error.localizedDescription)")
            sessions = []
        }
    }

    // MARK: - Session Management

    /// Add a new session to the store
    func addSession(_ session: Session) throws {
        sessions.append(session)
        sessions.sort { $0.createdAt > $1.createdAt } // Newest first
        try saveSessions()
    }

    /// Update an existing session
    func updateSession(_ session: Session) throws {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            throw StorageError.sessionNotFound
        }

        sessions[index] = session
        try saveSessions()
    }

    /// Delete a session and its associated files
    func deleteSession(_ session: Session) throws {
        // Remove from array
        sessions.removeAll { $0.id == session.id }

        // Delete session directory and files
        let sessionDir = SessionFileManager.sessionDirectory(for: session.id)

        if fileManager.fileExists(atPath: sessionDir.path) {
            do {
                try fileManager.removeItem(at: sessionDir)
            } catch {
                throw StorageError.failedToDeleteSession
            }
        }

        // Save updated sessions list
        try saveSessions()
    }

    /// Get all sessions sorted by date (newest first)
    func getAllSessions() -> [Session] {
        return sessions
    }

    // MARK: - Persistence

    private func createStorageDirectoryIfNeeded() throws {
        let storageDir = sessionsFileURL.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: storageDir.path) {
            do {
                try fileManager.createDirectory(
                    at: storageDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw StorageError.failedToCreateDirectory
            }
        }
    }

    private func saveSessions() throws {
        let wrapper = SessionsWrapper(sessions: sessions)

        do {
            // Atomic write: write to temp file, then move
            let tempURL = sessionsFileURL.deletingLastPathComponent()
                .appendingPathComponent("sessions.tmp")

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(wrapper)
            try data.write(to: tempURL, options: .atomic)

            // Move temp file to final location
            if fileManager.fileExists(atPath: sessionsFileURL.path) {
                try fileManager.removeItem(at: sessionsFileURL)
            }
            try fileManager.moveItem(at: tempURL, to: sessionsFileURL)

        } catch {
            throw StorageError.failedToSaveSession
        }
    }

    private func loadSessions() throws {
        // If file doesn't exist, start with empty sessions
        guard fileManager.fileExists(atPath: sessionsFileURL.path) else {
            sessions = []
            return
        }

        do {
            let data = try Data(contentsOf: sessionsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let wrapper = try decoder.decode(SessionsWrapper.self, from: data)
            sessions = wrapper.sessions.sorted { $0.createdAt > $1.createdAt }

        } catch {
            print("Failed to load sessions, starting fresh: \(error.localizedDescription)")
            // If JSON is corrupted, reset to empty
            sessions = []

            // Backup corrupted file
            let backupURL = sessionsFileURL.deletingLastPathComponent()
                .appendingPathComponent("sessions.corrupted.json")
            try? fileManager.copyItem(at: sessionsFileURL, to: backupURL)

            // Create fresh empty file
            try saveSessions()
        }
    }

    /// Reload sessions from disk (useful after external changes)
    func reloadSessions() throws {
        try loadSessions()
    }
}

// MARK: - Helper Types

private struct SessionsWrapper: Codable {
    let sessions: [Session]
}
