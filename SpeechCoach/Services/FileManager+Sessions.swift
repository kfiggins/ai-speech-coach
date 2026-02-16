//
//  FileManager+Sessions.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

extension FileManager {

    /// Create session directory for a given session ID
    func createSessionDirectory(for sessionId: String) throws {
        let sessionDir = SessionFileManager.sessionDirectory(for: sessionId)

        if !fileExists(atPath: sessionDir.path) {
            try createDirectory(
                at: sessionDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    /// Delete session directory and all contents for a given session ID
    func deleteSessionDirectory(for sessionId: String) throws {
        let sessionDir = SessionFileManager.sessionDirectory(for: sessionId)

        if fileExists(atPath: sessionDir.path) {
            try removeItem(at: sessionDir)
        }
    }

    /// Check if all required session files exist
    func sessionFilesExist(for sessionId: String) -> Bool {
        let audioURL = SessionFileManager.audioFileURL(for: sessionId)
        let transcriptURL = SessionFileManager.transcriptFileURL(for: sessionId)

        return fileExists(atPath: audioURL.path) &&
               fileExists(atPath: transcriptURL.path)
    }

    /// Check if audio file exists for a session
    func audioFileExists(for sessionId: String) -> Bool {
        let audioURL = SessionFileManager.audioFileURL(for: sessionId)
        return fileExists(atPath: audioURL.path)
    }

    /// Get file size for a session's audio file
    func audioFileSize(for sessionId: String) -> Int64? {
        let audioURL = SessionFileManager.audioFileURL(for: sessionId)

        guard let attributes = try? attributesOfItem(atPath: audioURL.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }

        return size
    }
}
