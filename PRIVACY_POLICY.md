# Privacy Policy for JellyAmp

**Last Updated: October 18, 2024**

## Overview

JellyAmp is a personal music streaming client for Jellyfin media servers. This privacy policy explains how JellyAmp handles your data.

## Data Collection and Storage

### What JellyAmp Collects

JellyAmp stores the following information locally on your device:

- **Jellyfin Server URL**: The web address of your personal Jellyfin server
- **Authentication Token**: A secure access token provided by your Jellyfin server
- **User ID**: Your Jellyfin user identifier
- **User Preferences**: App settings like repeat mode, shuffle state, and cached library data

### How Data is Stored

- Authentication tokens are stored securely in the device **Keychain** (encrypted at rest)
- Server URLs and user preferences are stored in **UserDefaults** (local device storage)
- Library cache (album/artist names, artwork URLs) is stored locally for faster app performance

### Apple Watch

When using the Apple Watch companion app, credentials are synced between your iPhone and Apple Watch using Apple's **WatchConnectivity** framework. This data never leaves your devices.

## Data Usage

### What JellyAmp Does With Your Data

- Connects to **YOUR** Jellyfin server using the credentials you provide
- Streams music directly from **YOUR** Jellyfin server to your device
- Caches library metadata to improve performance

### What JellyAmp Does NOT Do

- ❌ We do **NOT** collect any analytics or telemetry
- ❌ We do **NOT** store your data on our servers (we don't have servers)
- ❌ We do **NOT** share, sell, or transmit your data to third parties
- ❌ We do **NOT** track your listening habits
- ❌ We do **NOT** require an account with us

## Third-Party Services

JellyAmp connects directly to **your** Jellyfin server. Your Jellyfin server handles all media content, user management, and data storage. Please refer to your Jellyfin server administrator for information about how your media server handles data.

JellyAmp does not use any third-party analytics, advertising, or tracking services.

## Data Security

- Authentication tokens are stored in the iOS/watchOS Keychain with hardware encryption
- All communication with your Jellyfin server uses HTTPS (if your server supports it)
- No data is transmitted to any server except your own Jellyfin server

## Data Deletion

You can delete all JellyAmp data at any time by:

1. Opening JellyAmp Settings
2. Tapping "Sign Out"
3. Deleting the app from your device

This removes all stored credentials, server URLs, and cached data.

## Children's Privacy

JellyAmp does not knowingly collect any information from anyone, including children under 13. The app is a personal media player that connects only to your own Jellyfin server.

## Changes to This Privacy Policy

We may update this privacy policy from time to time. Changes will be posted in the app and on this page with an updated "Last Updated" date.

## Your Rights

Since JellyAmp stores all data locally on your device and does not collect or transmit data to us, you have complete control over your data at all times. You can view, modify, or delete your data by managing the app on your device.

## Contact

If you have questions about this privacy policy, please open an issue on our GitHub repository:

https://github.com/[your-username]/JellyAmp

---

**Summary**: JellyAmp is a local-first app. Your credentials and data stay on your devices. We don't collect anything. We don't have servers. It's just you and your Jellyfin server.
