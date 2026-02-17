# Phase 14: Testing & Polish

**Status:** Not Started
**Objective:** Ensure comprehensive test coverage, handle edge cases, perform end-to-end verification, and clean up the codebase.

## Test Updates

### Verify existing tests pass unchanged
- `RecordingServiceTests`
- `StatsServiceTests`
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
- [ ] Transcribe button disabled while transcribing
- [ ] Get Coaching disabled without transcript or while analyzing
- [ ] Missing API key → helpful error pointing to Settings
- [ ] Network failure → error with retry option
- [ ] Audio > 25MB after silence removal → clear error before upload
- [ ] Session with existing transcript → allow re-transcribe
- [ ] Session with existing coaching → allow re-analyze

## Cleanup
- [ ] Remove all `import Speech` / `SFSpeechRecognizer` references
- [ ] Remove `NSSpeechRecognitionUsageDescription` from Info.plist
- [ ] Ensure `com.apple.security.network.client` entitlement exists
- [ ] Update `CLAUDE.md`: phase statuses, tech stack, permissions, privacy note
- [ ] `swift build` with no warnings
- [ ] `swift test` all green

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
- [ ] All tests passing
- [ ] Manual testing complete
- [ ] Edge cases handled
- [ ] Codebase clean (no Apple Speech references)
- [ ] CLAUDE.md updated
- [ ] Code committed
