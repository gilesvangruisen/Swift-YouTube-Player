//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit
import WebKit

public enum YouTubePlayerState: String {
    case unstarted = "-1"
    case ended = "0"
    case playing = "1"
    case paused = "2"
    case buffering = "3"
    case queued = "4"
}

public enum YouTubePlayerEvents: String {
    case youTubeIframeAPIReady = "onYouTubeIframeAPIReady"
    case ready = "onReady"
    case stateChange = "onStateChange"
    case playbackQualityChange = "onPlaybackQualityChange"
}

public enum YouTubePlaybackQuality: String {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case hd720 = "hd720"
    case hd1080 = "hd1080"
    case highResolution = "highres"
}

public protocol YouTubePlayerDelegate {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)
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
                dict[components[0]] = components[1]
            }
            
        }
        
        return dict
    }
}

public func videoIDFromYouTubeURL(_ videoURL: URL) -> String? {
    if let url = videoURL.queryStringComponents()["v"] as? String, !url.isEmpty {
        return url
    } else {
        return videoURL.lastPathComponent
    }
}

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView, UIWebViewDelegate {
    
    public typealias YouTubePlayerParameters = [String: Any]
    
    fileprivate var webView: WKWebView!
    
    /** The readiness of the player */
    fileprivate(set) open var ready = false
    
    /** The current state of the video player */
    fileprivate(set) open var playerState = YouTubePlayerState.unstarted
    
    /** The current playback quality of the video player */
    fileprivate(set) open var playbackQuality = YouTubePlaybackQuality.small
    
    /** Used to configure the player */
    open var playerVars = YouTubePlayerParameters()
    
    /** Used to respond to player events */
    open var delegate: YouTubePlayerDelegate?
    
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
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        } else {
            webConfiguration.requiresUserActionForMediaPlayback = false
        }
        
        webView = WKWebView(frame: CGRect.zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
    }
    
    
    // MARK: Load player
    
    open func loadVideoURL(_ videoURL: URL) {
        if let videoID = videoIDFromYouTubeURL(videoURL) {
            loadVideoID(videoID)
        }
    }
    
    open func loadVideoID(_ videoID: String) {
        var playerParams = playerParameters()
        playerParams["videoId"] = videoID
        
        loadWebViewWithParameters(playerParams)
    }
    
    open func loadPlaylistID(_ playlistID: String) {
        // No videoId necessary when listType = playlist, list = [playlist Id]
        playerVars["listType"] = "playlist"
        playerVars["list"] = playlistID
        
        loadWebViewWithParameters(playerParameters())
    }
    
    
    // MARK: Player controls
    
    open func play() {
        evaluatePlayerCommand("playVideo()")
    }
    
    open func pause() {
        evaluatePlayerCommand("pauseVideo()")
    }
    
    open func stop() {
        evaluatePlayerCommand("stopVideo()")
    }
    
    open func clear() {
        evaluatePlayerCommand("clearVideo()")
    }
    
    open func seekTo(_ seconds: Float, seekAhead: Bool) {
        evaluatePlayerCommand("seekTo(\(seconds), \(seekAhead))")
    }
    
    open func getDuration(_ completion: @escaping (String?) -> Void)  {
        evaluatePlayerCommand("getDuration()") { (val) in
            completion(val)
        }
    }
    
    open func getCurrentTime(_ completion: @escaping (String?) -> Void) {
        evaluatePlayerCommand("getCurrentTime()") { (val) in
            completion(val)
        }
    }
    
    // MARK: Playlist controls
    
    open func previousVideo() {
        evaluatePlayerCommand("previousVideo()")
    }
    
    open func nextVideo() {
        evaluatePlayerCommand("nextVideo()")
    }
    
    fileprivate func evaluatePlayerCommand(_ command: String, completion: ((String?) -> Void)? = nil) {
        let fullCommand = "player." + command + ";"
        webView.evaluateJavaScript(fullCommand) { (returnedValue, error) in
            if let val = returnedValue as? String{
                completion?(val)
                return
            }
            
            completion?(nil)
        }
    }
    
    
    // MARK: Player setup
    
    fileprivate func loadWebViewWithParameters(_ parameters: YouTubePlayerParameters) {
        
        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!
        
        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters)!
        
        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters, options: [], range: nil)
        
        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: URL(string: "about:blank"))
    }
    
    fileprivate func playerHTMLPath() -> String {
        return Bundle(for: self.classForCoder).path(forResource: "YTPlayer", ofType: "html")!
    }
    
    fileprivate func htmlStringWithFilePath(_ path: String) -> String? {
        
        // Error optional for error handling
        var error: Error?
        
        // Get HTML string from path
        let htmlString: String?
        do {
            htmlString = try String(contentsOfFile: path)
        } catch let error1 {
            error = error1
            htmlString = nil
        }
        
        // Check for error
        if let _ = error {
            print("Lookup error: no HTML file found for path, \(path)")
        }
        
        return htmlString
    }
    
    
    // MARK: Player parameters and defaults
    
    fileprivate func playerParameters() -> YouTubePlayerParameters {
        
        playerVars["autoplay"] =  1
        playerVars["controls"] =  1
        playerVars["playsinline"] =  1
        
        return [
            "height": "100%",
            "width": "100%",
            "events": playerCallbacks(),
            "playerVars": playerVars
        ]
    }
    
    fileprivate func playerCallbacks() -> YouTubePlayerParameters {
        return [
            "onReady": "onReady",
            "onStateChange": "onStateChange",
            "onPlaybackQualityChange": "onPlaybackQualityChange",
            "onError": "onPlayerError"
        ]
    }
    
    fileprivate func serializedJSON(_ object: Any) -> String? {
        
        // Empty error
        var error: NSError?
        
        // Serialize json into NSData
        let jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch let error1 as NSError {
            error = error1
            jsonData = nil
        }
        
        // Check for error and return nil
        if let _ = error {
            print("Error parsing JSON")
            return nil
        }
        
        return String(bytes: jsonData!, encoding: .utf8)
    }
    
    
    // MARK: JS Event Handling
    
    fileprivate func handleJSEvent(_ eventURL: URL) {
        
        // Grab the last component of the queryString as string
        let data: String? = eventURL.queryStringComponents()["data"] as? String
        
        if let host = eventURL.host {
            if let event = YouTubePlayerEvents(rawValue: host) {
                // Check event type and handle accordingly
                switch event {
                case .youTubeIframeAPIReady:
                    ready = true
                    break
                    
                case .ready:
                    delegate?.playerReady(self)
                    
                    break
                    
                case .stateChange:
                    if let newState = YouTubePlayerState(rawValue: data!) {
                        playerState = newState
                        delegate?.playerStateChanged(self, playerState: newState)
                    }
                    
                    break
                    
                case .playbackQualityChange:
                    if let newQuality = YouTubePlaybackQuality(rawValue: data!) {
                        playbackQuality = newQuality
                        delegate?.playerQualityChanged(self, playbackQuality: newQuality)
                    }
                    
                    break
                }
            }
        }
    }
}


extension YouTubePlayerView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "ytplayer"  {
            handleJSEvent(url)
        }
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
}
