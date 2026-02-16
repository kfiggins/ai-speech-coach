# Phase 1: Project Setup & Basic Shell

## Status
🔴 Not Started

## Objectives
- Create macOS SwiftUI application project
- Set up basic navigation structure
- Configure permissions in Info.plist
- Create folder structure for services, models, views
- Add basic UI shell with Start/Stop button

## Tasks
- [ ] Create new macOS App project in Xcode (SwiftUI, Swift)
- [ ] Configure Info.plist with required permissions:
  - [ ] NSMicrophoneUsageDescription
  - [ ] NSSpeechRecognitionUsageDescription
- [ ] Create folder structure:
  - [ ] Services/
  - [ ] Models/
  - [ ] ViewModels/
  - [ ] Views/
  - [ ] Resources/
- [ ] Create basic navigation:
  - [ ] MainView (root screen)
  - [ ] SessionResultsView (results screen)
- [ ] Add basic MainView UI:
  - [ ] Start/Stop button
  - [ ] Status indicator (Idle/Recording/Processing/Ready)
  - [ ] Session history list placeholder
- [ ] Set up unit test target
- [ ] Configure app sandbox entitlements

## Files to Create
- `SpeechCoach/SpeechCoachApp.swift` - App entry point
- `SpeechCoach/Views/MainView.swift` - Main screen
- `SpeechCoach/Views/SessionResultsView.swift` - Results screen
- `SpeechCoach/Models/SessionStatus.swift` - Enum for app states
- `SpeechCoach/Info.plist` - App configuration

## Tests to Write
- [ ] Test app launches successfully
- [ ] Test navigation between views
- [ ] Test status state changes

## Acceptance Criteria
- ✅ App builds and runs without errors
- ✅ Main screen displays with Start/Stop button
- ✅ Status indicator shows "Idle" by default
- ✅ Permissions are properly configured
- ✅ All tests pass

## Notes
- Use minimum deployment target: macOS 13.0 (for modern SwiftUI features)
- Enable sandbox but allow microphone and user-selected file access
- Keep UI minimal for now, focus on structure

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 2
