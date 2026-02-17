# Phase 12: Decouple Transcription from Recording

## Status
⬜ Not Started

## Objectives
- Stop blocking the UI after recording stops
- Save session immediately (audio only) so user can start a new recording right away
- Move transcription to on-demand (triggered by user via "Transcribe" button)
- Transcription happens in SessionResultsViewModel with loading state

## Flow Change
```
BEFORE: Record → Stop → Transcribe (blocks UI) → Stats → Save → Ready
AFTER:  Record → Stop → Save audio → Ready (can record again)
        Later: User clicks "Transcribe" → Remove silence → Transcribe → Stats → Update session
```

## Tasks
- [ ] Simplify `RecordingViewModel.stopRecording()`:
  - [ ] Stop recording, get session with audio and duration
  - [ ] Save session immediately via `sessionStore.addSession()` (empty transcript, no stats)
  - [ ] Set status to `.ready` — user can record again
  - [ ] Remove all transcription and stats logic from this method
  - [ ] Make `transcriptionService` internal (not private) so views can access it
- [ ] Add transcription capability to `SessionResultsViewModel`:
  - [ ] Add dependencies: `transcriptionService`, `statsService`, `silenceRemovalService`
  - [ ] Add `@Published var isTranscribing = false`
  - [ ] Add `@Published var transcriptionProgress: Double = 0`
  - [ ] Make `session` a `@Published var` instead of `let` (so UI refreshes after transcription)
  - [ ] Add `func transcribeSession()`:
    1. Set `isTranscribing = true`
    2. If cloud provider: run `silenceRemovalService.removeSilence()` on audio
    3. Call `transcriptionService.transcribe(audioURL:)`
    4. Save transcript to file via `transcriptionService.saveTranscript()`
    5. Calculate stats via `statsService`
    6. Update session via `sessionStore.updateSession()`
    7. Update local `session` property so UI refreshes
    8. Set `isTranscribing = false`
  - [ ] Handle errors: show error message but keep session intact

## Files to Modify
- `SpeechCoach/ViewModels/RecordingViewModel.swift` (simplify)
- `SpeechCoach/ViewModels/SessionResultsViewModel.swift` (add transcription)

## Tests to Write
- [ ] Test `RecordingViewModel.stopRecording()` saves session without transcribing
- [ ] Test `RecordingViewModel` status is `.ready` after stop (not `.processing`)
- [ ] Test `SessionResultsViewModel.transcribeSession()` updates session with transcript
- [ ] Test `SessionResultsViewModel.transcribeSession()` calculates stats
- [ ] Test `SessionResultsViewModel.isTranscribing` state management
- [ ] Test error handling during transcription (session preserved)
- [ ] Existing tests updated for new dependencies

## Acceptance Criteria
- [ ] Build succeeds (`swift build`)
- [ ] Record → Stop → session saved immediately (no transcript yet)
- [ ] Can start new recording immediately after stopping
- [ ] No transcription happens automatically
- [ ] All tests pass (`swift test`)
- [ ] Code committed

## Technical Details
**RecordingViewModel changes** (lines to modify):
- Remove lines 87-117 (permission check + transcription + stats) from `stopRecording()`
- Replace with: save session, set status to `.ready`
- Change `private let transcriptionService` → `let transcriptionService`

**SessionResultsViewModel new init**:
```swift
init(
    session: Session,
    sessionStore: SessionStore,
    transcriptionService: TranscriptionService = TranscriptionService(),
    statsService: StatsService = StatsService(),
    silenceRemovalService: SilenceRemovalService = SilenceRemovalService(),
    exportService: ExportService = ExportService()
)
```

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 13
