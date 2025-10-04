# CachingPlayerItem

CachingPlayerItem is a subclass of AVPlayerItem that enables downloading and caching of media data. It is designed to be used with AVPlayer to play audio and video content from the internet.
It also supports preloading of media data to improve the playback experience.

## Usage

### Basic Playback with Caching

```swift
import AVFoundation
import CachingPlayerItem

let url = URL(string: "https://example.com/video.mp4")!
let playerItem = CachingPlayerItem(url: url)
let player = AVPlayer(playerItem: playerItem)

// Play the video - it will cache as it plays
player.play()
```

### Preloading Videos

```swift
let preloader = Preloader(preloadSize: 10 * 1024 * 1024) // Preload first 10MB
preloader.preload(url)

// Preload multiple videos
preloader.preload([url1, url2, url3])

// Cancel preloading if needed
preloader.cancelPreloading(for: url)
```

### Cache Management

```swift
// Set custom cache directory
VideoCacheManager.setCacheDirectory(URL(fileURLWithPath: "/custom/cache/path"))

// Invalidate cache for a specific video
let cacheManager = VideoCacheManager(for: url)
try cacheManager.invalidateCache()

// Clear all cached data
try VideoCacheManager.deleteCachedData()
```

## API Reference

- `CachingPlayerItem(url: URL)`: Creates a player item that caches video data.
- `Preloader`: Actor for preloading video segments.
- `VideoCacheManager`: Manages cache files and directories.

### Disclaimer

This package will cache the entire video to disk. This is not ideal for large videos as it will consume a lot of disk space.

This will also not work with HTTP Live Streaming (HLS) videos as they are not downloaded as a single file.
