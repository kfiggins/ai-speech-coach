# Phase 14: Testing & Polish

**Status:** Complete (2026-02-17)
**Objective:** Ensure comprehensive test coverage, handle edge cases, perform end-to-end verification, and clean up the codebase.

## Test Updates

### Verify existing tests pass unchanged
- `RecordingServiceTests`
- `StatsServiceTests` (fixed Bundle.main → Bundle.module for JSON resource loading)
- `SessionStoreTests`
- `ExportServiceTests`

### Update for changed interfaces
- `SessionTests.swift` — Add `CoachingResult` encoding/decoding test
- `SessionStatusTests.swift` — Update for removed `.processing` case
- `SessionResultsViewModelTests.swift` — Update for new dependencies, add transcription/coaching flow tests
- `PermissionManagerTests.swift` — Remove speech recognition tests

### Optional: gated integration test
- Requires `OPENAI_API_KEY` env var
- Full transcription + coaching flow with real API

## Edge Cases
- [x] Transcribe button disabled while transcribing
- [x] Get Coaching disabled without transcript or while analyzing
- [x] Missing API key → helpful error pointing to Settings
- [x] Network failure → error with retry option
- [x] Audio > 25MB after silence removal → clear error before upload
- [x] Session with existing transcript → allow re-transcribe
- [x] Session with existing coaching → allow re-analyze

## Cleanup
- [x] Remove all `import Speech` / `SFSpeechRecognizer` references
- [x] Remove `NSSpeechRecognitionUsageDescription` from Info.plist
- [x] Ensure `com.apple.security.network.client` entitlement exists
- [x] Update `CLAUDE.md`: phase statuses, tech stack, permissions, privacy note
- [x] Fix StatsService Bundle.main → Bundle.module for test resource loading
- [x] `swift build` with no warnings
- [x] `swift test` all 153 tests green (0 failures)

## Manual Testing Checklist
1. Fresh launch, no API key → settings banner visible
2. Enter key in Settings → saves → banner gone
3. Record → stop → session saved immediately (no transcript)
4. Can start new recording right away
5. Open session → "Transcribe" button → loading → transcript + stats appear
6. "Get Coaching" button → loading → scores, highlights, action plan appear
7. Export transcript/audio works
8. Delete session works
9. Remove API key → Transcribe → clear error
10. Disconnect network → Transcribe → network error
11. Record with long pauses → silence removal reduces file → transcription works
12. Settings: change models, coaching style → persisted on relaunch
13. Settings: API key show/hide toggle works
14. Multiple sessions: transcribe different sessions → verify isolation
15. Re-transcribe a session that already has a transcript

## Completion Criteria
- [x] All tests passing (153/153)
- [ ] Manual testing complete (requires running the app)
- [x] Edge cases handled
- [x] Codebase clean (no Apple Speech references)
- [x] CLAUDE.md updated
- [x] Code committed
