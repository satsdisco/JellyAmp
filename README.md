# JellyAmp

A modern music streaming client for Jellyfin servers, built for iOS and Apple Watch.

![Platform](https://img.shields.io/badge/platform-iOS%2017.0%2B%20%7C%20watchOS%2010.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### iOS App
- 🎵 **Gapless Playback** - Seamless transitions between tracks using AVQueuePlayer
- 🔐 **Quick Connect** - Easy authentication with Jellyfin servers
- 🎨 **Cypherpunk Design** - Modern UI with iOS 26 Liquid Glass effects
- 🎧 **Background Audio** - Full lock screen controls and Control Center integration
- 📱 **AirPlay Support** - Stream to any AirPlay-enabled device
- 🔀 **Queue Management** - Drag-to-reorder, shuffle, and repeat modes
- ⭐ **Favorites** - Mark your favorite artists, albums, and tracks
- 🔍 **Search** - Find music across your entire library
- 📅 **Year Filtering** - Browse artists and albums by release year

### Apple Watch App
- ⌚ **Standalone Streaming** - Stream music directly from Jellyfin over cellular/WiFi
- 👤 **Artist-First Navigation** - Browse your library by artist with year filters
- 🎵 **Now Playing** - Full playback controls on your wrist
- 📡 **Auto-Sync** - Credentials automatically sync from your iPhone

## Technology

- **SwiftUI** - Modern declarative UI framework
- **Combine** - Reactive state management
- **AVFoundation** - High-quality audio playback with gapless support
- **Keychain** - Secure credential storage
- **WatchConnectivity** - Seamless iPhone ↔ Watch credential sync
- **MediaPlayer** - Lock screen and Control Center integration

## Requirements

- iOS 17.0+ / watchOS 10.0+
- Xcode 15.0+
- A running Jellyfin server
- Jellyfin server with Quick Connect enabled (recommended)

## Installation

### TestFlight (Recommended)
*Coming soon!* JellyAmp will be available for beta testing via TestFlight.

### Building from Source
1. Clone this repository
2. Open `JellyAmp.xcodeproj` in Xcode
3. Select your development team in the project settings
4. Build and run on your device (iPhone or Apple Watch)

```bash
git clone https://github.com/satsdisco/JellyAmp.git
cd JellyAmp
open JellyAmp.xcodeproj
```

## Usage

### First Launch
1. Open JellyAmp on your iPhone
2. Choose **Quick Connect** or **Manual Setup**
3. Enter your Jellyfin server details
4. Start streaming!

### Apple Watch
The watch app automatically syncs credentials from your iPhone. Just open JellyAmp on your watch and start browsing your library.

## Architecture

JellyAmp uses a service-oriented architecture with singleton services:

- **JellyfinService** - API client for all Jellyfin server communication
- **PlayerManager** - Audio playback engine with gapless queue management
- **KeychainService** - Secure credential storage
- **WatchConnectivityManager** - iPhone ↔ Watch communication

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

## Privacy

JellyAmp is a local-first app. Your credentials and data stay on your devices. We don't collect anything. We don't have servers. It's just you and your Jellyfin server.

Read our full [Privacy Policy](https://satsdisco.github.io/JellyAmp/PRIVACY_POLICY).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

JellyAmp is available under the MIT license. See the LICENSE file for more info.

## Acknowledgments

- Built for the [Jellyfin](https://jellyfin.org/) community
- Inspired by modern music players and cypherpunk aesthetics
- Uses Jellyfin's open API for seamless media streaming

## Support

For questions, issues, or feature requests:
- Open an issue on [GitHub](https://github.com/satsdisco/JellyAmp/issues)
- Check the [Jellyfin documentation](https://jellyfin.org/docs/)

---

**Made with 🎵 for Jellyfin users who love great design**
