# Phase 3: Transcription Service

## Status
⚪ Pending (blocked by Phase 2)

## Objectives
- Implement transcription using Apple Speech framework
- Request speech recognition permissions
- Transcribe audio files after recording stops
- Save transcripts to text files
- Handle transcription states and errors

## Tasks
- [ ] Update PermissionManager:
  - [ ] Request speech recognition permission
  - [ ] Check SFSpeechRecognizer authorization status
  - [ ] Handle permission denied for speech
- [ ] Create TranscriptionService:
  - [ ] Initialize SFSpeechRecognizer
  - [ ] Create SFSpeechURLRecognitionRequest
  - [ ] Transcribe audio file from URL
  - [ ] Extract transcript text from result
  - [ ] Save transcript to file
  - [ ] Handle transcription errors
- [ ] Update Session model:
  - [ ] Add transcriptText property
  - [ ] Add transcriptFileURL property
  - [ ] Add durationSeconds property
- [ ] Update RecordingViewModel:
  - [ ] Trigger transcription after recording stops
  - [ ] Show "Processing" status during transcription
  - [ ] Handle transcription completion
  - [ ] Handle transcription errors
- [ ] Update MainView:
  - [ ] Show processing spinner during transcription
  - [ ] Navigate to results after transcription completes
  - [ ] Display transcription error alerts

## Files to Create
- `SpeechCoach/Services/TranscriptionService.swift`
- `SpeechCoach/Models/TranscriptionResult.swift`
- `SpeechCoachTests/TranscriptionServiceTests.swift`

## Tests to Write
- [ ] Test speech recognition permission request
- [ ] Test transcription service initialization
- [ ] Test transcription of valid audio file
- [ ] Test transcript text extraction
- [ ] Test transcript file saving
- [ ] Test error handling for empty audio
- [ ] Test error handling for unsupported format
- [ ] Test error handling for permission denied

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
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 4
