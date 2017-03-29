//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit

public enum YouTubePlayerState: String {
    case Unstarted = "-1"
    case Ended = "0"
    case Playing = "1"
    case Paused = "2"
    case Buffering = "3"
    case Queued = "4"
}

public enum YouTubePlayerEvents: String {
    case YouTubeIframeAPIReady = "onYouTubeIframeAPIReady"
    case Ready = "onReady"
    case StateChange = "onStateChange"
    case PlaybackQualityChange = "onPlaybackQualityChange"
}

public enum YouTubePlaybackQuality: String {
    case Small = "small"
    case Medium = "medium"
    case Large = "large"
    case HD720 = "hd720"
    case HD1080 = "hd1080"
    case HighResolution = "highres"
}

public protocol YouTubePlayerDelegate: class {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)
}

// Make delegate methods optional by providing default implementations
public extension YouTubePlayerDelegate {
    
    func playerReady(_ videoPlayer: YouTubePlayerView) {}
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {}
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {}
    
}

private extension URL {
    func queryStringComponents() -> [String: Any] {

        var dict = [String: Any]()

        // Check for query string
        if let query = self.query {

            // Loop through pairings (separated by &)
            for pair in query.components(separatedBy: "&") {

                // Pull key, val from from pair parts (separated by =) and set dict[key] = value
                let components = pair.components(separatedBy: "=")
                if (components.count > 1) {
                    dict[components[0]] = components[1] as Any?
                }
            }

        }

        return dict
    }
}

public func videoIDFromYouTubeURL(_ videoURL: URL) -> String? {
    let pathComponents = videoURL.pathComponents
    if let host = videoURL.host, pathComponents.count > 1 && host.hasSuffix("youtu.be") {
        return pathComponents[1]
    }
    return videoURL.queryStringComponents()["v"] as? String
}

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView, UIWebViewDelegate {

    public typealias YouTubePlayerParameters = [String: Any]

    fileprivate var webView: UIWebView!

    /** The readiness of the player */
    fileprivate(set) open var ready = false

    /** The current state of the video player */
    fileprivate(set) open var playerState = YouTubePlayerState.Unstarted

    /** The current playback quality of the video player */
    fileprivate(set) open var playbackQuality = YouTubePlaybackQuality.Small

    /** Used to configure the player */
    open var playerVars = YouTubePlayerParameters()

    /** Used to respond to player events */
    open weak var delegate: YouTubePlayerDelegate?

    /** Video ID */
    open var videoID:String?
    
    /** Restricted */
    /** Set to true if you try play video and get error that
        its restricted to play only on youtube website */
    open var videoRestricted:Bool = false
    
    // MARK: Various methods for initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        buildWebView(playerParameters())
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        buildWebView(playerParameters())
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Remove web view in case it's within view hierarchy, reset frame, add as subview
        webView.removeFromSuperview()
        webView.frame = bounds
        addSubview(webView)
    }


    // MARK: Web view initialization

    fileprivate func buildWebView(_ parameters: [String: Any]) {
        webView = UIWebView()
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        webView.delegate = self
        webView.scrollView.isScrollEnabled = false
    }


    // MARK: Load player

    open func loadVideoURL(_ videoURL: URL) {
        if let videoID = videoIDFromYouTubeURL(videoURL) {
            loadVideoID(videoID)
        }
    }

    open func loadVideoID(_ videoID: String) {
        self.videoID = videoID
        var playerParams = playerParameters()
        playerParams["videoId"] = videoID as Any?

        loadWebViewWithParameters(playerParams)
    }

    open func loadPlaylistID(_ playlistID: String) {
        // No videoId necessary when listType = playlist, list = [playlist Id]
        playerVars["listType"] = "playlist" as Any?
        playerVars["list"] = playlistID as Any?

        loadWebViewWithParameters(playerParameters())
    }


    // MARK: Player controls

    open func play() {
        _ = evaluatePlayerCommand("playVideo()")
    }

    open func pause() {
        _ = evaluatePlayerCommand("pauseVideo()")
    }

    open func stop() {
        _ = evaluatePlayerCommand("stopVideo()")
    }

    open func clear() {
        _ = evaluatePlayerCommand("clearVideo()")
    }

    open func seekTo(_ seconds: Float, seekAhead: Bool) {
        _ = evaluatePlayerCommand("seekTo(\(seconds), \(seekAhead))")
    }
    
    open func getDuration() -> String? {
        return evaluatePlayerCommand("getDuration()")
    }
    
    open func getCurrentTime() -> String? {
        return evaluatePlayerCommand("getCurrentTime()")
    }

    // MARK: Playlist controls

    open func previousVideo() {
        _ = evaluatePlayerCommand("previousVideo()")
    }

    open func nextVideo() {
        _ = evaluatePlayerCommand("nextVideo()")
    }
    
    fileprivate func evaluatePlayerCommand(_ command: String) -> String? {
        let fullCommand = "player." + command + ";"
        return webView.stringByEvaluatingJavaScript(from: fullCommand)
    }


    // MARK: Player setup

    fileprivate func loadWebViewWithParameters(_ parameters: YouTubePlayerParameters) {

        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!

        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters as Any)!

        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters)

        // Load HTML in web view
        if videoRestricted {
            if let videoID = videoID {
                webView.loadHTMLString(htmlString, baseURL: URL(string: "https://www.youtube.com/embed/\(videoID)"))
            }
        } else {
            webView.loadHTMLString(htmlString, baseURL: URL(string: "about:blank"))
        }
    }

    fileprivate func playerHTMLPath() -> String {
        return Bundle(for: self.classForCoder).path(forResource: "YTPlayer", ofType: "html")!
    }

    fileprivate func htmlStringWithFilePath(_ path: String) -> String? {

        do {

            // Get HTML string from path
            let htmlString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)

            return htmlString as String

        } catch _ {

            // Error fetching HTML
            printLog("Lookup error: no HTML file found for path")

            return nil
        }
    }


    // MARK: Player parameters and defaults

    fileprivate func playerParameters() -> YouTubePlayerParameters {

        return [
            "height": "100%" as Any,
            "width": "100%" as Any,
            "events": playerCallbacks() as Any,
            "playerVars": playerVars as Any
        ]
    }

    fileprivate func playerCallbacks() -> YouTubePlayerParameters {
        return [
            "onReady": "onReady" as Any,
            "onStateChange": "onStateChange" as Any,
            "onPlaybackQualityChange": "onPlaybackQualityChange" as Any,
            "onError": "onPlayerError" as Any
        ]
    }

    fileprivate func serializedJSON(_ object: Any) -> String? {

        do {
            // Serialize to JSON string
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)

            // Succeeded
            return NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String

        } catch let jsonError {

            // JSON serialization failed
            print(jsonError)
            printLog("Error parsing JSON")

            return nil
        }
    }


    // MARK: JS Event Handling

    fileprivate func handleJSEvent(_ eventURL: URL) {

        // Grab the last component of the queryString as string
        let data: String? = eventURL.queryStringComponents()["data"] as? String

        if let host = eventURL.host, let event = YouTubePlayerEvents(rawValue: host) {

            // Check event type and handle accordingly
            switch event {
                case .YouTubeIframeAPIReady:
                    ready = true
                    break

                case .Ready:
                    delegate?.playerReady(self)

                    break

                case .StateChange:
                    if let newState = YouTubePlayerState(rawValue: data!) {
                        playerState = newState
                        delegate?.playerStateChanged(self, playerState: newState)
                    }

                    break

                case .PlaybackQualityChange:
                    if let newQuality = YouTubePlaybackQuality(rawValue: data!) {
                        playbackQuality = newQuality
                        delegate?.playerQualityChanged(self, playbackQuality: newQuality)
                    }

                    break
            }
        }
    }


    // MARK: UIWebViewDelegate

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        let url = request.url

        // Check if ytplayer event and, if so, pass to handleJSEvent
        if let url = url, url.scheme == "ytplayer" { handleJSEvent(url) }

        return true
    }
}

private func printLog(_ strings: CustomStringConvertible...) {
    let toPrint = ["[YouTubePlayer]"] + strings
    print(toPrint, separator: " ", terminator: "\n")
}
