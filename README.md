# CachingPlayerItem

CachingPlayerItem is a subclass of AVPlayerItem that enables downloading and caching of media data. It is designed to be used with AVPlayer to play audio and video content from the internet.
It also supports preloading of media data to improve the playback experience.

### Dislaimer

This package will cache the entire video to disk. This is not ideal for large videos as it will consume a lot of disk space.

This will also not work with HTTP Live Streaming (HLS) videos as they are not downloaded as a single file.
