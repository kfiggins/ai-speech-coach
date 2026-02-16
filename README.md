# Speech Coach

A privacy-focused macOS app that helps you improve your speaking skills by recording, transcribing, and analyzing your speech sessions.

## Features

- 🎤 **Audio Recording**: High-quality audio recording of your speech practice sessions
- 📝 **Auto-Transcription**: Automatic transcription using Apple's built-in Speech Recognition
- 📊 **Speech Analytics**: Detailed statistics including:
  - Total and unique word counts
  - Words per minute
  - Filler word detection ("um", "uh", "like", etc.)
  - Most frequently used words
- 💾 **Session Management**: Save and browse your session history
- 📤 **Export**: Export transcripts (.txt) and audio files (.m4a) to any location
- 🔒 **Privacy First**: All processing happens locally on your Mac - nothing is uploaded

## Requirements

- macOS 13.0 (Ventura) or later
- Microphone access
- Speech Recognition permission (for transcription)

## Installation

### Building from Source

1. Clone the repository:
\`\`\`bash
git clone https://github.com/kfiggins/ai-speech-coach.git
cd ai-speech-coach
\`\`\`

2. Open the project in Xcode:
\`\`\`bash
open SpeechCoach.xcodeproj
\`\`\`

3. Build and run (⌘R)

## Usage

### Recording a Session

1. Click **"Start Recording"** or press \`⌘R\`
2. Speak naturally into your microphone
3. Click **"Stop Recording"** or press \`⌘R\` again
4. Wait for transcription to complete (automatic)

### Viewing Results

- Tap any session in the **Recent Sessions** list to view:
  - Full transcript (selectable and copyable)
  - Speech statistics
  - Filler word breakdown
  - Top words analysis

### Exporting Data

From any session details view:
- **Export Transcript**: Save the transcript as a .txt file
- **Export Audio**: Save the original recording as a .m4a file
- Files are automatically revealed in Finder after export

### Managing Sessions

- **Delete**: Swipe left on any session in the list, or use the Delete button in session details
- All session data (audio, transcript, stats) is stored locally in \`~/Library/Application Support/SpeechCoach/\`

## Keyboard Shortcuts

- \`⌘R\` - Start/Stop Recording
- \`⌘Q\` - Quit App

## Privacy

Your privacy matters. Speech Coach:
- ✅ Processes all data locally on your Mac
- ✅ Uses Apple's built-in Speech Recognition (on-device when available)
- ✅ Never uploads recordings or transcripts to external servers
- ✅ Only exports data when you explicitly choose to
- ✅ Stores session data in your local Application Support directory

## Technical Details

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **AVFoundation**: Audio recording and playback
- **Speech Framework**: Apple's speech-to-text API
- **Clean Architecture**: Separation of Services, ViewModels, and Views

### File Storage

\`\`\`
~/Library/Application Support/SpeechCoach/
├── sessions.json (session metadata)
└── Sessions/
    ├── {session-id}/
    │   ├── audio.m4a
    │   └── transcript.txt
    └── ...
\`\`\`

### Data Format

Sessions are stored as JSON with the following structure:
- Session ID, creation date, duration
- Transcript text
- Statistics (word counts, filler words, WPM)
- File references for audio and transcript

## Development

### Project Structure

\`\`\`
SpeechCoach/
├── Services/           # Business logic layer
│   ├── RecordingService.swift
│   ├── TranscriptionService.swift
│   ├── StatsService.swift
│   ├── SessionStore.swift
│   └── ExportService.swift
├── ViewModels/         # Presentation logic
│   ├── RecordingViewModel.swift
│   ├── SessionListViewModel.swift
│   └── SessionResultsViewModel.swift
├── Views/              # UI layer
│   ├── MainView.swift
│   └── SessionResultsView.swift
└── Models/             # Data models
    ├── Session.swift
    └── SessionStatus.swift

SpeechCoachTests/       # Unit tests
\`\`\`

### Running Tests

\`\`\`bash
xcodebuild test -project SpeechCoach.xcodeproj -scheme SpeechCoach -destination 'platform=macOS'
\`\`\`

## Contributing

This is a personal project, but suggestions and feedback are welcome! Feel free to open an issue.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with SwiftUI and macOS native frameworks
- Filler word and stop word lists curated for speech analysis
- Inspired by the need for privacy-focused speech practice tools

## Roadmap

Potential future enhancements:
- [ ] CSV export for statistics
- [ ] Custom filler word lists
- [ ] Speaking pace visualization
- [ ] Goal setting and progress tracking
- [ ] Dark mode optimization

---

Made with ❤️ for better public speaking
