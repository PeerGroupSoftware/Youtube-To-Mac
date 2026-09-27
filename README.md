# YoutubeToMac

Native macOS interface for downloading YouTube (and other) videos with [yt-dlp](https://github.com/yt-dlp/yt-dlp).

YoutubeToMac is an open-source Cocoa app written in Swift. It ships a universal `yt-dlp` binary, so it no longer depends on system Python (which fixed the macOS Monterey Python 2.7 warning and breakage after Python 2 was removed).

## Requirements

- macOS 11.0 or later
- Xcode 14+ to build from source
- Optional but recommended: [ffmpeg](https://ffmpeg.org/) for audio conversion (`mp3`, `wav`, `aac`)

  ```bash
  brew install ffmpeg
  ```

## Features

- Download video or extract audio from a pasted URL
- Format choices: Auto, 1080p / 720p / 480p, mp4, webm; audio Auto, m4a, mp3, wav, aac
- Progress UI, cancel, download folder picker, and recent-download history
- Clipboard auto-fill when a YouTube URL is on the pasteboard
- Touch Bar controls (Audio Only / Download)
- In-app update check against GitHub releases
- Bundled **yt-dlp 2026.08.19** (universal Intel + Apple Silicon)

## Build

1. Open `YoutubeToMac.xcodeproj` in Xcode
2. Select the **YoutubeToMac** scheme
3. Build & Run (⌘R)

The yt-dlp binary lives at `YT3Swift/YoutubeDL/yt-dlp_macos` and is copied into the app bundle as a resource. Version metadata is in `YT3Swift/YoutubeDL/VERSION.txt`.

## Updating yt-dlp

```bash
curl -L -o YT3Swift/YoutubeDL/yt-dlp_macos \
  "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
chmod +x YT3Swift/YoutubeDL/yt-dlp_macos
```

Update `VERSION.txt` to match the release tag.

## Notes

- **App Sandbox** is off so yt-dlp can write downloads and call Homebrew ffmpeg. Hardened Runtime stays on.
- Audio formats other than native streams need ffmpeg on your `PATH` (`/opt/homebrew/bin` and `/usr/local/bin` are searched automatically).
- This app is a GUI front-end; download behavior and site support come from yt-dlp.

## License / feedback

Issues and feature requests: [GitHub Issues](https://github.com/PeerGroupSoftware/Youtube-To-Mac/issues).
