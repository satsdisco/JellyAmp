# JellyAmp iOS TestFlight Notes — 1.1 (33)

## What to Test

This build focuses on real-device playback reliability and browsing polish for long-form/live music listening.

### Playback / Now Playing
- Lock Screen and Control Center should expose ±15s seek controls instead of next/previous.
- Restored playback should resume near the saved timestamp after app kill/reopen, especially on long tracks.
- Long live recordings should not falsely advance to the next track during stalls/buffering.
- Now Playing animation warning cleaned up.

### Library / Browsing
- Library refresh keeps cached content visible during flaky refreshes and retries failed fetches.
- Artist “By Year” browsing remembers the tapped album/year and restores scroll position after returning.
- Artist detail avoids unnecessary reloads when albums are already loaded.
- Search preserves the query/filter and restores nearby scroll position after opening an album/artist result.
- Search failures show a retry state instead of fake “no results”.
- Album and playlist detail pages avoid unnecessary refetches on return and show useful retry states on flaky loads.
- Favorites keeps existing content visible if refresh fails, with inline retry.

### Downloads / Offline
- Downloads screen shows active and failed download state even before tracks complete.
- Failed downloads can be retried.
- Album download state surfaces failures instead of hiding them.
- Download progress handles unknown file sizes safely.

## Suggested First-Pass Device QA

1. Start a long track, lock phone, verify ±15s controls.
2. Seek 10+ minutes into a track, kill app, reopen, verify resume.
3. Browse artist → By Year → old album → back, verify scroll/year restore.
4. Search deep result → album/artist → back, verify search scroll restore.
5. Download an album, interrupt network, verify failure + retry.
6. Pull refresh Library/Favorites on weak network, verify cached content remains visible.

## Known Build Notes

- Version: 1.1
- Build: 20
- Bundle ID: jellyampos.Jellywatch.JellyAmp
- Team: 55XV5874TM
- No physical iPhone was visible from this Mac mini during local CLI checks.
- Simulator build/tests pass; final TestFlight upload still needs explicit approval.
