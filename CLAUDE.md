# AI Speech Coach - macOS App

## Project Overview
A macOS SwiftUI application that records speech sessions, transcribes them on-demand via OpenAI's cloud APIs, provides LLM-powered coaching analysis, and computes local analytics on speech patterns including filler words, word frequency, and other statistics.

## Core Functionality
- **Audio Recording**: Record microphone audio during sessions
- **Transcription**: On-demand cloud transcription via OpenAI (gpt-4o-transcribe)
- **Coaching**: LLM-powered speech coaching (scores, highlights, action plan, rewrite)
- **Silence Removal**: Pre-process audio to strip dead space before cloud transcription
- **Analytics**: Compute word statistics, filler word counts, most used words
- **Session Management**: Store and retrieve session history locally
- **Export**: Download transcripts and audio files
- **Settings**: API key management, model/style configuration

## Technical Stack
- **Platform**: macOS (SwiftUI)
- **Audio**: AVAudioRecorder, AVAudioFile (silence removal)
- **Transcription**: OpenAI gpt-4o-transcribe API (cloud)
- **Coaching**: OpenAI Responses API (gpt-4.1, gpt-4o, gpt-4.1-mini)
- **Networking**: URLSession (for OpenAI API calls)
- **Secrets**: macOS Keychain (API key storage)
- **Storage**: JSON-based session persistence in Application Support
- **Architecture**: Clean separation of concerns (Services + ViewModels + Views)

## Key Principles
1. **Privacy-Conscious**: Audio sent to OpenAI for transcription/coaching; API key stored in Keychain
2. **Simple MVP**: Focus on core features, defer nice-to-haves
3. **Clean Architecture**: Separate services for Recording, Transcription, Stats, Storage
4. **Test Coverage**: Write tests for each phase before moving forward
5. **Incremental Commits**: Commit working code at the end of each phase

## Project Structure
```
ai-speech-coach/
├── CLAUDE.md (this file)
├── docs/
│   ├── PHASE_1_SETUP.md
│   ├── PHASE_2_RECORDING.md
│   ├── PHASE_3_TRANSCRIPTION.md
│   ├── PHASE_4_STATS.md
│   ├── PHASE_5_PERSISTENCE.md
│   ├── PHASE_6_UI.md
│   ├── PHASE_7_EXPORT.md
│   ├── PHASE_8_POLISH.md
│   ├── PHASE_9_OPENAI_TRANSCRIPTION.md
│   ├── PHASE_10_COACHING_SERVICE.md
│   ├── PHASE_11_SILENCE_REMOVAL.md
│   ├── PHASE_12_ASYNC_TRANSCRIPTION.md
│   ├── PHASE_13_UI_UPDATES.md
│   └── PHASE_14_TESTING_POLISH.md
├── SpeechCoach/
│   ├── Services/
│   ├── Models/
│   ├── ViewModels/
│   └── Views/
└── SpeechCoachTests/
```

## Development Workflow
1. Read the current phase implementation file
2. Implement the features described
3. Write tests and ensure they pass
4. Update the phase file with completion status
5. Commit the changes
6. Move to next phase

## Permissions Required
- **Microphone**: NSMicrophoneUsageDescription
- **Network**: com.apple.security.network.client (outbound HTTP for OpenAI API)

## Data Storage
- **Sessions Directory**: `~/Library/Application Support/SpeechCoach/Sessions/`
- **Session Metadata**: `sessions.json`
- **Per-Session Files**:
  - `<sessionID>/audio.m4a`
  - `<sessionID>/transcript.txt`

## Stop Words & Filler Words
- **Filler Words**: um, uh, like, you know, i mean, sort of, kind of
- **Stop Words**: Basic English stop words (the, and, a, to, of, in, is, it, etc.)
- Stored in local JSON for easy customization

## Phase Status
✅ Phase 1: Project Setup (2026-02-15)
✅ Phase 2: Audio Recording (2026-02-15)
✅ Phase 3: Transcription (2026-02-16)
✅ Phase 4: Stats & Analytics (2026-02-16)
✅ Phase 5: Session Persistence (2026-02-16)
✅ Phase 6: Results UI (2026-02-16)
✅ Phase 7: Export (2026-02-16)
✅ Phase 8: Polish (2026-02-16)
✅ Phase 9: OpenAI Transcription Service (2026-02-17)
✅ Phase 10: Coaching Analysis Service (2026-02-17)
✅ Phase 11: Silence Removal Service (2026-02-17)
✅ Phase 12: Decouple Recording & On-Demand Processing (2026-02-17)
✅ Phase 13: UI Updates (Transcribe Button, Settings, Privacy) (2026-02-17)
✅ Phase 14: Testing & Polish (2026-02-17)

## Architecture Notes

Phases 9-14 replaced Apple Speech with OpenAI cloud APIs:
- Recording saves audio-only sessions immediately (no transcription during recording)
- Transcription and coaching are on-demand from the session results view
- `StatsService` provides instant local stats; `CoachingService` provides LLM analysis
- API key stored in macOS Keychain via `KeychainService`
- Non-secret preferences (models, style, goals) stored in UserDefaults via `AppSettings`
