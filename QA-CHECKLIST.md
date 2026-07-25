# JellyAmp iOS QA Checklist

## Build Under Test

Use JellyAmp `1.1 (33)` from the current local `main` after the playback/library polish pass.

## Must-pass Manual QA

### 1. Lock Screen / Control Center
- Start a long live track.
- Lock the phone.
- Confirm lock screen shows ±15s seek buttons, not next/previous track buttons.
- Tap +15s several times.
- Tap -15s several times.
- Confirm artwork/title/time stay in sync.
- Confirm playback does not restart from 0:00.

### 2. Resume After App Kill
- Start a long track and seek at least 10 minutes in.
- Kill JellyAmp from app switcher.
- Reopen JellyAmp.
- Press play/resume.
- Confirm playback seeks back near the saved timestamp instead of starting at 0:00.
- Repeat once on Wi-Fi and once on a slow/spotty connection if possible.

### 3. Long Track / False Finish Recovery
- Play a long live recording.
- Let it run through normal playback and at least one queue transition.
- Confirm it does not jump early to the next track.
- Confirm if buffering/stall occurs, the queue does not advance by itself.

### 4. Artist Year Browsing Scroll Restore
- Open an artist with many albums.
- Switch to By Year view.
- Scroll down to an older year.
- Expand that year.
- Open an album.
- Navigate back.
- Confirm the same year is expanded and scroll position returns to the tapped album.

### 5. Library Refresh
- Open Library with cached content.
- Pull to refresh / tap sync.
- Confirm existing library content stays visible while refresh runs.
- Simulate weak network if possible.
- Confirm flaky fetches retry and do not blank a usable cached library.

### 6. Search Navigation Restore
- Search for a term with enough album/artist results to scroll.
- Scroll down and open an album or artist result.
- Navigate back to Search.
- Confirm the search term, selected filter, and nearby scroll position are preserved.
- Toggle network offline and run a new search.
- Confirm the error state has a Try Again button instead of silently showing empty results.

### 7. Downloads / Offline Failure Recovery
- Start downloading an album.
- Confirm Downloads shows an active download status card even before any track completes.
- Interrupt the network mid-download.
- Confirm failed downloads show a retry action instead of disappearing into “No Downloads”.
- Tap retry after network returns and confirm progress resumes.
- Confirm downloaded albums/tracks remain playable offline.

### 8. Playlist Detail Resilience
- Open a playlist and wait for tracks to load.
- Navigate away and back.
- Confirm it does not unnecessarily refetch/rebuild the track list.
- Simulate weak/offline network on first playlist open.
- Confirm the playlist shows a useful retry state.

### 9. Album Detail Resilience
- Open an album and wait for tracks to load.
- Navigate away and back.
- Confirm the track list is preserved and does not reload from scratch.
- Simulate weak/offline network on first album open.
- Confirm the album shows a useful retry state.

### 10. Favorites Refresh Resilience
- Open Favorites with existing favorited content.
- Pull to refresh.
- Simulate a flaky network response.
- Confirm existing favorites stay visible with an inline retry banner.
- Confirm the empty/error screen only appears when there is no cached favorite content to show.

## Nice-to-check

- Play/pause from earbuds/headphones.
- CarPlay/Bluetooth metadata if available.
- Watch companion still builds/launches.
- Offline downloaded album playback.
- Search results → album → back scroll behavior.

## Known Notes

- No physical iPhone is currently visible to `xcodebuild` from this Mac mini; only the iPhone 17 Pro simulator is available.
- `xcodebuild test` passed on simulator, with one transient UI test runner launch-denied log but final result `TEST SUCCEEDED`.
- Generic iOS build passed with only an AppIntents metadata warning because the app has no AppIntents dependency.
