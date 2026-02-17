//
//  SilenceRemovalServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
import AVFoundation
@testable import SpeechCoach

final class SilenceRemovalServiceTests: XCTestCase {

    var service: SilenceRemovalService!

    override func setUp() async throws {
        try await super.setUp()
        service = SilenceRemovalService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Mixed Audio (Sine + Silence)

    func testRemoveSilenceFromMixedAudio() async throws {
        // 1s sine wave + 2s silence + 1s sine wave = 4s total
        let url = try createMixedAudio(
            segments: [
                .tone(duration: 1.0, frequency: 440),
                .silence(duration: 2.0),
                .tone(duration: 1.0, frequency: 440)
            ]
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let resultURL = try await service.removeSilence(from: url)
        defer { if resultURL != url { try? FileManager.default.removeItem(at: resultURL) } }

        // Result should be different URL (processing happened)
        XCTAssertNotEqual(resultURL, url)

        // Result should be shorter than original
        let originalDuration = try audioDuration(at: url)
        let resultDuration = try audioDuration(at: resultURL)
        XCTAssertLessThan(resultDuration, originalDuration)
        // Should be roughly 2s (the two 1s sine segments)
        XCTAssertGreaterThan(resultDuration, 1.5)
        XCTAssertLessThan(resultDuration, 2.5)
    }

    // MARK: - All Silent Audio

    func testAllSilentAudioReturnsOriginal() async throws {
        let url = try createMixedAudio(segments: [.silence(duration: 3.0)])
        defer { try? FileManager.default.removeItem(at: url) }

        let resultURL = try await service.removeSilence(from: url)

        // Should return original URL since everything is silent
        XCTAssertEqual(resultURL, url)
    }

    // MARK: - Clean Audio (No Silence)

    func testCleanAudioPassesThrough() async throws {
        let url = try createMixedAudio(segments: [.tone(duration: 3.0, frequency: 440)])
        defer { try? FileManager.default.removeItem(at: url) }

        let resultURL = try await service.removeSilence(from: url)

        // Should return original URL since there's no silence to remove
        XCTAssertEqual(resultURL, url)
    }

    // MARK: - Progress Handler

    func testProgressHandlerCalled() async throws {
        let url = try createMixedAudio(
            segments: [
                .tone(duration: 1.0, frequency: 440),
                .silence(duration: 1.0),
                .tone(duration: 1.0, frequency: 440)
            ]
        )
        defer { try? FileManager.default.removeItem(at: url) }

        var progressValues: [Double] = []
        let resultURL = try await service.removeSilence(from: url) { progress in
            progressValues.append(progress)
        }
        defer { if resultURL != url { try? FileManager.default.removeItem(at: resultURL) } }

        // Progress should have been reported
        XCTAssertFalse(progressValues.isEmpty)
        // Should start near 0 and end at 1.0
        XCTAssertGreaterThan(progressValues.first ?? 0, 0)
        XCTAssertEqual(progressValues.last, 1.0)
        // Should be monotonically increasing
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i - 1])
        }
    }

    // MARK: - File Not Found

    func testFileNotFound() async {
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/audio.m4a")

        do {
            _ = try await service.removeSilence(from: nonexistentURL)
            XCTFail("Should throw fileNotFound")
        } catch let error as SilenceRemovalService.SilenceRemovalError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Minimum Output Duration

    func testMinimumOutputDuration() async throws {
        // Very short tone (0.1s) + silence (2s) — result would be < 1s minimum
        let url = try createMixedAudio(
            segments: [
                .tone(duration: 0.1, frequency: 440),
                .silence(duration: 2.0)
            ]
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let resultURL = try await service.removeSilence(from: url)

        // Should return original because output would be too short
        XCTAssertEqual(resultURL, url)
    }

    // MARK: - Custom Threshold

    func testCustomThresholdMoreAggressive() async throws {
        // Create audio with a quiet tone (amplitude 0.01, roughly -40 dB)
        let url = try createMixedAudio(
            segments: [
                .tone(duration: 1.0, frequency: 440, amplitude: 0.01),
                .silence(duration: 1.0),
                .tone(duration: 1.0, frequency: 440, amplitude: 0.5)
            ]
        )
        defer { try? FileManager.default.removeItem(at: url) }

        // Default threshold (-40 dB) should keep the quiet tone
        let defaultResult = try await service.removeSilence(from: url)
        defer { if defaultResult != url { try? FileManager.default.removeItem(at: defaultResult) } }

        // More aggressive threshold (-20 dB) should remove the quiet tone too
        service.configuration.silenceThresholdDb = -20.0
        let aggressiveResult = try await service.removeSilence(from: url)
        defer { if aggressiveResult != url { try? FileManager.default.removeItem(at: aggressiveResult) } }

        let defaultDuration = try audioDuration(at: defaultResult)
        let aggressiveDuration = try audioDuration(at: aggressiveResult)

        // Aggressive should be shorter or equal (removes more)
        XCTAssertLessThanOrEqual(aggressiveDuration, defaultDuration)
    }

    // MARK: - Error Descriptions

    func testErrorDescriptions() {
        let errors: [SilenceRemovalService.SilenceRemovalError] = [
            .fileNotFound,
            .failedToReadAudio("test"),
            .failedToWriteAudio("test"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }

    // MARK: - Configuration Defaults

    func testConfigurationDefaults() {
        let config = SilenceRemovalService.Configuration()
        XCTAssertEqual(config.silenceThresholdDb, -55.0)
        XCTAssertEqual(config.windowDurationMs, 50.0)
        XCTAssertEqual(config.minimumOutputDuration, 1.0)
    }

    // MARK: - Helpers

    enum AudioSegment {
        case tone(duration: Double, frequency: Double, amplitude: Float = 0.5)
        case silence(duration: Double)
    }

    /// Create a WAV file with specified segments of tones and silence
    private func createMixedAudio(segments: [AudioSegment]) throws -> URL {
        let sampleRate: Double = 44100.0
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-audio-\(UUID().uuidString).wav")

        // Calculate total frames
        var totalFrames = 0
        for segment in segments {
            switch segment {
            case .tone(let duration, _, _):
                totalFrames += Int(sampleRate * duration)
            case .silence(let duration):
                totalFrames += Int(sampleRate * duration)
            }
        }

        // Create format (PCM float, mono, 44.1kHz)
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create format"])
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"])
        }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        guard let channelData = buffer.floatChannelData else {
            throw NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "No channel data"])
        }

        let samples = channelData[0]
        var offset = 0

        for segment in segments {
            switch segment {
            case .tone(let duration, let frequency, let amplitude):
                let frameCount = Int(sampleRate * duration)
                for i in 0..<frameCount {
                    let t = Double(i) / sampleRate
                    samples[offset + i] = amplitude * Float(sin(2.0 * Double.pi * frequency * t))
                }
                offset += frameCount

            case .silence(let duration):
                let frameCount = Int(sampleRate * duration)
                for i in 0..<frameCount {
                    samples[offset + i] = 0.0
                }
                offset += frameCount
            }
        }

        // Write to file
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)

        return url
    }

    /// Get the duration of an audio file
    private func audioDuration(at url: URL) throws -> Double {
        let file = try AVAudioFile(forReading: url)
        return Double(file.length) / file.fileFormat.sampleRate
    }
}
