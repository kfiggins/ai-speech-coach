# Phase 14: Testing & Polish

## Status
⬜ Not Started

## Objectives
- Ensure all tests pass after the full refactor
- Update existing tests for changed interfaces
- Handle edge cases and error scenarios
- Full end-to-end manual verification

## Tasks
- [ ] Update `TranscriptionServiceTests.swift`:
  - [ ] Test default provider is Apple
  - [ ] Test `setProvider()` persists to UserDefaults
  - [ ] Test fallback to local when Groq selected but no API key
  - [ ] Test `requiresSpeechPermission` correct per provider
  - [ ] Test `isCloudProvider` correct per provider
- [ ] Verify existing test suites:
  - [ ] `RecordingServiceTests` — should pass unchanged
  - [ ] `StatsServiceTests` — should pass unchanged
  - [ ] `SessionStoreTests` — should pass unchanged
  - [ ] `SessionResultsViewModelTests` — update for new dependencies
  - [ ] `PermissionManagerTests` — should pass unchanged
  - [ ] `ExportServiceTests` — should pass unchanged
- [ ] Edge cases:
  - [ ] Transcribe button disabled if already transcribing
  - [ ] Switching provider while transcription in progress — prevent or handle
  - [ ] Missing API key when Groq selected: helpful error on transcribe attempt
  - [ ] Network failure during Groq transcription: show error, allow retry
  - [ ] Very large audio files (>25MB): clear error before upload
  - [ ] Session with existing transcript: don't show Transcribe button (or offer re-transcribe)

## Files to Modify
- `SpeechCoachTests/TranscriptionServiceTests.swift`
- `SpeechCoachTests/SessionResultsViewModelTests.swift`
- Other test files as needed

## Tests to Write/Update
- [ ] TranscriptionService coordinator tests (provider switching, persistence, fallback)
- [ ] SessionResultsViewModel transcription flow tests
- [ ] Edge case tests (missing API key, network failure, large files)
- [ ] Integration test gated behind `RUN_INTEGRATION_TESTS=1` env var (optional)

## Acceptance Criteria
- [ ] `swift build` succeeds with no warnings
- [ ] `swift test` — ALL tests pass (existing + new)
- [ ] Manual walkthrough: record → view session → transcribe with Apple Speech → verify stats
- [ ] Manual walkthrough: set GROQ_API_KEY → switch to Groq → record → transcribe → verify
- [ ] Manual: verify silence removal works (record with pauses → transcribe → check)
- [ ] Manual: verify can record new session while previous is being transcribed
- [ ] No memory leaks or crashes
- [ ] Code committed

## Manual Testing Checklist
- [ ] Fresh launch: default provider is Apple, privacy notice shows local
- [ ] Switch to Groq without API key: warning shown in settings
- [ ] Switch to Groq with API key: checkmark shown, privacy notice updates
- [ ] Record session → stop → session appears in list immediately
- [ ] Can start new recording right after stopping
- [ ] Open session → "Transcribe" button visible
- [ ] Click Transcribe → loading indicator with progress
- [ ] After transcription: transcript + stats populate
- [ ] Export transcript works after transcription
- [ ] Delete session works
- [ ] Error: unset GROQ_API_KEY with Groq selected → transcribe → clear error message
- [ ] Error: disconnect network → transcribe with Groq → network error shown

## Completion
- [ ] All tests passing
- [ ] Manual testing complete
- [ ] Edge cases handled
- [ ] Code committed to git
- [ ] Update CLAUDE.md with new phase statuses
