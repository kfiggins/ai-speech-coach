//
//  SilenceRemovalService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation
import AVFoundation

/// Service for removing silent segments from audio files before cloud upload
class SilenceRemovalService {

    // MARK: - Configuration

    struct Configuration {
        var silenceThresholdDb: Double = -55.0
        var windowDurationMs: Double = 50.0
        var minimumOutputDuration: Double = 1.0
    }

    // MARK: - Errors

    enum SilenceRemovalError: LocalizedError, Equatable {
        case fileNotFound
        case failedToReadAudio(String)
        case failedToWriteAudio(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Audio file not found."
            case .failedToReadAudio(let detail):
                return "Failed to read audio file: \(detail)"
            case .failedToWriteAudio(let detail):
                return "Failed to write processed audio: \(detail)"
            }
        }
    }

    // MARK: - Properties

    var configuration: Configuration

    // MARK: - Initialization

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Remove silent segments from an audio file.
    /// Returns the URL to the processed file, or the original URL if the result
    /// would be too short or the audio is entirely silent.
    func removeSilence(
        from audioURL: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw SilenceRemovalError.fileNotFound
        }

        // Open source audio file
        let sourceFile: AVAudioFile
        do {
            sourceFile = try AVAudioFile(forReading: audioURL)
        } catch {
            throw SilenceRemovalError.failedToReadAudio(error.localizedDescription)
        }

        let format = sourceFile.processingFormat
        let sampleRate = format.sampleRate
        let totalFrames = AVAudioFrameCount(sourceFile.length)

        // Calculate window size in frames
        let windowFrames = AVAudioFrameCount(sampleRate * configuration.windowDurationMs / 1000.0)
        guard windowFrames > 0 else {
            return audioURL
        }

        // Analyze chunks: determine which windows are non-silent
        var nonSilentChunks: [(position: AVAudioFramePosition, length: AVAudioFrameCount)] = []
        var framesProcessed: AVAudioFrameCount = 0

        while framesProcessed < totalFrames {
            let remainingFrames = totalFrames - framesProcessed
            let chunkLength = min(windowFrames, remainingFrames)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkLength) else {
                break
            }

            do {
                try sourceFile.read(into: buffer, frameCount: chunkLength)
            } catch {
                break
            }

            let rmsDb = computeRMSdB(buffer: buffer)

            if rmsDb > configuration.silenceThresholdDb {
                nonSilentChunks.append((
                    position: AVAudioFramePosition(framesProcessed),
                    length: chunkLength
                ))
            }

            framesProcessed += chunkLength

            progressHandler?(Double(framesProcessed) / Double(totalFrames) * 0.8)
        }

        // If no non-silent chunks found, return original
        if nonSilentChunks.isEmpty {
            progressHandler?(1.0)
            return audioURL
        }

        // Check if output would be too short
        let outputFrameCount = nonSilentChunks.reduce(0) { $0 + AVAudioFramePosition($1.length) }
        let outputDuration = Double(outputFrameCount) / sampleRate
        if outputDuration < configuration.minimumOutputDuration {
            progressHandler?(1.0)
            return audioURL
        }

        // Check if we're keeping all chunks (no silence to remove)
        if nonSilentChunks.count == Int(ceil(Double(totalFrames) / Double(windowFrames))) {
            progressHandler?(1.0)
            return audioURL
        }

        // Write non-silent chunks to a temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("silence-removed-\(UUID().uuidString).m4a")

        do {
            let outputFile = try AVAudioFile(
                forWriting: tempURL,
                settings: sourceFile.fileFormat.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )

            // Re-open source for reading chunks
            let readerFile = try AVAudioFile(forReading: audioURL)

            for (index, chunk) in nonSilentChunks.enumerated() {
                readerFile.framePosition = chunk.position

                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunk.length) else {
                    continue
                }

                try readerFile.read(into: buffer, frameCount: chunk.length)
                try outputFile.write(from: buffer)

                progressHandler?(0.8 + 0.2 * Double(index + 1) / Double(nonSilentChunks.count))
            }

            progressHandler?(1.0)
            return tempURL

        } catch {
            // Clean up temp file on failure
            try? FileManager.default.removeItem(at: tempURL)
            throw SilenceRemovalError.failedToWriteAudio(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    private func computeRMSdB(buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return -Double.infinity
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return -Double.infinity
        }

        let samples = channelData[0]
        var sumOfSquares: Double = 0

        for i in 0..<frameLength {
            let sample = Double(samples[i])
            sumOfSquares += sample * sample
        }

        let rms = sqrt(sumOfSquares / Double(frameLength))

        if rms <= 0 {
            return -Double.infinity
        }

        return 20.0 * log10(rms)
    }
}
