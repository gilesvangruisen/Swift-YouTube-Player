# Swift YouTube Player

Swift library for embedding and controlling YouTube videos in your iOS applications!

## VideoPlayerView

`VideoPlayerView` inherits from `UIView` so you can initialize and configure it however you wish, including in IB. To load a video, call `loadPlayerWithVideoID(videoID: String)`, passing the ID of the video. If you only have a URL, e.g. `https://www.youtube.com/watch?v=nfWlot6h_JM`, the video ID is the bit after `?v=`, in this case, `nfWlot6h_JM`. I'll be updating the library soon to be able to load videos from a YouTube URL.

Behind the scenes, it's using a `UIWebView` and [YouTube's iFrame API](https://developers.google.com/youtube/iframe_api_reference) to load, play, and control videos.

## Example

``` Swift
import YouTubePlayer

@IBOutlet var playerView = VideoPlayerView()

override func viewDidLoad() {
    super.viewDidLoad()
    
    playerView.loadPlayerWithVideoID("wQg3bXrVLtg")
}

@IBAction func playVideo(sender: UIButton) {
    playerView.play()
}

```

## Controlling VideoPlayerView

Each `VideoPlayerView` has controls for loading, playing, pausing, stopping, clearing, and seeking videos. They are:

* `loadPlayerWithVideoID(videoID: String)`
* `play()`
* `pause()`
* `stop()`
* `clear()`
* `seekTo(seconds: Float, seekAhead: Bool)`

## Responding to events

YouTube's iFrame player emits certain events based on the lifecycle of the player. The `VideoPlayerViewDelegate` outlines these methods that get called during a player's lifecycle. They are:

* `func videoPlayerReady(videoPlayer: VideoPlayerView)`
* `func videoPlayerStateChanged(videoPlayer: VideoPlayerView, playerState: VideoPlayerState)`
* `func videoPlayerQualityChanged(videoPlayer: VideoPlayerView, playbackQuality: VideoPlaybackQuality)`

Unfortunately due to the way Swift protocols work, these are all required delegate methods. Setting a delegate on an instance of `VideoPlayerView` is optional, but any delegate must conform to `VideoPlayerViewDelegate` and therefore must implement every one of the above methods. I wish there were a better way around this, but declaring the protocol as an `@objc` protocol means I wouldn't be able to use enum values as arguments, because Swift enums are incompatible with Objective-C enumerations. Feel free to file an issue if you know of some solution that lets us have optional delegate methods as well as the ability to pass Swift enums to these delegate methods.



