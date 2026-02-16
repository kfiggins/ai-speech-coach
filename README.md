# AI Speech Coach

A macOS application that helps you improve your speaking skills by recording, transcribing, and analyzing your speech patterns.

## Features

- 🎙️ **Audio Recording**: Record speech sessions using your microphone
- 📝 **Automatic Transcription**: Powered by Apple Speech Recognition (on-device)
- 📊 **Speech Analytics**:
  - Word count and unique vocabulary tracking
  - Filler word detection (um, uh, like, you know, etc.)
  - Most frequently used words
  - Words per minute calculation
- 💾 **Session History**: All sessions stored locally on your Mac
- 📤 **Export**: Download transcripts and audio files
- 🔒 **Privacy First**: All processing happens locally, nothing leaves your Mac

## Tech Stack

- **Platform**: macOS 13.0+
- **Framework**: SwiftUI
- **Audio**: AVAudioRecorder
- **Speech**: SFSpeechRecognizer (Apple Speech Framework)
- **Storage**: JSON-based local storage

## Project Structure

```
ai-speech-coach/
├── CLAUDE.md                    # Project reference for AI assistant
├── README.md                    # This file
├── docs/                        # Phase-by-phase implementation guides
│   ├── PHASE_1_SETUP.md
│   ├── PHASE_2_RECORDING.md
│   ├── PHASE_3_TRANSCRIPTION.md
│   ├── PHASE_4_STATS.md
│   ├── PHASE_5_PERSISTENCE.md
│   ├── PHASE_6_UI.md
│   ├── PHASE_7_EXPORT.md
│   └── PHASE_8_POLISH.md
├── SpeechCoach/                 # Main app (to be created in Phase 1)
└── SpeechCoachTests/            # Unit tests (to be created in Phase 1)
```

## Development Workflow

This project is built in **8 phases**, each with clear objectives, tasks, and tests:

1. **Phase 1**: Project Setup & Basic Shell
2. **Phase 2**: Audio Recording Service
3. **Phase 3**: Transcription Service
4. **Phase 4**: Text Processing & Statistics
5. **Phase 5**: Session Persistence & Storage
6. **Phase 6**: Results UI & Session History
7. **Phase 7**: Export Functionality
8. **Phase 8**: Polish & Error Handling

### Working on a Phase

1. Read the phase markdown file in `docs/`
2. Follow the tasks and implement features
3. Write tests for each component
4. Ensure all tests pass
5. Update the phase file to mark tasks complete
6. Commit your changes
7. Move to the next phase

### Testing

Each phase includes specific tests to write. Run tests frequently:

```bash
# In Xcode: Cmd+U
# Or use xcodebuild
xcodebuild test -scheme SpeechCoach -destination 'platform=macOS'
```

## Getting Started

The project hasn't been created yet. To begin:

1. Read [CLAUDE.md](CLAUDE.md) for the full project overview
2. Start with [docs/PHASE_1_SETUP.md](docs/PHASE_1_SETUP.md)
3. Create the Xcode project following Phase 1 instructions

## Privacy & Permissions

The app requires:
- **Microphone Access**: To record audio
- **Speech Recognition**: To transcribe recordings

All processing happens on-device. No data is sent to external servers.

## Data Storage

Sessions are stored in:
```
~/Library/Application Support/SpeechCoach/
├── sessions.json              # Session metadata
└── Sessions/
    └── <session-id>/
        ├── audio.m4a          # Recording
        └── transcript.txt     # Transcription
```

## License

[To be determined]

## Contributing

This is currently a personal project. Contributions welcome after v1.0 release.

---

**Current Status**: 🔴 Phase 1 - Project Setup (Not Started)

See [CLAUDE.md](CLAUDE.md) for implementation details.
