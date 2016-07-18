//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//
//  Updated for OSX/macOS by Justin Kaufman (JUSTINMKAUFMAN) on 7/6/16.
//

#if os(iOS)
    
import UIKit

#elseif os(OSX)

import Cocoa
import Foundation
import WebKit

#endif

    
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
    func playerReady(videoPlayer: YouTubePlayerView)
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)
    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)
}

// Make delegate methods optional by providing default implementations
public extension YouTubePlayerDelegate {
    
    func playerReady(videoPlayer: YouTubePlayerView) {}
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {}
    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {}
    
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
                if (components.count > 1) {
                    dict[components[0]] = components[1]
                }
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

/** These are the classes required for iOS (default) */
var playerClasses = [UIView, UIWebViewDelegate]

#if os(OSX)
    
    /** These are the different classes required for macOS */
    playerClasses = [NSView, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate]
    
#endif
    
public class YouTubePlayerView: playerClasses {

    public typealias YouTubePlayerParameters = [String: AnyObject]
    
    #if os(iOS)

        private var webView: UIWebView!

    #elseif os(OSX)
    
        public var contentController: WKUserContentController?
    
        public var webView: WKWebView?
    
        public var webConfig: WKWebViewConfiguration?
    
    #endif
    
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

    
    #if os(iOS)
    
        override public func layoutSubviews() {
            super.layoutSubviews()

            // Remove web view in case it's within view hierarchy, reset frame, add as subview
            webView.removeFromSuperview()
            webView.frame = bounds
            addSubview(webView)
    }
    
    #elseif os(OSX)
    
        override public func resizeSubviewsWithOldSize(oldSize: NSSize) {
        
            super.resizeSubviewsWithOldSize(oldSize)
        
            webView?.removeFromSuperview()
        
            webView!.frame = bounds
        
            addSubview(webView!)
        
        }
    
        override public func layout() {
        
            super.layout()
        
        }
    
    #endif
    

    // MARK: Web view initialization

    private func buildWebView(parameters: [String: AnyObject]) {
        
        #if os(iOS)
        
            webView = UIWebView()
            webView.allowsInlineMediaPlayback = true
            webView.mediaPlaybackRequiresUserAction = false
            webView.delegate = self
            webView.scrollView.scrollEnabled = false
        
        #elseif os(OSX)
        
            contentController = WKUserContentController()
            webConfig = WKWebViewConfiguration()
            webConfig!.userContentController = contentController!
            self.webView = WKWebView(frame: CGRectZero, configuration: webConfig!)
            self.webView?.navigationDelegate = self
            
        #endif
        
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
    
    public func getDuration() -> String? {
        return evaluatePlayerCommand("getDuration()")
    }
    
    public func getCurrentTime() -> String? {
        return evaluatePlayerCommand("getCurrentTime()")
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
        
        #if os(iOS)
            return webView.stringByEvaluatingJavaScriptFromString(fullCommand)
        #elseif os(OSX)
            return webView!.stringByEvaluatingJavaScriptFromString(fullCommand)
        #endif
    }


    // MARK: Player setup

    private func loadWebViewWithParameters(parameters: YouTubePlayerParameters) {

        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!

        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters)!

        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.stringByReplacingOccurrencesOfString("%@", withString: jsonParameters)

        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: NSURL(string: "about:blank"))
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


    #if os(iOS)
    
        // MARK: UIWebViewDelegate

        public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

            let url = request.URL

            // Check if ytplayer event and, if so, pass to handleJSEvent
            if let url = url where url.scheme == "ytplayer" { handleJSEvent(url) }

            return true
        }
    
    #elseif os(OSX)
    
        public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
            let action = navigationAction
        
            let actionUrl: NSURL = action.request.URL!
            
            if actionUrl.scheme == "ytplayer" {
            
                self.handleJSEvent(actionUrl)
            
                decisionHandler(.Cancel)
            
            }
            
            else {
            
                decisionHandler(.Allow)
            
            }
        
        }
    
        public func getStringFromCommand(command: String, arguments: [String]) -> String {
        
            let task = NSTask()
        
            task.launchPath = command
        
            task.arguments = arguments
        
            let pipe = NSPipe()
        
            task.standardOutput = pipe
        
            task.launch()
        
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
            let output: String = String(data: data, encoding: NSUTF8StringEncoding)!
        
            return output
        
        }
    
        public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
            if message.name == "player" {
            
                let data = message.body as! NSDictionary
            
                var string = getStringFromCommand(data["command"] as! String, arguments: data["arguments"] as! [String])
            
                string = string.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
            
                string = string.stringByReplacingOccurrencesOfString("\r", withString: "\\r")
            
                let callbackString = "window.callbacksFromOS[\"" + (data["callbackFunction"] as! String) + "\"](\"" + string + "\")"
            
                webView?.evaluateJavaScript(callbackString, completionHandler: nil)
            
            }
        
        }
    
    #endif
    
}

private func printLog(strings: CustomStringConvertible...) {
    let toPrint = ["[YouTubePlayer]"] + strings
    print(toPrint, separator: " ", terminator: "\n")
}

#if os(OSX)

    // The method for evaluating JavaScript on macOS runs async with
    // a completion handler. This makes it unsuitable as a drop-in
    // replacement for the equivalent iOS method (which runs sync).

    // The following extension uses the method in the macOS framework,
    // with additional code to wait for the return value to make it
    // compatible with the iOS method. 

    // Thanks to a SO post (apologies, but I seem to have lost track
    // of the post URL) for pointing me in the right direction on this.
    
    extension WKWebView {
        
        func stringByEvaluatingJavaScriptFromString(script: String) -> String {
            
            var resultString: String = ""
            
            var finished: Bool = false
            
            self.evaluateJavaScript(script, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
                
                if error == nil {
                    
                    if result != nil {
                        
                        // Handle adding optional string
                        if let strResult = result as? NSString {
                            
                            resultString = strResult as String
                            
                        }
                            
                        else {
                            
                            if let numResult = result as? NSNumber {
                                
                                resultString = numResult.stringValue
                                
                            }
                                
                            else{
                                
                                resultString = "\(result)"
                                
                            }
                            
                        }
                        
                    }
                    
                }
                    
                else {
                    
                    // Handle javascript data return error
                    
                }
                
                finished = true
                
            })
            
            while !finished {
                
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
                
            }
            return resultString
        }
        
    }
    
#endif


