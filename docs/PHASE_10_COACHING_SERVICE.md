# Phase 10: Coaching Analysis Service

**Status:** Not Started
**Objective:** Create a new service that sends transcripts to OpenAI's Responses API for LLM-powered speech coaching analysis.

## New Files

### `SpeechCoach/Models/CoachingResult.swift`
- `CoachingResult` — scores, metrics, highlights, actionPlan, rewrite, raw
- `CoachingScores` — clarity/confidence/conciseness/structure/persuasion (1-10) + computed overall
- `CoachingMetrics` — durationSeconds, estimatedWPM, fillerWords, repeatPhrases
- `CoachingHighlight` — type (strength/improvement), text
- `CoachingRewrite` — version, text
- All structs: `Codable + Equatable`

### `SpeechCoach/Services/CoachingService.swift`
- `ObservableObject` with `@Published isAnalyzing` / `analysisProgress`
- POSTs to `https://api.openai.com/v1/responses`
- Model options: `gpt-4.1` (default), `gpt-4o`, `gpt-4.1-mini`
- Style options: `supportive`, `direct`, `detailed`
- System prompt: "You are a supportive speech coach... Output valid JSON only."
- User prompt: transcript + optional context (goal, audience, duration)
- Requests strict JSON matching `CoachingResult` schema
- Same retry logic as transcription (1 retry on 5xx, respect 429, no retry on other 4xx)
- Parses JSON from LLM text output

## Modified Files

### `SpeechCoach/Models/Session.swift`
- Add `var coachingResult: CoachingResult?` (optional, backward-compatible)
- Add to `CodingKeys`
- Add `var hasCoaching: Bool` computed property

## Reconciling StatsService vs LLM Coaching
- **Keep both.** `StatsService` = instant, deterministic, free local stats (word count, filler words, WPM)
- `CoachingService` = subjective LLM analysis (scores, highlights, action plan, rewrite)
- Different sections in the UI

## Tests

### `SpeechCoachTests/CoachingServiceTests.swift`
- MockURLProtocol tests: success, missing key, malformed JSON, 401, 429, 5xx, prompt per style

### `SpeechCoachTests/CoachingResultTests.swift`
- Codable round-trip, partial data handling

## Completion Criteria
- [ ] `CoachingResult` model compiles with all nested structs
- [ ] `CoachingService` sends correct request format to OpenAI Responses API
- [ ] `Session.coachingResult` added without breaking existing data
- [ ] All tests pass
- [ ] `swift build` succeeds
