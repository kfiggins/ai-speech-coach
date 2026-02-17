# Phase 10: Groq Whisper Provider

## Status
⬜ Not Started

## Objectives
- Implement cloud-based Speech-to-Text using Groq's Whisper-compatible API
- Proper error handling with clear user-facing messages
- URLSession-based with dependency injection for testability
- Full test coverage with mocked HTTP

## Tasks
- [ ] Create `GroqTranscriptionProvider.swift`:
  - [ ] Conform to `TranscriptionProvider` protocol
  - [ ] Read `GROQ_API_KEY` from `ProcessInfo.processInfo.environment`
  - [ ] POST to `https://api.groq.com/openai/v1/audio/transcriptions`
  - [ ] Multipart form-data: `file` (binary), `model` (string), `response_format` ("json")
  - [ ] Default model: `distil-whisper-large-v3-en`
  - [ ] Accept `URLSession` via init for testability
  - [ ] `GroqError` enum: `missingAPIKey`, `invalidAudioFile`, `httpError(statusCode, message)`, `decodingFailed`, `networkError(Error)`, `fileTooLarge`
  - [ ] 401/403 → immediate fail with clear "invalid/missing GROQ_API_KEY" message
  - [ ] 5xx → 1 retry with exponential backoff
  - [ ] File size check: reject >25MB before upload
  - [ ] Static `isAPIKeyAvailable: Bool` helper
  - [ ] Build multipart request with boundary, Content-Disposition headers, audio/mp4 content type
  - [ ] Parse `GroqResponse` (Decodable: `{ "text": "..." }`)
  - [ ] Parse `GroqErrorResponse` for error messages
- [ ] Create `GroqTranscriptionProviderTests.swift`:
  - [ ] `MockURLProtocol` to intercept URLSession requests
  - [ ] Test successful transcription (200 + valid JSON)
  - [ ] Test missing API key throws `missingAPIKey`
  - [ ] Test 401 auth error throws `httpError` immediately (no retry)
  - [ ] Test 5xx retry then success (verify 2 calls made)
  - [ ] Test empty transcript response throws `emptyTranscript`
  - [ ] Test file not found throws error
  - [ ] Test multipart request format (boundary, fields, content-type)

## Files to Create
- `SpeechCoach/Services/GroqTranscriptionProvider.swift` (new)
- `SpeechCoachTests/GroqTranscriptionProviderTests.swift` (new)

## Tests to Write
- [ ] `testSuccessfulTranscription` — mock 200, verify text returned
- [ ] `testMissingAPIKey` — empty key, verify `GroqError.missingAPIKey`
- [ ] `testAuthenticationError` — mock 401, verify immediate failure
- [ ] `testServerErrorRetry` — mock 500 then 200, verify retry works
- [ ] `testEmptyTranscriptResponse` — mock `{"text": ""}`, verify error
- [ ] `testFileNotFound` — non-existent URL, verify error
- [ ] `testFileTooLarge` — file >25MB, verify `fileTooLarge` error
- [ ] `testMultipartRequestFormat` — verify boundary, model field, auth header

## Acceptance Criteria
- [ ] Build succeeds (`swift build`)
- [ ] All new tests pass with mocked HTTP (`swift test`)
- [ ] `GroqTranscriptionProvider.isAPIKeyAvailable` works correctly
- [ ] No API keys logged or exposed
- [ ] Code committed

## Technical Details
**Groq API Endpoint**:
- URL: `POST https://api.groq.com/openai/v1/audio/transcriptions`
- Auth: `Authorization: Bearer $GROQ_API_KEY`
- Content-Type: `multipart/form-data`

**Models Available**:
- `whisper-large-v3` — general, multilingual
- `distil-whisper-large-v3-en` — English-only, faster (default)

**Response Format**:
```json
{ "text": "transcribed text here" }
```

**Max File Size**: 25 MB

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 11
