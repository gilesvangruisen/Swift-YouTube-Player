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
    case small
    case medium
    case large
    case hd720
    case hd1080
    case highres
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
    var youtubeID: String? {
        let rule = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: rule, options: .caseInsensitive)
        let range = NSRange(location: 0, length: absoluteString.count)
        guard let checkingResult = regex?.firstMatch(in: absoluteString, options: [], range: range) else { return nil }
        
        return (absoluteString as NSString).substring(with: checkingResult.range)
    }
    
    var queryParams: [String: String] {
        guard let query = self.query else { return [:] }
        
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

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView {
    
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
    fileprivate(set) open var playerState = PlayerState.unstarted {
        didSet {
            delegate?.playerStateChanged(self, playerState: playerState)
        }
    }
    
    /** The current playback quality of the video player */
    fileprivate(set) open var playbackQuality = PlaybackQuality.small {
        didSet {
            delegate?.playerQualityChanged(self, playbackQuality: playbackQuality)
        }
    }
    
    /** Used to configure the player */
    open var playerParams = PlayerParameters()
    
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
        if let videoID = videoURL.youtubeID {
            loadVideoID(videoID)
        }
    }
    
    open func loadVideoID(_ videoID: String) {
        playerParams.videoId = videoID
        loadWebViewWithParameters(playerParams)
    }
    
    open func loadPlaylistID(_ playlistID: String) {
        playerParams.list = playlistID
        loadWebViewWithParameters(playerParams)
    }
    
    
    // MARK: Player setup
    
    fileprivate func loadWebViewWithParameters(_ parameters: PlayerParameters) {
        // Get JSON / HTML strings
        guard
            let encoded = try? JSONEncoder().encode(parameters),
            let jsonParameters = String(data: encoded, encoding: .utf8),
            let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())
            else {
                assertionFailure("Can't encode parameters")
                return
        }
        
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters)
        webView.loadHTMLString(htmlString, baseURL: nil)
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
            printLog("Lookup error: no HTML file found for path")
            return nil
        }
    }
    
    
    // MARK: JS Event Handling
    
    fileprivate func handleJSEvent(_ eventURL: URL) {
        guard let host = eventURL.host, let event = PlayerEvents(rawValue: host) else { return }
        
        switch event {
        case .iframeAPIReady:
            ready = true
            
        case .ready:
            delegate?.playerReady(self)
            
        case .stateChange:
            if let data = eventURL.queryParams["data"], let newState = PlayerState(rawValue: data) {
                playerState = newState
            }
            
        case .playbackQualityChange:
            if let data = eventURL.queryParams["data"], let newQuality = PlaybackQuality(rawValue: data) {
                playbackQuality = newQuality
            }
        }
    }
}

// MARK: - Controls

extension YouTubePlayerView {
    
    // MARK: Player controls
    
    open func mute() {
        evaluatePlayerCommand(#function)
    }
    
    open func unMute() {
        evaluatePlayerCommand(#function)
    }
    
    open func playVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func pauseVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func stopVideo() {
        evaluatePlayerCommand(#function)
    }
    
    open func clearVideo() {
        evaluatePlayerCommand(#function)
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
        evaluatePlayerCommand(#function)
    }
    
    open func nextVideo() {
        evaluatePlayerCommand(#function)
    }
    
    // MARK: Helper
    
    fileprivate func evaluatePlayerCommand(_ command: String, completion: ((String?) -> Void)? = nil) {
        let fullCommand = "player." + command + ";"
        webView.evaluateJavaScript(fullCommand) { response, _ in
            completion?(response as? String)
        }
    }
}

extension YouTubePlayerView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
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
