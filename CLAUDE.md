# AI Speech Coach - macOS App

## Project Overview
A macOS SwiftUI application that records speech sessions, transcribes them using Apple's Speech framework, and provides detailed analytics on speech patterns including filler words, word frequency, and other statistics.

## Core Functionality
- **Audio Recording**: Record microphone audio during sessions
- **Transcription**: Automatic transcription using Apple Speech Recognition
- **Analytics**: Compute word statistics, filler word counts, most used words
- **Session Management**: Store and retrieve session history locally
- **Export**: Download transcripts and audio files

## Technical Stack
- **Platform**: macOS (SwiftUI)
- **Audio**: AVAudioRecorder
- **Speech**: SFSpeechRecognizer (Apple Speech framework)
- **Storage**: JSON-based session persistence in Application Support
- **Architecture**: Clean separation of concerns (Services + ViewModels + Views)

## Key Principles
1. **Privacy First**: All processing happens locally on the user's Mac
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
│   └── PHASE_8_POLISH.md
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
- **Speech Recognition**: NSSpeechRecognitionUsageDescription

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

## Current Phase
✅ Phase 1: Complete (2026-02-15)
✅ Phase 2: Complete (2026-02-15)
✅ Phase 3: Complete (2026-02-16)
✅ Phase 4: Complete (2026-02-16)
✅ Phase 5: Complete (2026-02-16)
➡️ Phase 6: Results UI & Session History (see docs/PHASE_6_UI.md)
