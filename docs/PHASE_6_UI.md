# Phase 6: Results UI & Session History

## Status
✅ Complete (2026-02-16)

## Objectives
- Build SessionResultsView with transcript and stats display
- Create reusable stats card components
- Implement session history list in MainView
- Add navigation between views
- Polish UI/UX for all screens

## Tasks
- [ ] Create SessionResultsView:
  - [ ] Display session date/time header
  - [ ] Show scrollable, selectable transcript
  - [ ] Display stats cards section
  - [ ] Add export buttons (placeholder for Phase 7)
  - [ ] Add delete session button
- [ ] Create stats card components:
  - [ ] StatCard view (reusable)
  - [ ] Total words card
  - [ ] Unique words card
  - [ ] Filler words card (with breakdown)
  - [ ] Top words card (list)
  - [ ] Words per minute card (if available)
- [ ] Update MainView:
  - [ ] Add session history list
  - [ ] Show recent sessions (newest first)
  - [ ] Tap session to navigate to results
  - [ ] Show empty state when no sessions
- [ ] Create navigation:
  - [ ] NavigationStack/NavigationLink setup
  - [ ] Pass session to results view
  - [ ] Back navigation handling
- [ ] Polish UI:
  - [ ] Consistent spacing and padding
  - [ ] Color scheme (accent colors for stats)
  - [ ] Typography hierarchy
  - [ ] Loading states
  - [ ] Empty states

## Files to Create
- `SpeechCoach/Views/SessionResultsView.swift`
- `SpeechCoach/Views/Components/StatCard.swift`
- `SpeechCoach/Views/Components/SessionListItem.swift`
- `SpeechCoach/Views/Components/EmptyStateView.swift`
- `SpeechCoach/ViewModels/SessionResultsViewModel.swift`
- `SpeechCoachTests/SessionResultsViewModelTests.swift`

## Tests to Write
- [ ] Test SessionResultsViewModel loads session correctly
- [ ] Test delete session removes from store
- [ ] Test navigation to results view
- [ ] Test session list displays correctly
- [ ] Test empty state shows when no sessions
- [ ] Test stats calculations display correctly in UI

## Acceptance Criteria
- ✅ Session results view shows transcript clearly
- ✅ Stats cards display all calculated statistics
- ✅ Filler words breakdown is visible
- ✅ Top words list is readable and sorted
- ✅ Session history list shows all sessions
- ✅ Tapping session navigates to results
- ✅ Delete session works and updates UI
- ✅ Empty state shows helpful message
- ✅ All tests pass

## Technical Details
**SessionResultsView Layout**:
```
┌─────────────────────────────┐
│ Session: Feb 15, 2026 10:30 │
├─────────────────────────────┤
│ Transcript                  │
│ ┌─────────────────────────┐ │
│ │ [Scrollable text area]  │ │
│ │                         │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Statistics                  │
│ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │Total│ │Unique│ │Filler│   │
│ │ 250 │ │  85  │ │  12  │   │
│ └─────┘ └─────┘ └─────┘    │
│ ┌───────────────────────┐  │
│ │ Top Words             │  │
│ │ 1. think (8)          │  │
│ │ 2. project (6)        │  │
│ └───────────────────────┘  │
├─────────────────────────────┤
│ [Export Transcript] [Audio] │
│ [Delete Session]            │
└─────────────────────────────┘
```

**MainView Layout**:
```
┌─────────────────────────────┐
│ Speech Coach                │
├─────────────────────────────┤
│ Status: Idle                │
│ ┌─────────────────────────┐ │
│ │   [Start Recording]     │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ Recent Sessions             │
│ ┌─────────────────────────┐ │
│ │ Feb 15, 10:30 - 250w  >│ │
│ ├─────────────────────────┤ │
│ │ Feb 14, 15:20 - 180w  >│ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## Design Notes
- Use SF Symbols for icons (mic.fill, waveform, chart.bar.fill)
- Group stats in HStack/VStack for clean layout
- Make transcript copyable (TextEditor or selectable Text)
- Use List for session history with delete swipe action
- Consider dark mode support

## Completion
- [x] Implementation complete
- [x] Tests written and passing
- [x] Code committed to git
- [x] Ready for Phase 7
