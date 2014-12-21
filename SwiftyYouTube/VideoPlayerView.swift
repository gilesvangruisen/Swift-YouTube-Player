//
//  VideoPlayerView.swift
//  SwiftyYouTube
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import UIKit

class VideoPlayerView: UIView {

    var webView: UIWebView

    override init(frame: CGRect) {
        webView = UIWebView()
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        webView = UIWebView()
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = frame
        addSubview(webView)
    }

    func buildWebView() {
        webView = UIWebView()
        webView.loadHTMLString(htmlStringWithFilePath(playerHTMLPath()), baseURL: nil)
    }

    func playerHTMLPath() -> String {
        return NSBundle.mainBundle().pathForResource("YTPlayer", ofType: "html")!
    }

    func htmlStringWithFilePath(path: String) -> String {
        var error: NSError?
        let htmlString = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)

        if let error = error {
            return "Lookup error: no HTML file found for path, \(path)"
        } else {
            return htmlString!
        }
    }

//    func loadVideoWithID(videoID: String) {
//
//    }

}
