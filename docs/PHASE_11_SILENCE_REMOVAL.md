# Phase 11: Silence Removal Service

**Status:** Not Started
**Objective:** Pre-process recorded audio to remove silent segments before uploading to OpenAI, reducing upload size, API cost, and improving transcription quality.

## New Files

### `SpeechCoach/Services/SilenceRemovalService.swift`
- `func removeSilence(from audioURL: URL, progressHandler: ((Double) -> Void)?) async throws -> URL`
- Uses `AVAudioFile` + `AVAudioPCMBuffer` in ~50ms windows
- Computes RMS amplitude per chunk, converts to dB: `20 * log10(rms)`
- Keeps chunks above threshold (default: -40 dB)
- Writes non-silent chunks to temporary m4a file
- Returns original URL if all silent or result < 1 second
- Reports progress via `progressHandler`

### Configuration
```swift
struct Configuration {
    var silenceThresholdDb: Double = -40.0
    var windowDurationMs: Double = 50.0
    var minimumOutputDuration: Double = 1.0
}
```

### Audio Format
Input/output both m4a (AAC, 44.1kHz, mono) — matching `RecordingService` format.

## Tests

### `SpeechCoachTests/SilenceRemovalServiceTests.swift`
- Programmatic audio generation (sine wave + silence patterns)
- `testRemoveSilenceFromMixedAudio` — verify output shorter than input
- `testAllSilentAudioReturnsOriginal` — returns original URL unchanged
- `testCleanAudioPassesThrough` — no silence, output similar to input
- `testProgressHandlerCalled` — verify progress callback
- `testFileNotFound` — non-existent path throws error
- `testMinimumOutputDuration` — too-short result returns original
- `testCustomThreshold` — different threshold changes behavior

## No Files Modified
Standalone service — integrated in Phase 12.

## Completion Criteria
- [ ] Silence removal works on real recorded audio
- [ ] All edge cases handled (all silent, no silence, too short)
- [ ] All tests pass
- [ ] `swift build` succeeds
