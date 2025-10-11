# AudioVisualService

A Swift package that provides intelligent caching and preloading capabilities for AVFoundation-based media playback. It enables offline viewing, faster subsequent playback, and improved user experience for streaming media content.

## Features

- **Automatic Caching**: Seamlessly caches video content during playback for offline access
- **Range-Aware Caching**: Tracks downloaded byte ranges to detect and handle missing segments
- **Preloading**: Proactively download video segments to improve playback experience
- **Cache Management**: Comprehensive cache lifecycle management with size limits and cleanup
- **Thread-Safe**: Built with Swift Concurrency (actors) for safe concurrent operations
- **AVFoundation Integration**: Drop-in replacement for standard AVPlayerItem usage

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/iankoex/AudioVisualService.git", from: "1.0.0")
]
```

Or add it directly in Xcode:

1. Go to File → Add Packages...
2. Enter the repository URL: `https://github.com/iankoex/AudioVisualService.git`

## Usage

### Basic Playback with Caching

```swift
import AVFoundation
import AudioVisualService

let videoURL = URL(string: "https://example.com/video.mp4")!
let playerItem = CachingPlayerItem(url: videoURL)
let player = AVPlayer(playerItem: playerItem)

// Play the video - content will be cached automatically
player.play()
```

### Using the Service Delegate

```swift
import AudioVisualService

class MyViewController: UIViewController, AudioVisualServiceDelegate {
    func didCacheData(url: URL, totalBytesCached: Int) {
        print("Cached \(totalBytesCached) bytes for \(url)")
        // Update UI with caching progress
    }

    func playVideo() {
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let playerItem = CachingPlayerItem(url: videoURL, serviceDelegate: self)
        let player = AVPlayer(playerItem: playerItem)
        player.play()
    }
}
```

### Advanced Asset Usage

```swift
import AudioVisualService

let videoURL = URL(string: "https://example.com/video.mp4")!
let asset = CachingAVURLAsset(url: videoURL)
let playerItem = AVPlayerItem(asset: asset)
let player = AVPlayer(playerItem: playerItem)

player.play()
```

### Preloading Videos

```swift
import AudioVisualService

// Create a preloader with 5MB preload limit
let preloader = Preloader(preloadSize: 5 * 1024 * 1024)

// Preload a single video
await preloader.preload(videoURL)

// Preload multiple videos concurrently
await preloader.preload([videoURL1, videoURL2, videoURL3])

// Cancel preloading if needed
await preloader.cancelPreloading(for: videoURL)
```

### Cache Management

```swift
import AudioVisualService

// Set custom cache directory (call this early in your app)
CacheManager.setCacheDirectory(URL(fileURLWithPath: "/custom/cache/path"))

// Check cache status for a video
let cacheManager = CacheManager(for: videoURL)
if cacheManager.isFullyCached {
    print("Video is available offline")
}

// Get total cache size
let totalSize = CacheManager.totalCacheSize()
print("Total cache size: \(totalSize) bytes")

// Clean up old cache files
CacheManager.enforceCacheLimit()

// Invalidate cache for a specific video
try cacheManager.invalidateCache()

// Clear all cached data
try CacheManager.deleteCachedData()
```

### Cache Validation

```swift
import AudioVisualService

let cacheManager = CacheManager(for: videoURL)

// Check if video is fully cached and playable
if cacheManager.isFullyCached {
    // Video is completely downloaded and validated
    print("Video ready for offline playback")
}
```

## Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 14.0+ / watchOS 7.0+
- Swift 5.8+
- Xcode 14.0+

## API Reference

### CachingPlayerItem

A drop-in replacement for `AVPlayerItem` with automatic caching capabilities.

```swift
public class CachingPlayerItem: AVPlayerItem, Sendable {
    public init(
        url: URL,
        automaticallyLoadedAssetKeys: [String]? = nil,
        serviceDelegate: AudioVisualServiceDelegate? = nil
    )
}
```

### CachingAVURLAsset

An `AVURLAsset` subclass that provides caching through custom resource loading.

```swift
public final class CachingAVURLAsset: AVURLAsset, @unchecked Sendable {
    public init(
        url: URL,
        options: [String: Any]? = nil,
        serviceDelegate: AudioVisualServiceDelegate? = nil
    )
}
```

### Preloader

An actor that manages preloading of video content to improve playback performance.

```swift
public actor Preloader: Sendable {
    public init(preloadSize: Int = 5 * 1024 * 1024)

    public func preload(_ url: URL)
    public func preload(_ urls: [URL])
    public func cancelPreloading(for url: URL)
}
```

### CacheManager

Manages local caching of video data with comprehensive lifecycle management.

```swift
public final class CacheManager: Sendable {
    public init(for url: URL)

    // Cache status
    public var isFullyCached: Bool { get }

    // Cache operations
    public func invalidateCache() throws

    // Static methods
    public static func setCacheDirectory(_ directory: URL)
    public static func totalCacheSize() -> Int
    public static func deleteCachedData() throws
    public static func enforceCacheLimit()
}
```

### AudioVisualServiceDelegate

A protocol for receiving callbacks about caching and loading events.

```swift
public protocol AudioVisualServiceDelegate: Sendable {
    func didCacheData(url: URL, totalBytesCached: Int)
}
```

## Architecture

AudioVisualService uses a layered architecture:

1. **CachingAVURLAsset**: Intercepts AVFoundation's resource loading requests
2. **ResourceLoader**: Manages the coordination between caching and network requests
3. **CacheManager**: Handles disk storage, retrieval, and cache lifecycle
4. **Preloader**: Provides proactive content downloading capabilities

## Cache Strategy

- **Range-Based Caching**: Tracks downloaded byte ranges to detect missing segments
- **Validation**: Ensures cached content is contiguous and playable
- **Automatic Cleanup**: Removes old cache files based on access time
- **Configurable Limits**: Set maximum cache size and retention policies

## Limitations & Considerations

### Supported Formats

- ✅ Progressive MP4, MOV, and other single-file video formats
- ❌ HTTP Live Streaming (HLS) - use native AVPlayer HLS support instead
- ❌ DASH streaming - not supported
- ❌ Encrypted/DRM-protected content

### Storage Considerations

- Videos are cached in their entirety to disk
- Large videos will consume significant storage space
- Cache size management is automatic but configurable
- Default retention: 7 days since last access

### Performance Notes

- First playback may buffer while caching begins
- Subsequent playbacks use cached content for instant start
- Network usage is optimized through range requests
- Concurrent preloading is supported for multiple videos

## Contributing

Contributions are welcome! Please ensure that:

- Documentation is updated for public APIs
- Code follows Swift concurrency best practices

## License

This project is licensed under the MIT License - see the LICENSE file for details.
