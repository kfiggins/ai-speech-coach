# Phase 4: Text Processing & Statistics

## Status
⚪ Pending (blocked by Phase 3)

## Objectives
- Implement text tokenization and normalization
- Calculate word statistics
- Detect and count filler words
- Identify most frequently used words
- Create stop words and filler words configuration

## Tasks
- [ ] Create configuration files:
  - [ ] Create stop-words.json with common English stop words
  - [ ] Create filler-words.json with filler word list
- [ ] Create StatsService:
  - [ ] Tokenize transcript (normalize, split into words)
  - [ ] Calculate total word count
  - [ ] Calculate unique word count
  - [ ] Count filler words (single and multi-word)
  - [ ] Find most used words (excluding stop words)
  - [ ] Calculate words per minute (if duration available)
- [ ] Create stats models:
  - [ ] SessionStats struct
  - [ ] WordCount struct (word + count)
  - [ ] FillerWordBreakdown struct
- [ ] Update Session model:
  - [ ] Add stats property
- [ ] Integrate stats calculation:
  - [ ] Call StatsService after transcription
  - [ ] Save stats with session

## Files to Create
- `SpeechCoach/Services/StatsService.swift`
- `SpeechCoach/Models/SessionStats.swift`
- `SpeechCoach/Resources/stop-words.json`
- `SpeechCoach/Resources/filler-words.json`
- `SpeechCoachTests/StatsServiceTests.swift`

## Tests to Write
- [ ] Test tokenization removes punctuation correctly
- [ ] Test total word count calculation
- [ ] Test unique word count calculation
- [ ] Test filler word detection (single word: "um", "uh")
- [ ] Test filler word detection (multi-word: "you know", "i mean")
- [ ] Test stop word filtering
- [ ] Test most used words ranking
- [ ] Test empty transcript handling
- [ ] Test edge cases (single word, all stop words, etc.)

## Acceptance Criteria
- ✅ Transcript is tokenized correctly
- ✅ Total words calculated accurately
- ✅ Unique words count is correct
- ✅ Filler words detected and counted (with breakdown)
- ✅ Top 10 most used words identified (excluding stop words)
- ✅ Stats are stored with session
- ✅ All tests pass

## Technical Details
**Tokenization**:
```swift
// Normalize
let normalized = transcript.lowercased()
// Remove punctuation (keep apostrophes)
let cleaned = normalized.components(separatedBy: .punctuationCharacters)
    .joined(separator: " ")
// Split into words
let words = cleaned.components(separatedBy: .whitespaces)
    .filter { !$0.isEmpty }
```

**Stop Words** (sample):
```json
["the", "and", "a", "to", "of", "in", "is", "it", "that", "for", "on", "with", "as", "was", "at", "be", "this", "by"]
```

**Filler Words**:
```json
{
  "single": ["um", "uh", "like", "literally", "basically", "actually"],
  "multi": ["you know", "i mean", "sort of", "kind of", "i think"]
}
```

**SessionStats Model**:
```swift
struct SessionStats {
    let totalWords: Int
    let uniqueWords: Int
    let fillerWordCount: Int
    let fillerWordBreakdown: [String: Int]
    let topWords: [WordCount]
    let wordsPerMinute: Double?
}
```

## Notes
- Keep original transcript unchanged (don't modify it)
- Multi-word filler detection: scan tokens in sequence
- Make stop words and filler words easily customizable for v1.1
- Consider case where transcript is empty (all stats should be 0)

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 5
