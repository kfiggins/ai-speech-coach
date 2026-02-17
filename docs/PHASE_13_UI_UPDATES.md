# Phase 13: UI Updates — Transcribe Button, Settings, Privacy Notice

## Status
⬜ Not Started

## Objectives
- Add "Transcribe" button to session results for on-demand transcription
- Show loading indicator during transcription
- Create settings view for switching between Apple (local) and Groq (cloud) providers
- Dynamic privacy notice reflecting active provider

## Tasks
- [ ] Update `SessionResultsView.swift`:
  - [ ] When transcript is empty and not transcribing: show prominent "Transcribe" button
  - [ ] When transcribing: show `ProgressView` with progress percentage
  - [ ] After transcription: transcript and stats sections populate as before
  - [ ] Pass `transcriptionService` and `statsService` to `SessionResultsViewModel`
  - [ ] Export Transcript button disabled until transcript exists (already handled)
- [ ] Create `SettingsView.swift`:
  - [ ] Radio group picker for `TranscriptionProviderType`
  - [ ] API key status: green checkmark if `GROQ_API_KEY` detected, orange warning if missing
  - [ ] Context text: cloud → "Audio will be sent to Groq's servers"
  - [ ] Context text: local → "All processing happens locally"
  - [ ] Compact layout (~350px wide)
- [ ] Update `MainView.swift`:
  - [ ] Add gear icon button in header → opens `SettingsView` as `.sheet`
  - [ ] Dynamic privacy notice at bottom:
    - Local: lock icon + "Your recordings stay private on your Mac"
    - Cloud: cloud icon + "Audio is sent to Groq for transcription"
  - [ ] Pass `viewModel.transcriptionService` to `SettingsView`

## Files to Create/Modify
- `SpeechCoach/Views/SessionResultsView.swift` (modify)
- `SpeechCoach/Views/SettingsView.swift` (new)
- `SpeechCoach/Views/MainView.swift` (modify)

## Tests to Write
- [ ] Test `SettingsView` provider switching updates `TranscriptionService`
- [ ] Test privacy notice changes based on active provider
- [ ] Existing UI-related tests still pass

## Acceptance Criteria
- [ ] Build succeeds (`swift build`)
- [ ] Settings gear opens, can toggle between providers
- [ ] Privacy notice updates dynamically when switching providers
- [ ] Groq option shows API key status (detected/missing)
- [ ] "Transcribe" button appears on sessions without transcripts
- [ ] Loading indicator shows during transcription with progress
- [ ] After transcription, transcript + stats display correctly
- [ ] All tests pass (`swift test`)
- [ ] Code committed

## UI Mockups

**Session Results — No Transcript**:
```
┌─────────────────────────────────┐
│ Transcript                      │
│ ┌─────────────────────────────┐ │
│ │  No transcript yet.         │ │
│ │                             │ │
│ │  [🎙 Transcribe Session]    │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Session Results — Transcribing**:
```
┌─────────────────────────────────┐
│ Transcript                      │
│ ┌─────────────────────────────┐ │
│ │  ⏳ Transcribing... 45%     │ │
│ │  ████████░░░░░░░░░░         │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Settings View**:
```
┌───────────────────────────────┐
│ Transcription Provider        │
│                               │
│ ○ Apple Speech (Local)        │
│ ● Groq Whisper (Cloud)        │
│                               │
│ ✅ API key detected           │
│                               │
│ ℹ️ Audio will be sent to      │
│   Groq's servers              │
└───────────────────────────────┘
```

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 14
