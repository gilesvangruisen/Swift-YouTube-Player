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
    case Error = "onError"
    case PlayTime = "onPlayTime"
}

public enum YouTubePlaybackQuality: String {
    case Small = "small"
    case Medium = "medium"
    case Large = "large"
    case HD720 = "hd720"
    case HD1080 = "hd1080"
    case HighResolution = "highres"
}

private enum YouTubePlayerErrorCodes: String {
    case InvalidParameter = "2"
    case HTML5 = "5"
    case VideoNotFound = "100"
    case NotEmbeddable = "101"
    case CannotFindVideo = "105"
    case SameAsNotEmbeddable = "150"
}

public enum YouTubePlayerError {
    case InvalidParameter
    case HTML5
    case VideoNotFound
    case NotEmbeddable
}

public protocol YouTubePlayerDelegate: class {
    func playerReady(videoPlayer: YouTubePlayerView)
    func player(videoPlayer: YouTubePlayerView, stateChanged state: YouTubePlayerState)
    func player(videoPlayer: YouTubePlayerView, playbackQualityChanged quality: YouTubePlaybackQuality)
    func player(videoPlayer: YouTubePlayerView, receivedError error: YouTubePlayerError)
    func player(videoPlayer: YouTubePlayerView, didPlayTime time: NSTimeInterval)
}

// Make delegate methods optional by providing default implementations
public extension YouTubePlayerDelegate {
    
    func playerReady(videoPlayer: YouTubePlayerView) {}
    func player(videoPlayer: YouTubePlayerView, stateChanged state: YouTubePlayerState) {}
    func player(videoPlayer: YouTubePlayerView, playbackQualityChanged quality: YouTubePlaybackQuality) {}
    func player(videoPlayer: YouTubePlayerView, receivedError error: YouTubePlayerError) {}
    func player(videoPlayer: YouTubePlayerView, didPlayTime time: NSTimeInterval) {}
    
}

private extension NSURL {
    func queryStringComponents() -> [String: AnyObject] {

        var dict = [String: AnyObject]()

        // Check for query string
        if let query = self.query {

            // Loop through pairings (separated by &)
            for pair in query.componentsSeparatedByString("&") {

                // Pull key, val from from pair parts (separated by =) and set dict[key] = value
                let components = pair.componentsSeparatedByString("=")
                dict[components[0]] = components[1]
            }

        }

        return dict
    }
}

public func videoIDFromYouTubeURL(videoURL: NSURL) -> String? {
    if let host = videoURL.host, pathComponents = videoURL.pathComponents where pathComponents.count > 1 && host.hasSuffix("youtu.be") {
        return pathComponents[1]
    }
    return videoURL.queryStringComponents()["v"] as? String
}

/** Embed and control YouTube videos */
public class YouTubePlayerView: UIView, UIWebViewDelegate {

    public typealias YouTubePlayerParameters = [String: AnyObject]

    private var webView: UIWebView!

    /** The readiness of the player */
    private(set) public var ready = false

    /** The current state of the video player */
    private(set) public var playerState = YouTubePlayerState.Unstarted

    /** The current playback quality of the video player */
    private(set) public var playbackQuality = YouTubePlaybackQuality.Small

    /** Used to configure the player */
    public var playerVars = YouTubePlayerParameters()

    /** Used to respond to player events */
    public weak var delegate: YouTubePlayerDelegate?


    // MARK: Various methods for initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        buildWebView(playerParameters())
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        buildWebView(playerParameters())
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        // Remove web view in case it's within view hierarchy, reset frame, add as subview
        webView.removeFromSuperview()
        webView.frame = bounds
        addSubview(webView)
    }


    // MARK: Web view initialization

    private func buildWebView(parameters: [String: AnyObject]) {
        webView = UIWebView()
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        webView.delegate = self
        webView.opaque = false
        webView.scrollView.scrollEnabled = false
    }


    // MARK: Load player

    public func loadVideoURL(videoURL: NSURL) {
        if let videoID = videoIDFromYouTubeURL(videoURL) {
            loadVideoID(videoID)
        }
    }

    public func loadVideoID(videoID: String) {
        var playerParams = playerParameters()
        playerParams["videoId"] = videoID

        loadWebViewWithParameters(playerParams)
    }

    public func loadPlaylistID(playlistID: String) {
        // No videoId necessary when listType = playlist, list = [playlist Id]
        playerVars["listType"] = "playlist"
        playerVars["list"] = playlistID

        loadWebViewWithParameters(playerParameters())
    }


    // MARK: Player controls

    public func play() {
        evaluatePlayerCommand("playVideo()")
    }

    public func pause() {
        evaluatePlayerCommand("pauseVideo()")
    }

    public func stop() {
        evaluatePlayerCommand("stopVideo()")
    }

    public func clear() {
        evaluatePlayerCommand("clearVideo()")
    }

    public func seekTo(seconds: Float, seekAhead: Bool) {
        evaluatePlayerCommand("seekTo(\(seconds), \(seekAhead))")
    }
    
    public func getDuration() -> NSTimeInterval? {
        if let duration = evaluatePlayerCommand("getDuration()") {
            return NSTimeInterval(duration)
        }
        return nil
    }
    
    public func getCurrentTime() -> NSTimeInterval? {
        if let currentTime = evaluatePlayerCommand("getCurrentTime()") {
            return NSTimeInterval(currentTime)
        }
        return nil
    }

    // MARK: Playlist controls

    public func previousVideo() {
        evaluatePlayerCommand("previousVideo()")
    }

    public func nextVideo() {
        evaluatePlayerCommand("nextVideo()")
    }
    
    private func evaluatePlayerCommand(command: String) -> String? {
        let fullCommand = "player." + command + ";"
        return webView.stringByEvaluatingJavaScriptFromString(fullCommand)
    }


    // MARK: Player setup

    private func loadWebViewWithParameters(parameters: YouTubePlayerParameters) {

        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!

        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters)!

        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.stringByReplacingOccurrencesOfString("%@", withString: jsonParameters)
        
        let baseURL: NSURL?
        if  let playerVars = parameters["playerVars"] as? YouTubePlayerParameters,
            let origin = playerVars["origin"] as? String,
            let originURL = NSURL(string: origin) {
                baseURL = originURL
        } else {
            baseURL = NSURL(string: "about:blank")
        }
        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }

    private func playerHTMLPath() -> String {
        return NSBundle(forClass: self.classForCoder).pathForResource("YTPlayer", ofType: "html")!
    }

    private func htmlStringWithFilePath(path: String) -> String? {

        do {

            // Get HTML string from path
            let htmlString = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)

            return htmlString as String

        } catch _ {

            // Error fetching HTML
            printLog("Lookup error: no HTML file found for path")

            return nil
        }
    }


    // MARK: Player parameters and defaults

    private func playerParameters() -> YouTubePlayerParameters {

        return [
            "height": "100%",
            "width": "100%",
            "events": playerCallbacks(),
            "playerVars": playerVars
        ]
    }

    private func playerCallbacks() -> YouTubePlayerParameters {
        return [
            "onReady": "onReady",
            "onStateChange": "onStateChange",
            "onPlaybackQualityChange": "onPlaybackQualityChange",
            "onError": "onPlayerError"
        ]
    }

    private func serializedJSON(object: AnyObject) -> String? {

        do {
            // Serialize to JSON string
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)

            // Succeeded
            return NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String

        } catch let jsonError {

            // JSON serialization failed
            print(jsonError)
            printLog("Error parsing JSON")

            return nil
        }
    }


    // MARK: JS Event Handling

    private func handleJSEvent(eventURL: NSURL) {
        
        // Grab the last component of the queryString as string
        guard let host = eventURL.host else { return }
        guard let event = YouTubePlayerEvents(rawValue: host) else { return }
        
        let data: String? = eventURL.queryStringComponents()["data"] as? String
        
        // Check event type and handle accordingly
        switch event {
        case .YouTubeIframeAPIReady:
            ready = true
            
        case .Ready:
            delegate?.playerReady(self)
            
        case .StateChange:
            if let data = data, let newState = YouTubePlayerState(rawValue: data) {
                playerState = newState
                delegate?.player(self, stateChanged: newState)
            }
            
        case .PlaybackQualityChange:
            if let data = data, let newQuality = YouTubePlaybackQuality(rawValue: data) {
                playbackQuality = newQuality
                delegate?.player(self, playbackQualityChanged: newQuality)
            }
            
        case .Error:
            if let data = data, let errorCode = YouTubePlayerErrorCodes(rawValue: data) {
                let error: YouTubePlayerError
                switch errorCode {
                case .CannotFindVideo:
                    fallthrough
                case .VideoNotFound:
                    error = .VideoNotFound
                case .HTML5:
                    error = .HTML5
                case .InvalidParameter:
                    error = .InvalidParameter
                case .NotEmbeddable:
                    fallthrough
                case .SameAsNotEmbeddable:
                    error = .NotEmbeddable
                }
                delegate?.player(self, receivedError: error)
            }
            
        case .PlayTime:
            if let data = data, let time = NSTimeInterval(data) {
                delegate?.player(self, didPlayTime: time)
            }
            
        }
    }


    // MARK: UIWebViewDelegate

    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        let url = request.URL

        // Check if ytplayer event and, if so, pass to handleJSEvent
        if let url = url where url.scheme == "ytplayer" { handleJSEvent(url) }

        return true
    }
}

private func printLog(strings: CustomStringConvertible...) {
    let toPrint = ["[YouTubePlayer]"] + strings
    print(toPrint, separator: " ", terminator: "\n")
}
