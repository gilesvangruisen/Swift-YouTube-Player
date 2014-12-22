//
//  VideoPlayerView.swift
//  SwiftyYouTube
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit

public class VideoPlayerView: UIView {

    typealias PlayerParameters = [String: AnyObject]

    var webView: UIWebView!


    // MARK: Various methods for initialization

    override public init() {
        super.init()
        buildWebView(playerParameters())
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        buildWebView(playerParameters())
    }

    required public init(coder aDecoder: NSCoder) {
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
    }

    // MARK: Player controls

    public func loadPlayerWithVideoID(videoID: String) {
        var playerParams = playerParameters()
        playerParams["videoId"] = videoID

        loadWebViewWithParameters(playerParams)
    }

    public func play() {
        let result = webView.stringByEvaluatingJavaScriptFromString("player.playVideo();")
        println(result)
    }




    // MARK: Player setup

    private func loadWebViewWithParameters(parameters: PlayerParameters) {

        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!

        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters)!

        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.stringByReplacingOccurrencesOfString("%@", withString: jsonParameters, options: nil, range: nil)

        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: NSURL(string: "about:blank"))
    }

    private func playerHTMLPath() -> String {
        return NSBundle(forClass: self.classForCoder).pathForResource("YTPlayer", ofType: "html")!
    }

    private func htmlStringWithFilePath(path: String) -> String? {

        // Error optional for error handling
        var error: NSError?

        // Get HTML string from path
        let htmlString = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)

        // Check for error
        if let error = error {
            println("Lookup error: no HTML file found for path, \(path)")
        }

        return htmlString!
    }


    // MARK: Player parameters and defaults

    private func playerParameters() -> PlayerParameters {

        // Fetch default playerVars
        var playerVars = defaultPlayerVars()

        return [
            "height": "100%",
            "width": "100%",
            "events": playerCallbacks(),
            "playerVars": playerVars
        ]
    }

    private func defaultPlayerVars() -> PlayerParameters {
        return [
            "playsinline": 1,
            "controls": 0,
            "autoplay": 1,
            "disablekb": 1,
            "rel": 0,
            "modestbranding": 1,
            "showinfo": 0
        ]
    }

    private func playerCallbacks() -> PlayerParameters {
        return [
            "onReady": "onReady",
            "onStateChange": "onStateChange",
            "onPlaybackQualityChange": "onPlaybackQualityChange",
            "onError": "onPlayerError"
        ]
    }

    private func serializedJSON(object: AnyObject) -> String? {

        // Empty error
        var error: NSError?

        // Serialize json into NSData
        let jsonData = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted, error: &error)

        // Check for error and return nil
        if let error = error {
            println("Error parsing JSON")
            return nil
        }

        // Success, return JSON string
        return NSString(data: jsonData!, encoding: NSUTF8StringEncoding)
    }
}
