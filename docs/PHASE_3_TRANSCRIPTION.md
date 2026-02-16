# Phase 3: Transcription Service

## Status
✅ Complete (2026-02-16)

## Objectives
- Implement transcription using Apple Speech framework
- Request speech recognition permissions
- Transcribe audio files after recording stops
- Save transcripts to text files
- Handle transcription states and errors

## Tasks
- [x] Update PermissionManager:
  - [x] Request speech recognition permission (already done in Phase 2)
  - [x] Check SFSpeechRecognizer authorization status
  - [x] Handle permission denied for speech
- [x] Create TranscriptionService:
  - [x] Initialize SFSpeechRecognizer
  - [x] Create SFSpeechURLRecognitionRequest
  - [x] Transcribe audio file from URL
  - [x] Extract transcript text from result
  - [x] Save transcript to file
  - [x] Handle transcription errors
  - [x] Track transcription progress
- [x] Update Session model:
  - [x] Add transcriptText property (already existed)
  - [x] Add transcriptFileURL property (already existed)
  - [x] Add durationSeconds property (already existed)
  - [x] Make Session Codable for JSON persistence
  - [x] Make SessionStats Codable
  - [x] Make WordCount Codable with proper initialization
- [x] Update RecordingViewModel:
  - [x] Trigger transcription after recording stops
  - [x] Show "Processing" status during transcription
  - [x] Handle transcription completion
  - [x] Handle transcription errors gracefully
  - [x] Request speech recognition permission
  - [x] Observe transcription progress
- [x] Update MainView:
  - [x] Show processing status during transcription
  - [x] Handle transcription errors with alerts
  - [x] Allow audio-only sessions if transcription fails

## Files to Create
- `SpeechCoach/Services/TranscriptionService.swift`
- `SpeechCoach/Models/TranscriptionResult.swift`
- `SpeechCoachTests/TranscriptionServiceTests.swift`

## Tests to Write
- [x] Test speech recognition permission check
- [x] Test transcription service initialization
- [x] Test transcript file saving
- [x] Test save empty transcript
- [x] Test error handling for nonexistent file
- [x] Test transcription error types
- [x] Test Session Codable encoding/decoding
- [x] Test SessionStats Codable
- [x] Test WordCount Codable

Note: Integration tests requiring actual audio transcription are documented
but not run in automated tests to avoid speech recognition dependencies.

## Acceptance Criteria
- ✅ App requests speech recognition permission
- ✅ Audio file is transcribed after recording stops
- ✅ Transcript text is saved to file
- ✅ Processing status shows during transcription
- ✅ User sees results after transcription completes
- ✅ Errors are handled gracefully (user can still export audio)
- ✅ All tests pass

## Technical Details
**Transcript File Path**:
```
~/Library/Application Support/SpeechCoach/Sessions/<UUID>/transcript.txt
```

**Speech Recognition**:
- Use `SFSpeechRecognizer(locale: Locale(identifier: "en-US"))`
- Use `SFSpeechURLRecognitionRequest` with audio file URL
- Handle recognition task completion asynchronously

**Error Cases**:
- Permission denied → show alert, allow audio export only
- Recognition failed → show error, save empty transcript
- Audio too short → show warning, proceed with what's available

## Notes
- Speech recognition is asynchronous, use Combine or async/await
- Keep the full transcript for display, we'll process it separately in Phase 4
- Consider adding timeout for very long audio files (warn if > 5 min)

## Completion
- [x] Implementation complete
- [x] Tests written and passing (33/33 tests)
- [x] Code committed to git
- [x] Ready for Phase 4

## Implementation Notes
- **TranscriptionService**: Apple Speech framework integration
  - Uses SFSpeechRecognizer with en-US locale by default
  - SFSpeechURLRecognitionRequest for file-based transcription
  - Async/await pattern with proper error handling
  - Progress tracking (estimated during processing)
  - Saves transcript to text file atomically
  - Comprehensive error types with localized descriptions

- **Model Updates (Codable Support)**:
  - Session now conforms to Codable for JSON serialization
  - SessionStats made Codable for nested encoding
  - WordCount updated with explicit initializer and Codable
  - Custom CodingKeys in Session to exclude computed properties
  - Preparing for Phase 5 (JSON-based persistence)

- **RecordingViewModel Integration**:
  - Requests speech recognition permission after recording
  - Automatically triggers transcription post-recording
  - Graceful fallback if permission denied (audio-only mode)
  - Non-blocking transcription errors (preserves audio)
  - Observes transcription progress for UI updates
  - Error messages distinguish between fatal and non-fatal issues

- **Error Handling Strategy**:
  - Microphone permission denied → block recording, show alert
  - Speech permission denied → allow recording, skip transcription
  - Transcription fails → save audio anyway, show non-blocking error
  - File not found → clear error message
  - Empty transcript → specific error with guidance

- **Test Coverage** (33 tests passing, up from 24):
  - TranscriptionService: 6 unit tests
  - SessionCodable: 3 serialization tests
  - PermissionManager: 6 tests (from Phase 2)
  - RecordingService: 3 tests (from Phase 2)
  - Session models: 15 tests (from Phase 1)

- **User Experience**:
  - Processing status shows during transcription
  - Transcription happens automatically after recording
  - User can still use app if transcription fails
  - Audio is always saved, transcript is bonus
  - Clear permission flow for both mic and speech

- **Privacy & Performance**:
  - All transcription happens on-device
  - No data sent to external servers
  - SFSpeechRecognizer runs in background
  - Transcript saved to local file system only
