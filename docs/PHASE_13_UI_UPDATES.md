# Phase 13: UI Updates — Settings, Coaching Results, Transcribe Button

**Status:** Complete (2026-02-17)
**Objective:** Add settings UI for API key and model configuration, transcribe/coaching buttons, coaching results display, and updated privacy notice.

## New Files

### `SpeechCoach/Views/SettingsView.swift`
- **API Key section:** SecureField + save to Keychain + show/hide toggle + status indicator (green check / orange warning)
- **Transcription section:** Model picker (gpt-4o-transcribe / gpt-4o-mini-transcribe)
- **Coaching section:** Model picker (gpt-4.1 / gpt-4o / gpt-4.1-mini), style picker (supportive / direct / detailed), speech goal TextField, target audience TextField
- **Privacy section:** Info text about cloud processing + Keychain storage
- Frame: ~450x500

### `SpeechCoach/Views/CoachingResultsView.swift`
- Displays `CoachingResult`:
  - Scores grid (5 cards, color-coded 1-10)
  - Highlights list (green = strength, orange = improvement)
  - Numbered action plan
  - Collapsible rewrite section

## Modified Files

### `SpeechCoach/Views/SessionResultsView.swift`
- **Transcript section:**
  - Empty + not transcribing → "Transcribe" button
  - Transcribing → ProgressView with percentage
  - After → transcript text (existing)
- **New coaching section after stats:**
  - Transcript exists + no coaching + not analyzing → "Get Coaching" button
  - Analyzing → ProgressView
  - Coaching exists → `CoachingResultsView`
- API key warning banner if no key in Keychain
- Update init to create VM with all dependencies

### `SpeechCoach/Views/MainView.swift`
- Add gear icon button in header → opens `SettingsView` as `.sheet`
- Update privacy notice: cloud icon + "Audio is sent to OpenAI for transcription"
- Show "Set up API key in Settings" if no key configured
- Remove speech recognition from permission alerts
- Update `SessionListItemView` to show "Not transcribed" instead of "Processing..." when no stats
- Bump frame to ~700x550

## Completion Criteria
- [x] Settings view opens from gear icon
- [x] API key saves to Keychain and status indicator works
- [x] Model/style preferences persist across launches
- [x] "Transcribe" button appears on sessions without transcripts
- [x] "Get Coaching" button appears after transcription
- [x] Coaching results display with scores, highlights, action plan
- [x] Privacy notice shows cloud messaging
- [x] All tests pass (except pre-existing StatsServiceTests JSON resource issue)
- [x] `swift build` succeeds
