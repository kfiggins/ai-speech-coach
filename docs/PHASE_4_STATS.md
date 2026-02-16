# Phase 4: Text Processing & Statistics

## Status
✅ Complete (2026-02-16)

## Objectives
- Implement text tokenization and normalization
- Calculate word statistics
- Detect and count filler words
- Identify most frequently used words
- Create stop words and filler words configuration

## Tasks
- [x] Create configuration files:
  - [x] Create stop-words.json with common English stop words (115 words)
  - [x] Create filler-words.json with single & multi-word fillers
- [x] Create StatsService:
  - [x] Tokenize transcript (normalize, split into words)
  - [x] Calculate total word count
  - [x] Calculate unique word count
  - [x] Count filler words (single and multi-word)
  - [x] Find most used words (excluding stop words)
  - [x] Calculate words per minute (if duration available)
  - [x] Load configuration from JSON files
- [x] Create stats models:
  - [x] SessionStats struct (already existed from Phase 1)
  - [x] WordCount struct (word + count, already existed)
  - [x] FillerWordBreakdown integrated into SessionStats
- [x] Update Session model:
  - [x] Add stats property (already existed)
- [x] Integrate stats calculation:
  - [x] Call StatsService after transcription in RecordingViewModel
  - [x] Save stats with session

## Files to Create
- `SpeechCoach/Services/StatsService.swift`
- `SpeechCoach/Models/SessionStats.swift`
- `SpeechCoach/Resources/stop-words.json`
- `SpeechCoach/Resources/filler-words.json`
- `SpeechCoachTests/StatsServiceTests.swift`

## Tests to Write
- [x] Test tokenization removes punctuation correctly
- [x] Test total word count calculation
- [x] Test unique word count calculation
- [x] Test filler word detection (single word: "um", "uh", "like")
- [x] Test filler word detection (multi-word: "you know", "i mean")
- [x] Test filler word breakdown (counts per filler)
- [x] Test stop word filtering
- [x] Test most used words ranking
- [x] Test most used words sorted by frequency
- [x] Test top words limit (max 10)
- [x] Test words per minute calculation
- [x] Test WPM with no duration (nil)
- [x] Test WPM with zero duration (nil)
- [x] Test empty transcript handling
- [x] Test edge cases (only stop words, only fillers, numbers)
- [x] Test tokenization normalizes case
- [x] Test tokenization handles apostrophes
- [x] Test long realistic transcript

All 21 StatsService tests passing!

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
- [x] Implementation complete
- [x] Tests written and passing (54/54 tests)
- [x] Code committed to git
- [x] Ready for Phase 5

## Implementation Notes
- **StatsService**: Comprehensive text analysis engine
  - Smart tokenization preserving contractions and hyphens
  - Case normalization for consistent analysis
  - Regex-based multi-word filler detection
  - Stop word filtering for meaningful word ranking
  - Words per minute calculation with duration validation

- **Configuration Files**:
  - stop-words.json: 115 common English stop words
  - filler-words.json: 14 single-word + 9 multi-word fillers
  - Loaded via Bundle.module (SPM-compatible)
  - Easily customizable for future enhancements

- **Tokenization Algorithm**:
  1. Lowercase normalization
  2. Remove punctuation (preserve apostrophes & hyphens)
  3. Split on whitespace
  4. Filter empty strings
  5. Trim remaining special characters

- **Filler Word Detection**:
  - Multi-word fillers processed first (prevent double-counting)
  - Regex word boundary matching for accuracy
  - Breakdown tracks individual filler counts
  - Total count aggregates all occurrences

- **Top Words Algorithm**:
  - Filter out stop words and filler words
  - Count occurrences in filtered tokens
  - Sort by frequency (descending)
  - Return top 10

- **Words Per Minute**:
  - Only calculated if duration > 0
  - Formula: (total words / duration in minutes)
  - Returns nil for invalid/missing duration

- **RecordingViewModel Integration**:
  - Stats calculated immediately after transcription
  - Only runs when transcription succeeds
  - Stats saved to session automatically
  - No stats if transcription skipped/failed

- **Test Coverage** (54 tests, up from 33):
  - StatsService: 21 comprehensive tests
    - Basic stats (empty, simple, total/unique counts)
    - Filler detection (single, multi, breakdown)
    - Top words (filtering, sorting, limits)
    - WPM (calculation, edge cases)
    - Tokenization (punctuation, case, apostrophes)
    - Edge cases (only stop words, only fillers, numbers)
  - All previous tests still passing (33)

- **Performance**:
  - Efficient Set-based lookups for stop/filler words
  - Single-pass tokenization
  - Sorted filler list (longest first) for accurate multi-word matching
  - Scales well with transcript length

- **User Experience**:
  - Automatic analysis after each recording
  - Rich statistics without user action
  - Privacy-preserving (all local)
  - Customizable word lists via JSON
