# TestFlight Pre-Submission Test Plan

## Critical Test Scenarios

Run through ALL of these scenarios before submitting to TestFlight. Check each box as you complete it.

### Authentication & Onboarding
- [ ] Fresh install - onboarding appears
- [ ] Quick Connect flow works end-to-end
- [ ] Manual server setup works
- [ ] Invalid server URL shows proper error
- [ ] Invalid credentials show proper error
- [ ] Sign out and sign back in
- [ ] **Sign out while music is playing** (should stop playback)

### Library Browsing
- [ ] Library loads on first launch
- [ ] Artists list shows alphabetically
- [ ] Albums list shows correctly
- [ ] Empty library shows proper message
- [ ] Large library scrolls smoothly (test with 500+ items if possible)
- [ ] Search works for artists, albums, tracks
- [ ] Search with no results shows proper message
- [ ] Favorites tab works
- [ ] Adding/removing favorites works

### Playback - iPhone
- [ ] Play a single track
- [ ] Play an album from track list
- [ ] Gapless playback between tracks
- [ ] Seek/scrubbing works correctly
- [ ] Lock screen controls work (play/pause/skip)
- [ ] Track info shows on lock screen
- [ ] Background playback works (phone locked)
- [ ] Background playback works (app backgrounded)
- [ ] Play/pause from Control Center
- [ ] Skip tracks from Control Center
- [ ] AirPlay works
- [ ] **Playback continues when switching to another app**
- [ ] **No random mid-song restarts**

### Queue Management
- [ ] Queue shows current playback
- [ ] Reorder tracks in queue
- [ ] Delete tracks from queue
- [ ] Jump to track in queue
- [ ] Shuffle works
- [ ] Repeat modes work (off/all/one)
- [ ] Clear queue works

### Apple Watch App
- [ ] Watch app installs from iPhone
- [ ] Credentials sync to watch
- [ ] Watch shows "Not Signed In" if no credentials
- [ ] Artists list loads
- [ ] Artist detail shows 3 tabs (Albums/Songs/Years)
- [ ] Year filtering works
- [ ] Tapping album opens track list
- [ ] Playing from watch works
- [ ] **Watch playback works WITHOUT iPhone nearby** (cellular test)
- [ ] Watch shows Now Playing info
- [ ] Watch playback controls work

### Error Handling & Edge Cases
- [ ] **Enable Airplane Mode** → Try to load library (shows network error)
- [ ] **Enable Airplane Mode during playback** → Track continues or shows error
- [ ] **Force quit app while playing** → Relaunch shows proper state
- [ ] Try to play with no network connection
- [ ] Server becomes unreachable mid-session
- [ ] Invalid track ID (manually test if possible)
- [ ] Empty search query
- [ ] Very long album/artist names display correctly

### Performance
- [ ] App launches in < 3 seconds
- [ ] No lag when scrolling large lists
- [ ] Images load reasonably fast
- [ ] No memory warnings in Xcode
- [ ] No crashes after 30 minutes of use

### UI/UX
- [ ] All navigation flows work smoothly
- [ ] Back buttons work everywhere
- [ ] Tabs switch correctly
- [ ] Loading indicators appear during async operations
- [ ] Error messages are user-friendly (not technical)
- [ ] Colors are consistent (Cypherpunk theme)
- [ ] Text is readable everywhere
- [ ] Buttons have proper hit areas

## How to Test

### In Xcode Simulator
1. Select iPhone 15 simulator
2. Click Run (⌘R)
3. Go through each scenario above

### On Real iPhone (REQUIRED)
1. Connect your iPhone
2. Select it as destination
3. Click Run (⌘R)
4. Test everything, especially:
   - Background audio
   - Lock screen controls
   - Actual network conditions
   - AirPlay

### On Real Apple Watch (REQUIRED)
1. Ensure watch is paired and dev mode enabled
2. Build iPhone app (watch app deploys automatically)
3. Wait for watch app to install
4. Test cellular streaming by leaving iPhone behind

## Known Issues
Document any issues you find here:

- Issue 1:
- Issue 2:
- Issue 3:

## When All Tests Pass
✅ Move to next step: Create App Icon
