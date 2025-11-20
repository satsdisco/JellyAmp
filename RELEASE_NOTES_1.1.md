# JellyAmp Version 1.1 (Build 2) - Release Notes

## TestFlight Update - Major Stability & Feature Release

### 🎵 Playback Improvements

**Fixed Critical Gapless Playback Bug**
- Fixed issue where songs would skip to random positions when transitioning between tracks
- Implemented smart track change detection to prevent false restart recovery
- Songs now play smoothly from start to finish without interruptions
- Gapless playback queue properly managed with 3-track lookahead

**Streaming Optimizations**
- Updated to use proven HTTP transcoding parameters matching JellyJam
- Better bitrate management (128kbps default)
- Improved buffer handling for cellular streaming
- More reliable audio stream delivery

### 🎨 Design & Themes

**New Bitcoin Theme**
- Added beautiful Bitcoin-inspired theme with gold/brass accents
- Sophisticated color palette: Matte Black, Steely Gray, Gold Brass, Deep Blue
- Theme switcher in Settings with smooth animations
- All UI elements updated to use semantic theme colors

**Theme System**
- Easy theme switching from Settings
- Persistent theme selection across app launches
- Cypherpunk and Bitcoin themes available
- Smooth theme transitions with spring animations

### ⌚ Apple Watch App Polish

**Now Playing View**
- Compact, runner-optimized layout - everything fits without scrolling
- Album artwork with async loading
- Favorite button (heart) for quick access
- Larger tap targets for easy control while moving
- Optimized for glanceable use during runs

**Library View**
- Fixed navigation title overlap
- Cleaner Artists/Albums tab layout
- Better use of screen space
- Inline navigation for consistency

### 🐛 Bug Fixes

- Fixed mid-song restart issue (time jump detection now track-aware)
- Resolved text cutoff in Watch player
- Fixed Library view spacing and overlap issues
- Improved framework build configuration (JellyAmpKit)
- Better error handling for streaming failures

### 🔧 Technical Improvements

- Track change detection in time observer
- Reset time tracking on track transitions
- Only detect restarts within the same track
- Enhanced logging for debugging
- Improved audio session management

---

## What's Next

This is a major stability release focused on fixing the critical playback bugs and polishing the user experience. The app is now much more stable and ready for broader testing.

### Known Issues
- Favorite button on Watch is placeholder (backend integration pending)
- Some minor UI refinements still in progress

### Testing Focus
Please test:
- Long listening sessions with gapless playback
- Theme switching
- Watch app usability during activity
- Streaming reliability on cellular

---

**Build Date**: 2024-10-19
**Version**: 1.1 (2)
**Previous Version**: 1.0 (1)
