# Phase 2: Audio Recording Service

## Status
⚪ Pending (blocked by Phase 1)

## Objectives
- Implement audio recording service
- Request microphone permissions
- Save audio files to session directory
- Handle recording states (start/stop/error)
- Create recording indicator UI

## Tasks
- [ ] Create PermissionManager service:
  - [ ] Request microphone permission
  - [ ] Check permission status
  - [ ] Handle permission denied state
- [ ] Create RecordingService:
  - [ ] Initialize AVAudioRecorder
  - [ ] Configure audio format (.m4a AAC)
  - [ ] Generate unique session IDs
  - [ ] Create session directory structure
  - [ ] Start recording
  - [ ] Stop recording
  - [ ] Validate audio file after recording
- [ ] Create RecordingViewModel:
  - [ ] Manage recording state
  - [ ] Handle permission flow
  - [ ] Expose recording status to UI
- [ ] Update MainView:
  - [ ] Connect Start/Stop button to RecordingViewModel
  - [ ] Show recording indicator (red dot + timer)
  - [ ] Display permission request alerts
  - [ ] Handle error states

## Files to Create
- `SpeechCoach/Services/PermissionManager.swift`
- `SpeechCoach/Services/RecordingService.swift`
- `SpeechCoach/ViewModels/RecordingViewModel.swift`
- `SpeechCoach/Models/Session.swift` - Basic session model
- `SpeechCoachTests/RecordingServiceTests.swift`
- `SpeechCoachTests/PermissionManagerTests.swift`

## Tests to Write
- [ ] Test session ID generation is unique
- [ ] Test audio file path creation
- [ ] Test recording start creates file
- [ ] Test recording stop finalizes file
- [ ] Test audio file has valid duration > 0
- [ ] Test permission request flow
- [ ] Test error handling for permission denied
- [ ] Test error handling for recording failure

## Acceptance Criteria
- ✅ App requests microphone permission on first recording attempt
- ✅ Recording starts and creates audio file in correct location
- ✅ Recording indicator shows while recording
- ✅ Stop button finalizes audio file
- ✅ Audio file is valid and playable
- ✅ Session directory structure is created correctly
- ✅ All tests pass

## Technical Details
**Audio Format**:
- Container: .m4a
- Codec: AAC
- Sample Rate: 44100 Hz
- Channels: 1 (mono)

**File Path Pattern**:
```
~/Library/Application Support/SpeechCoach/Sessions/<UUID>/audio.m4a
```

**Session ID**: UUID string

## Notes
- Use AVAudioRecorder for simplicity (not AVAudioEngine for MVP)
- Handle app termination during recording gracefully
- Ensure audio session category is set correctly for recording

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 3
