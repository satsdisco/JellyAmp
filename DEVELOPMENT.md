# JellyAmp iOS Development

## Current local setup

- Project: `JellyAmp.xcodeproj`
- Main scheme: `JellyAmp`
- Known working simulator here: `iPhone 17 Pro` on iOS `26.2`
- Primary app target: iOS 17+
- Watch target: watchOS 10+

## Fast health checks

```bash
# List schemes / destinations
xcodebuild -list -project JellyAmp.xcodeproj
xcodebuild -showdestinations -project JellyAmp.xcodeproj -scheme JellyAmp

# Build iOS app + watch companion
xcodebuild -project JellyAmp.xcodeproj \
  -scheme JellyAmp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  build

# Run tests
xcodebuild test -project JellyAmp.xcodeproj \
  -scheme JellyAmp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

## Before starting feature work

1. `git status --short --branch`
2. Run the build command above.
3. If touching playback, test long live tracks and queue transitions manually; `PlayerManager` has had false-finish/race-condition issues.
4. Keep backup/scratch files out of the app target. Xcode's file-synchronized groups can accidentally bundle random files if they live under target folders.

## Current cleanup/roadmap notes

High-value open issues to tackle first:

- #94 — pending seek race on slow networks
- #84 — lock screen skip/next/previous controls
- #85 — settings version/build should come from bundle metadata
- #91 — duplicate files at project root
- #89 — retry/backoff/pull-to-refresh for library errors

## App Store hygiene

- Keep app/watch/complication `MARKETING_VERSION` aligned.
- Confirm TestFlight archive warnings before each upload.
- Privacy policy is local-first/no telemetry; don't add network calls outside Jellyfin without updating privacy docs.
