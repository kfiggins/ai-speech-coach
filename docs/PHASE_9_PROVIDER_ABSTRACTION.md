# Phase 9: Transcription Provider Abstraction

## Status
⬜ Not Started

## Objectives
- Extract a protocol so both Apple and Groq transcription share a common interface
- Move Apple Speech logic into its own provider class
- Refactor TranscriptionService into a coordinator that delegates to the active provider
- No behavior changes — existing Apple transcription still works identically

## Tasks
- [ ] Create `TranscriptionProvider.swift`:
  - [ ] `TranscriptionProviderType` enum (`.appleLocal`, `.groqWhisper`) — CaseIterable, Codable, rawValue display strings
  - [ ] `TranscriptionProvider` protocol with `transcribe(audioURL:progressHandler:) async throws -> String`
- [ ] Create `AppleTranscriptionProvider.swift`:
  - [ ] Move `SFSpeechRecognizer` logic from TranscriptionService
  - [ ] Conform to `TranscriptionProvider`
  - [ ] Same `performRecognition` continuation approach
  - [ ] Call `progressHandler` instead of updating `@Published` directly
- [ ] Refactor `TranscriptionService.swift` into coordinator:
  - [ ] Keep `ObservableObject` with `@Published isTranscribing`, `transcriptionProgress`
  - [ ] Keep `TranscriptionError` enum, `saveTranscript()`, static permission methods
  - [ ] Add `@Published activeProviderType` property
  - [ ] Add `setProvider(_:)` method (persists to UserDefaults key `"transcriptionProvider"`)
  - [ ] `transcribe(audioURL:)` delegates to active provider, forwards progress to `@Published`
  - [ ] Add `requiresSpeechPermission: Bool` computed property (true only for Apple)
  - [ ] Add `isCloudProvider: Bool` computed property
  - [ ] Default to `.appleLocal`; load saved preference from UserDefaults
  - [ ] Fall back to `.appleLocal` if Groq selected but API key missing

## Files to Create/Modify
- `SpeechCoach/Services/TranscriptionProvider.swift` (new)
- `SpeechCoach/Services/AppleTranscriptionProvider.swift` (new)
- `SpeechCoach/Services/TranscriptionService.swift` (modify)

## Tests to Write
- [ ] Test default provider is `.appleLocal`
- [ ] Test `setProvider()` persists to UserDefaults
- [ ] Test `requiresSpeechPermission` returns true for Apple, false for Groq
- [ ] Test `isCloudProvider` returns false for Apple, true for Groq
- [ ] Test fallback to Apple when Groq selected but no API key
- [ ] Existing TranscriptionService tests still pass

## Acceptance Criteria
- [ ] Build succeeds (`swift build`)
- [ ] Existing behavior is identical (Apple transcription works through coordinator)
- [ ] All existing tests still pass (`swift test`)
- [ ] New provider-switching tests pass
- [ ] Code committed

## Technical Details
**Protocol Signature**:
```swift
protocol TranscriptionProvider {
    func transcribe(audioURL: URL, progressHandler: @escaping (Double) -> Void) async throws -> String
}
```

**Why keep TranscriptionService as a concrete class?**
RecordingViewModel observes `TranscriptionService.$transcriptionProgress` via Combine/AsyncStream. Protocols in Swift cannot have `@Published` properties. The coordinator pattern preserves all existing observation code with zero changes to RecordingViewModel.

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 10
