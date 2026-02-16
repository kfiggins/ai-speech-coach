# Phase 7: Export Functionality

## Status
⚪ Pending (blocked by Phase 6)

## Objectives
- Implement transcript export using NSSavePanel
- Implement audio export using NSSavePanel
- Generate appropriate filenames
- Handle export errors gracefully
- Optional: Add "Reveal in Finder" functionality

## Tasks
- [ ] Create ExportService:
  - [ ] Export transcript to user-selected location
  - [ ] Export audio file to user-selected location
  - [ ] Generate default filenames
  - [ ] Copy files safely
  - [ ] Handle export errors
  - [ ] Optional: Reveal file in Finder
- [ ] Update SessionResultsViewModel:
  - [ ] Add export transcript action
  - [ ] Add export audio action
  - [ ] Handle export completion/errors
  - [ ] Show success/error alerts
- [ ] Update SessionResultsView:
  - [ ] Wire up export buttons to view model
  - [ ] Show export alerts
  - [ ] Disable buttons during export
  - [ ] Optional: Add "Reveal in Finder" button

## Files to Create
- `SpeechCoach/Services/ExportService.swift`
- `SpeechCoachTests/ExportServiceTests.swift`

## Tests to Write
- [ ] Test transcript export generates correct filename
- [ ] Test audio export generates correct filename
- [ ] Test file copy succeeds
- [ ] Test export handles missing source file
- [ ] Test export handles write permission errors
- [ ] Test default filename format
- [ ] Test user cancellation (returns gracefully)

## Acceptance Criteria
- ✅ Export Transcript button opens save dialog
- ✅ Transcript saves to user-selected location
- ✅ Export Audio button opens save dialog
- ✅ Audio file copies to user-selected location
- ✅ Default filenames are descriptive and unique
- ✅ Errors are handled and shown to user
- ✅ Success confirmation shown after export
- ✅ All tests pass

## Technical Details
**NSSavePanel Usage**:
```swift
let panel = NSSavePanel()
panel.allowedContentTypes = [.plainText] // or [.mpeg4Audio]
panel.nameFieldStringValue = defaultFilename
panel.message = "Choose where to save the transcript"

panel.begin { response in
    if response == .OK, let url = panel.url {
        // Copy file to url
    }
}
```

**Default Filenames**:
- Transcript: `Transcript_2026-02-15_10-30.txt`
- Audio: `Recording_2026-02-15_10-30.m4a`

Format: `Transcript_<YYYY-MM-DD>_<HH-mm>.txt`

**Export Service API**:
```swift
class ExportService {
    func exportTranscript(session: Session, completion: @escaping (Result<URL, Error>) -> Void)
    func exportAudio(session: Session, completion: @escaping (Result<URL, Error>) -> Void)
    func revealInFinder(url: URL)
}
```

## Error Handling
- Source file doesn't exist → "Recording file not found"
- Write permission denied → "Unable to save file. Check permissions."
- User cancels → Silent (no error)
- Disk full → "Not enough disk space"

## Notes
- Use FileManager.copyItem for file copying
- Validate source file exists before showing save panel
- Consider adding UTType imports for content types
- NSSavePanel runs asynchronously, handle UI updates on main thread

## Optional Enhancements (if time permits)
- [ ] Export stats as CSV
- [ ] Export combined package (transcript + audio + stats)
- [ ] Share via NSSharingServicePicker
- [ ] Reveal in Finder button

## Completion
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Code committed to git
- [ ] Ready for Phase 8
