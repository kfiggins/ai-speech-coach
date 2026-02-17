# Phase 11: Silence Removal Service

## Status
⬜ Not Started

## Objectives
- Pre-process audio to remove dead space/silence before sending to Groq
- Saves API cost and improves transcription quality
- Important for call scenarios where user listens a lot before speaking

## Tasks
- [ ] Create `SilenceRemovalService.swift`:
  - [ ] `func removeSilence(from audioURL: URL, progressHandler: ((Double) -> Void)?) async throws -> URL`
  - [ ] Use `AVAudioFile` + `AVAudioPCMBuffer` to read audio in chunks (~50ms windows)
  - [ ] Calculate RMS amplitude per chunk
  - [ ] Keep chunks above silence threshold (configurable, default ~-40 dB)
  - [ ] Write non-silent chunks to a new temporary m4a file
  - [ ] Return URL to processed file (caller responsible for cleanup)
  - [ ] If all audio is silent or result is too short, return original URL (no-op)
  - [ ] Report progress via progressHandler
- [ ] Create `SilenceRemovalServiceTests.swift`:
  - [ ] Test with programmatically generated audio (silent + non-silent sections)
  - [ ] Test all-silent audio returns original URL
  - [ ] Test already-clean audio passes through without significant change
  - [ ] Test progress handler is called

## Files to Create
- `SpeechCoach/Services/SilenceRemovalService.swift` (new)
- `SpeechCoachTests/SilenceRemovalServiceTests.swift` (new)

## Tests to Write
- [ ] `testRemoveSilenceFromMixedAudio` — generate buffer with silent + loud sections, verify output shorter
- [ ] `testAllSilentAudioReturnsOriginal` — all-silent input returns original URL
- [ ] `testCleanAudioPassesThrough` — no silence returns file without significant change
- [ ] `testProgressHandlerCalled` — verify progress reports during processing
- [ ] `testFileNotFound` — non-existent audio URL throws error

## Acceptance Criteria
- [ ] Build succeeds (`swift build`)
- [ ] All tests pass (`swift test`)
- [ ] Processing a recording with long pauses produces a smaller output file
- [ ] Already-clean audio is not significantly altered
- [ ] Code committed

## Technical Details
**Algorithm**:
1. Read audio file with `AVAudioFile`
2. Process in ~50ms windows using `AVAudioPCMBuffer`
3. For each window, compute RMS amplitude: `sqrt(mean(samples^2))`
4. Convert to dB: `20 * log10(rms)`
5. If dB > threshold (-40 dB default), keep the chunk
6. Write kept chunks to output file using `AVAudioFile` for writing

**Configuration**:
- `silenceThresholdDb`: Double = -40.0 (configurable)
- `windowDurationMs`: Double = 50.0 (chunk size)
- `minimumOutputDuration`: Double = 1.0 (minimum output length in seconds)

**Audio Format**: Input and output both m4a (AAC, 44.1kHz, mono) — matching RecordingService format

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 12
