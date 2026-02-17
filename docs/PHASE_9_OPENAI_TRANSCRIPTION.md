# Phase 9: OpenAI Transcription Service

**Status:** In Progress
**Objective:** Replace Apple Speech's `SFSpeechRecognizer` with OpenAI's `gpt-4o-transcribe` API for cloud-based transcription.

## New Files

### `SpeechCoach/Services/OpenAITranscriptionService.swift`
- `ObservableObject` with `@Published isTranscribing` / `transcriptionProgress`
- POSTs multipart/form-data to `https://api.openai.com/v1/audio/transcriptions`
- Model options: `gpt-4o-transcribe` (default, best quality), `gpt-4o-mini-transcribe` (faster/cheaper)
- Auth: `Authorization: Bearer $OPENAI_API_KEY` (key from Keychain)
- Max file size: 25 MB (validated before upload)
- Retry: 1 retry on 5xx with exponential backoff, respect 429 Retry-After, no retry on other 4xx
- Error types: `missingAPIKey`, `audioFileNotFound`, `fileTooLarge`, `httpError`, `rateLimited`, `networkError`, `emptyTranscript`
- `URLSession` injectable for testing

### `SpeechCoach/Services/KeychainService.swift`
- Thin wrapper around macOS Security framework
- `save(key:value:)`, `retrieve(key:)`, `delete(key:)`, `hasOpenAIKey`
- Uses `kSecClassGenericPassword` with service name `com.speechcoach.apikeys`

### `SpeechCoach/Models/AppSettings.swift`
- `ObservableObject` singleton for non-secret preferences
- Persists to UserDefaults: `transcriptionModel`, `coachingModel`, `coachingStyle`, `speechGoal`, `targetAudience`

## Modified Files

### Deleted: `SpeechCoach/Services/TranscriptionService.swift`
- Entirely replaced by `OpenAITranscriptionService`

### `SpeechCoach/ViewModels/RecordingViewModel.swift`
- Changed `transcriptionService` type from `TranscriptionService` to `OpenAITranscriptionService`
- Removed speech recognition permission check from `stopRecording()`
- Transcription now calls OpenAI directly

### `SpeechCoach/SpeechCoach.entitlements`
- Added `com.apple.security.network.client` for outbound HTTP requests

## Tests

### `SpeechCoachTests/OpenAITranscriptionServiceTests.swift`
- Uses `MockURLProtocol` to intercept HTTP requests
- Tests: success, missing key, file not found, too large, 401, 429, 5xx retry, empty transcript, multipart format

### `SpeechCoachTests/KeychainServiceTests.swift`
- Save/retrieve/delete round-trip tests

## Completion Criteria
- [ ] `OpenAITranscriptionService` compiles and handles all error cases
- [ ] `KeychainService` can store and retrieve API keys
- [ ] `RecordingViewModel` uses new service
- [ ] Old `TranscriptionService.swift` deleted
- [ ] Network entitlement added
- [ ] All tests pass
- [ ] `swift build` succeeds with no warnings
