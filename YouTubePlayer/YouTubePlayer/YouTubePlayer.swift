//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit
import WebKit

public enum PlayerState: String {
    case unstarted = "-1"
    case ended = "0"
    case playing = "1"
    case paused = "2"
    case buffering = "3"
    case queued = "4"
}

public enum PlayerEvents: String {
    case iframeAPIReady = "onYouTubeIframeAPIReady"
    case ready = "onReady"
    case stateChange = "onStateChange"
    case playbackQualityChange = "onPlaybackQualityChange"
}

public enum PlaybackQuality: String {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case hD720 = "hd720"
    case hD1080 = "hd1080"
    case highResolution = "highres"
}

public protocol YouTubePlayerDelegate: class {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: PlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: PlaybackQuality)
}

// Make delegate methods optional by providing default implementations
public extension YouTubePlayerDelegate {
    
    func playerReady(_ videoPlayer: YouTubePlayerView) {}
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: PlayerState) {}
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: PlaybackQuality) {}
    
}

private extension URL {
    var queryParams: [String: String] {
        
        // Check for query string
        guard let query = self.query else {
            return [:]
        }
        
        var dict = [String: String]()
        
        // Loop through pairings (separated by &)
        for pair in query.components(separatedBy: "&") {
            
            // Pull key, val from from pair parts (separated by =) and set dict[key] = value
            let components = pair.components(separatedBy: "=")
            if (components.count > 1) {
                dict[components[0]] = components[1]
            }
        }
        
        return dict
    }
}

public func videoIDFromYouTubeURL(_ videoURL: URL) -> String? {
    if videoURL.pathComponents.count > 1 && (videoURL.host?.hasSuffix("youtu.be"))! {
        return videoURL.pathComponents[1]
    } else if videoURL.pathComponents.contains("embed") {
        return videoURL.pathComponents.last
    }
    return videoURL.queryParams["v"]
}

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView {
    
    public typealias YouTubePlayerParameters = [String: AnyObject]
    public var baseURL = "about:blank"
    
    lazy private var webView: WKWebView = {
        let webView = WKWebView(frame: self.bounds, configuration: self.wkConfigs)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        return webView
    }()
    
    lazy private var wkConfigs: WKWebViewConfiguration = {
        let configs = WKWebViewConfiguration()
        configs.userContentController = self.wkUController
        configs.allowsInlineMediaPlayback = true
        return configs
    }()
    
    /// WKWebView equivalent for UIWebView's scalesPageToFit
    lazy private var wkUController: WKUserContentController = {
        // http://stackoverflow.com/questions/26295277/wkwebview-equivalent-for-uiwebviews-scalespagetofit
        var jscript = "var meta = document.createElement('meta');"
        jscript += "meta.name='viewport';"
        jscript += "meta.content='width=device-width';"
        jscript += "document.getElementsByTagName('head')[0].appendChild(meta);"
        
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        
        return wkUController
    }()
    
    /** The readiness of the player */
    fileprivate(set) open var ready = false
    
    /** The current state of the video player */
    fileprivate(set) open var playerState = PlayerState.unstarted
    
    /** The current playback quality of the video player */
    fileprivate(set) open var playbackQuality = PlaybackQuality.small
    
    /** Used to configure the player */
    open var playerVars = YouTubePlayerParameters()
    
    /** Used to respond to player events */
    open weak var delegate: YouTubePlayerDelegate?
    
    
    // MARK: Various methods for initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(webView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(webView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // Remove web view in case it's within view hierarchy, reset frame, add as subview
        webView.removeFromSuperview()
        webView.frame = bounds
        addSubview(webView)
    }
    
    
    // MARK: Load player
    
    open func loadVideoURL(_ videoURL: URL) {
        if let videoID = videoIDFromYouTubeURL(videoURL) {
            loadVideoID(videoID)
        }
    }
    
    open func loadVideoID(_ videoID: String) {
        var playerParams = playerParameters()
        playerParams["videoId"] = videoID as AnyObject?
        
        loadWebViewWithParameters(playerParams)
    }
    
    open func loadPlaylistID(_ playlistID: String) {
        // No videoId necessary when listType = playlist, list = [playlist Id]
        playerVars["listType"] = "playlist" as AnyObject?
        playerVars["list"] = playlistID as AnyObject?
        
        loadWebViewWithParameters(playerParameters())
    }
    
    
    // MARK: Player controls
    
    open func mute() {
        evaluatePlayerCommand("mute()")
    }
    
    open func unMute() {
        evaluatePlayerCommand("unMute()")
    }
    
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
    
    open func getDuration(completion: @escaping ((String?) -> Void)) {
        evaluatePlayerCommand("getDuration()", completion: completion)
    }
    
    open func getCurrentTime(completion: @escaping ((String?) -> Void)) {
        evaluatePlayerCommand("getCurrentTime()", completion: completion)
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
        webView.evaluateJavaScript(fullCommand) { response, _ in
            completion?(response as? String)
        }
    }
    
    
    // MARK: Player setup
    
    fileprivate func loadWebViewWithParameters(_ parameters: YouTubePlayerParameters) {
        
        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!
        
        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters as AnyObject)!
        
        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters)
        
        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: URL(string: baseURL))
    }
    
    fileprivate func playerHTMLPath() -> String {
        return Bundle(for: YouTubePlayerView.self).path(forResource: "YTPlayer", ofType: "html")!
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
            "height": "100%" as AnyObject,
            "width": "100%" as AnyObject,
            "events": playerCallbacks() as AnyObject,
            "playerVars": playerVars as AnyObject
        ]
    }
    
    fileprivate func playerCallbacks() -> YouTubePlayerParameters {
        return [
            "onReady": "onReady" as AnyObject,
            "onStateChange": "onStateChange" as AnyObject,
            "onPlaybackQualityChange": "onPlaybackQualityChange" as AnyObject,
            "onError": "onPlayerError" as AnyObject
        ]
    }
    
    fileprivate func serializedJSON(_ object: AnyObject) -> String? {
        
        do {
            // Serialize to JSON string
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            // Succeeded
            return NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?
            
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
        let data = eventURL.queryParams["data"]
        
        if let host = eventURL.host, let event = PlayerEvents(rawValue: host) {
            
            // Check event type and handle accordingly
            switch event {
            case .iframeAPIReady:
                ready = true
                break
                
            case .ready:
                delegate?.playerReady(self)
                
                break
                
            case .stateChange:
                if let newState = PlayerState(rawValue: data!) {
                    playerState = newState
                    delegate?.playerStateChanged(self, playerState: newState)
                }
                
                break
                
            case .playbackQualityChange:
                if let newQuality = PlaybackQuality(rawValue: data!) {
                    playbackQuality = newQuality
                    delegate?.playerQualityChanged(self, playbackQuality: newQuality)
                }
                
                break
            }
        }
    }
}

extension YouTubePlayerView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.scheme == "ytplayer" {
            handleJSEvent(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

private func printLog(_ strings: CustomStringConvertible...) {
    let toPrint = ["[YouTubePlayer]"] + strings
    print(toPrint, separator: " ", terminator: "\n")
}
