# Phase 5: Session Persistence & Storage

## Status
⚪ Pending (blocked by Phase 4)

## Objectives
- Implement session storage using JSON
- Save and load session metadata
- Provide session history access
- Handle session deletion with file cleanup
- Manage Application Support directory

## Tasks
- [ ] Create SessionStore service:
  - [ ] Initialize Application Support directory
  - [ ] Load sessions from sessions.json
  - [ ] Save sessions to sessions.json
  - [ ] Add new session to store
  - [ ] Update existing session
  - [ ] Delete session (remove from store + delete files)
  - [ ] Get all sessions (sorted by date)
- [ ] Create file management utilities:
  - [ ] Create session directory
  - [ ] Delete session directory and contents
  - [ ] Check if session files exist
- [ ] Update Session model:
  - [ ] Make Codable for JSON serialization
  - [ ] Add all required properties (id, createdAt, URLs, stats, etc.)
- [ ] Integrate with RecordingViewModel:
  - [ ] Create session on recording start
  - [ ] Update session after transcription
  - [ ] Update session after stats calculation
  - [ ] Save to SessionStore
- [ ] Create SessionListViewModel:
  - [ ] Load sessions from store
  - [ ] Provide sorted session list
  - [ ] Handle session selection
  - [ ] Handle session deletion

## Files to Create
- `SpeechCoach/Services/SessionStore.swift`
- `SpeechCoach/Services/FileManager+Sessions.swift`
- `SpeechCoach/ViewModels/SessionListViewModel.swift`
- `SpeechCoachTests/SessionStoreTests.swift`
- `SpeechCoachTests/FileManagerSessionsTests.swift`

## Tests to Write
- [ ] Test sessions.json creation
- [ ] Test save session to JSON
- [ ] Test load sessions from JSON
- [ ] Test session sorting (newest first)
- [ ] Test add new session
- [ ] Test update existing session
- [ ] Test delete session removes from JSON
- [ ] Test delete session removes files
- [ ] Test handling of corrupted JSON
- [ ] Test empty sessions list
- [ ] Test Application Support directory creation

## Acceptance Criteria
- ✅ Sessions are saved to sessions.json after completion
- ✅ Sessions persist across app launches
- ✅ Session history loads correctly
- ✅ Sessions are sorted newest first
- ✅ Delete session removes all associated files
- ✅ Corrupted JSON handled gracefully (reset to empty)
- ✅ All tests pass

## Technical Details
**Storage Location**:
```
~/Library/Application Support/SpeechCoach/
├── sessions.json
└── Sessions/
    ├── <uuid-1>/
    │   ├── audio.m4a
    │   └── transcript.txt
    └── <uuid-2>/
        ├── audio.m4a
        └── transcript.txt
```

**sessions.json Structure**:
```json
{
  "sessions": [
    {
      "id": "UUID-STRING",
      "createdAt": "2026-02-15T10:30:00Z",
      "durationSeconds": 120.5,
      "transcriptText": "...",
      "stats": {
        "totalWords": 250,
        "uniqueWords": 85,
        "fillerWordCount": 12,
        "fillerWordBreakdown": { "um": 5, "uh": 7 },
        "topWords": [{"word": "think", "count": 8}],
        "wordsPerMinute": 125.0
      }
    }
  ]
}
```

**Session Model** (Codable):
```swift
struct Session: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let durationSeconds: Double
    var transcriptText: String
    var stats: SessionStats?

    var audioFileURL: URL { /* computed */ }
    var transcriptFileURL: URL { /* computed */ }
}
```

## Notes
- Use FileManager to create/delete directories
- Handle concurrent access (lock file writes if needed)
- Ensure atomic writes to sessions.json (write to temp, then move)
- Consider migration strategy if JSON schema changes

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 6
