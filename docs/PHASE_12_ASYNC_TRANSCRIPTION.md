# Phase 12: Decouple Recording & On-Demand Processing

**Status:** Complete (2026-02-17)
**Objective:** Save audio immediately when recording stops. Transcription + coaching happen on-demand from session results.

## Flow Change
```
BEFORE: Record → Stop → Transcribe via OpenAI → Stats → Save → Ready
AFTER:  Record → Stop → Save audio-only session → Ready
        Later: "Transcribe" → Silence removal → OpenAI transcribe → Local stats → Save
        Later: "Get Coaching" → OpenAI coaching → Save
```

## Modified Files

### `SpeechCoach/ViewModels/RecordingViewModel.swift`
- Major simplification of `stopRecording()`:
  - Remove transcription + stats logic
  - Just save session with empty transcript and set `.ready`
- Remove `transcriptionService`, `statsService` dependencies
- Remove `observeTranscriptionService()` / `observeTranscriptionProgress()`
- Remove `transcriptionProgress` property
- Remove `.speechRecognition` from `PermissionType` enum

### `SpeechCoach/ViewModels/SessionResultsViewModel.swift`
- Change `let session` → `@Published var session`
- Add dependencies: `OpenAITranscriptionService`, `StatsService`, `SilenceRemovalService`, `CoachingService`, `AppSettings`
- Add `@Published isTranscribing`, `isAnalyzingCoaching`, `transcriptionProgress`
- Add `transcribeSession()`:
  1. Run silence removal on audio
  2. Transcribe with OpenAI
  3. Save transcript to file
  4. Compute local stats with StatsService
  5. Update session via sessionStore
- Add `analyzeCoaching()`:
  1. Validate transcript exists
  2. Call CoachingService
  3. Update session.coachingResult via sessionStore

### `SpeechCoach/Services/PermissionManager.swift`
- Remove `import Speech` and all speech recognition permission code
- Simplify `allPermissionsGranted` / `requestAllPermissions()` to microphone only

### `SpeechCoach/Models/SessionStatus.swift`
- Remove `.processing` case (transcribing/coaching state lives in view models)

## Tests

### `SpeechCoachTests/SessionResultsViewModelTests.swift`
- Update for new init signature with all dependencies
- Test `transcribeSession()` flow
- Test `analyzeCoaching()` flow
- Test error handling (session preserved)

### `SpeechCoachTests/PermissionManagerTests.swift`
- Remove speech recognition tests

### `SpeechCoachTests/Helpers/MockURLProtocol.swift`
- Extract shared mock for reuse across test files

## Completion Criteria
- [x] Recording saves immediately without transcribing
- [x] Can start new recording right after stopping (idle → recording → ready)
- [x] `transcribeSession()` works end-to-end (silence removal → transcribe → stats → save)
- [x] `analyzeCoaching()` works end-to-end (validate transcript → coaching → save)
- [x] Speech recognition permissions removed (`import Speech` gone)
- [x] `.processing` status removed (state lives in view models)
- [x] MockURLProtocol extracted to shared test helper
- [x] All 76 tests pass
- [x] `swift build` succeeds
