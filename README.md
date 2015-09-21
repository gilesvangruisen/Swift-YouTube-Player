# YouTubePlayer

Embed and control YouTube videos in your iOS applications! Neato, right? Let's see how it works.

## Installation

### Carthage

Add this to your Cartfile:

```
github "gilesvangruisen/Swift-YouTube-Player"
```

…and then run `carthage update`

Don't forget to:
* add `YouTubePlayer.framework` to the `Link binary with libraries` build phase
* add `YouTubePlayer.framework` as an input file to the `carthage copy-frameworks` run script phase (only necesasry if you're building for iOS)

See [Carthage](http://github.com/carthage/carthage) for more information about using Carthage as a dependency manager.

### Cocoapods

Ensure you are opting into using frameworks with `use_frameworks!`. Then add the following to your Podfile:

```
pod 'YouTubePlayer'
```

…and then run `pod install`.


## Example

```Swift
// Import Swift module
import YouTubePlayer
```

Build and lay out the view however you wish, whether in IB w/ an outlet or programmatically.
```Swift
@IBOutlet var videoPlayer: YouTubePlayerView!
```
```Swift
// init YouTubePlayerView w/ playerFrame rect (assume playerFrame declared)
var videoPlayer = YouTubePlayerView(frame: playerFrame)
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

## Controlling YouTubePlayerView

Each `YouTubePlayerView` has methods for controlling the player (play, pause, seek, change video, etc.) They are:

* `func loadVideoURL(videoURL: NSURL)`
* `func loadVideoID(videoID: String)`
* `func loadPlaylistID(playlistID: String)`
* `func play()`
* `func pause()`
* `func stop()`
* `func clear()`
* `func seekTo(seconds: Float, seekAhead: Bool)`
* `func previousVideo()`
* `func nextVideo()`

Please note that calls to all but the first two methods will result in a JavaScript runtime error if they are called before the player is ready. The player will not be ready until shortly after a call to either `loadVideoURL(videoURL: NSURL)` or `loadVideoID(videoID: String)`. You can check the readiness of the player at any time by checking its `ready: Bool` property. These functions run asynchronously, so it is not guaranteed that a call to a play function will be safe if it immediately follows a call to a load function. I plan to update the library soon to add completion handlers to be called when the player is ready.

In the meantime, you can also the `YouTubePlayerDelegate` method `playerReady(videoPlayer: YouTubePlayerView)` to ensure code is executed immediately when the player becomes ready.

## Responding to events

[YouTube's iFrame player](https://developers.google.com/youtube/iframe_api_reference) emits certain events based on the lifecycle of the player. The `YouTubePlayerDelegate` outlines these methods that get called during a player's lifecycle. They are:

* `func playerReady(videoPlayer: YouTubePlayerView)`
* `func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)`
* `func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)`

*Side note:* unfortunately, due to the way Swift protocols work, these are all required delegate methods. Setting a delegate on an instance of `YouTubePlayer` is optional, but any delegate must conform to `YouTubePlayerDelegate` and therefore must implement every one of the above methods. I wish there were a better way around this, but declaring the protocol as an `@objc` protocol means I wouldn't be able to use enum values as arguments, because Swift enums are incompatible with Objective-C enumerations. Feel free to file an issue if you know of some solution that lets us have optional delegate methods as well as the ability to pass Swift enums to these delegate methods.

## Troubleshooting

If you are having problems with the following line:

`return NSBundle(forClass: self.classForCoder).pathForResource("YTPlayer", ofType: "html")!`

then the pod failed to include Y`TPlayer.html` in the resources of the project. The steps to fix this are as follows:

* Click on `Pods` project
* Click on `YouTubePlayer` under TARGETS
* Click on `Build Phases`
* Click on the **plus sign** (add build phase)
* Add a `Copy Files` build phase
* Set `Destination` to `Resources` and add the `YTPlayer.html` file
