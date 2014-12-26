# YouTubePlayer

Embed and control YouTube videos in your iOS applications! Neato, right? Let's see how it works.

## Example

```Swift
// Import Swift module
import YouTubePlayer
```

Build and lay out the view however you wish, whether in IB:
```Swift
@IBOutlet var videoPlayer: YouTubePlayer!
```
…or programmatically:
```Swift
// init YouTubePlayer w/ playerFrame rect (assume playerFrame declared)
var videoPlayer = YouTubePlayer(frame: playerFrame)
```

Give the player a video to load, whether from ID or URL.
```Swift
// Load video from YouTube ID
videoPlayer.loadVideoID("nfWlot6h_JM")
```
```Swift
// Load video from YouTube URL
let myVideoURL = NSURL(string: "https://www.youtube.com/watch?v=wQg3bXrVLtg")
videoPlayer.loadVideoURL(myVideoURL!)
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
