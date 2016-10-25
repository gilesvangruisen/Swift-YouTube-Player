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

public protocol YouTubePlayerDelegate {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)
}

private extension URL {
    func queryStringComponents() -> [String: AnyObject] {

        var dict = [String: AnyObject]()

        // Check for query string
        if let query = self.query {

            // Loop through pairings (separated by &)
            for pair in query.components(separatedBy: "&") {

                // Pull key, val from from pair parts (separated by =) and set dict[key] = value
                let components = pair.components(separatedBy: "=")
                dict[components[0]] = components[1] as AnyObject?
            }

        }

        return dict
    }
}

public func videoIDFromYouTubeURL(_ videoURL: URL) -> String? {
    return videoURL.queryStringComponents()["v"] as? String
}

/** Embed and control YouTube videos */
open class YouTubePlayerView: UIView, UIWebViewDelegate,YouTubePlayerDelegate {
    
    struct Keys{
        
        //trigger "Can not load" after some seconds
        static let timerTimeInterval : TimeInterval = 40.0
        
        //Activity Indicator's container and loading view settings
        static let actIndicatorContainerColor : String = "000000"
        static let actIndicatorLoadingViewFrameWidth : CGFloat = 70.0
        static let actIndicatorLoadingViewFrameHeight : CGFloat = 70.0
        static let actIndicatorLoadingViewBackGroundColor : String = "929292"
        
        //Activity Indicator settings
        static let actIndicatorFrameWidth : CGFloat = 40.0
        static let actIndicatorFrameHeigth : CGFloat = 40.0
        static let actIndicatorColor : String = "616161"
        
        //Warning Label settings
        static let warningLabelFrameWidthRatio : CGFloat = 1.8
        static let warningLabelFrameHeightRatio: CGFloat = 2.0
        static let warningLabelText: String = "CAN NOT LOAD VIDEO, PLEASE TRY AGAIN LATER!"
        static let warningLabelTextColor: String = "A9ABB3"
        static let warningLabelTextFontType: String = "Avenir Next Condensed Ultra Light"
        static let warningLabelTextFontSize: CGFloat = 20.0
    }
    
    var actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    
    //Activity indicator background view
    var container: UIView = UIView()
    
    //Activity indicator loading view
    var loadingView: UIView = UIView()
    
    //Load timer, it allows Warning Label (Can not load) to be presented after some seconds.
    public var timer: Timer!
    
    //configure and show loading spinner
    public func showActivityIndicatorView(){
        
        let container: UIView = UIView()
        container.frame = webView.frame
        container.center = webView.center
        container.backgroundColor = UIColor(colorCode: Keys.actIndicatorContainerColor, alpha: 1.0)
        container.tag = 1453
        
        loadingView.frame = CGRect(x: 0, y: 0, width: Keys.actIndicatorLoadingViewFrameWidth, height: Keys.actIndicatorLoadingViewFrameHeight)
        loadingView.center = webView.center
        loadingView.backgroundColor = UIColor(colorCode: Keys.actIndicatorLoadingViewBackGroundColor, alpha: 1.0)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = loadingView.frame.height/2
        loadingView.tag = 1454
        
        actInd.frame = CGRect(x: 0, y: 0, width: Keys.actIndicatorLoadingViewFrameWidth
            , height: Keys.actIndicatorLoadingViewFrameHeight)
        actInd.center = CGPoint(x: loadingView.frame.size.width/2, y: loadingView.frame.size.height/2)
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.white
        actInd.color = UIColor(colorCode: Keys.actIndicatorColor, alpha: 1.0)
        actInd.tag = 1455
        
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        self.webView.addSubview(container)
        
        actInd.startAnimating()
    }
    
    //stop activity indicator and remove related subviews
    public func removeActivityIndicatorView(){
        actInd.stopAnimating()
        self.viewWithTag(1455)?.removeFromSuperview()
        self.viewWithTag(1454)?.removeFromSuperview()
        self.viewWithTag(1453)?.removeFromSuperview()
    }

    public typealias YouTubePlayerParameters = [String: AnyObject]

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
    open var delegate: YouTubePlayerDelegate?


    // MARK: Various methods for initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)

        printLog("initframe")
        buildWebView(playerParameters())
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        buildWebView(playerParameters())
    }
    
    public func playerReady(_ videoPlayer: YouTubePlayerView){
        
        removeActivityIndicatorView()
    }
    
    public func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {}
    
    
    public func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {}

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Remove web view in case it's within view hierarchy, reset frame, add as subview
        webView.removeFromSuperview()
        webView.frame = bounds
        addSubview(webView)
    }


    // MARK: Web view initialization

    fileprivate func buildWebView(_ parameters: [String: AnyObject]) {
        webView = UIWebView()
        webView.allowsInlineMediaPlayback = true
        webView.backgroundColor = UIColor.black
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

    // MARK: Playlist controls

    open func previousVideo() {
        evaluatePlayerCommand("previousVideo()")
    }

    open func nextVideo() {
        evaluatePlayerCommand("nextVideo()")
    }

    fileprivate func evaluatePlayerCommand(_ command: String) {
        let fullCommand = "player." + command + ";"
        webView.stringByEvaluatingJavaScript(from: fullCommand)
    }


    // MARK: Player setup

    fileprivate func loadWebViewWithParameters(_ parameters: YouTubePlayerParameters) {

        //prevent timer duplicate initilisation
        if timer != nil {
            if timer.isValid{
                timer.invalidate()
            }
        }
    
        // Get HTML from player file in bundle
        let rawHTMLString = htmlStringWithFilePath(playerHTMLPath())!

        // Get JSON serialized parameters string
        let jsonParameters = serializedJSON(parameters)

        // Replace %@ in rawHTMLString with jsonParameters string
        let htmlString = rawHTMLString.replacingOccurrences(of: "%@", with: jsonParameters!)

        // Load HTML in web view
        webView.loadHTMLString(htmlString, baseURL: URL(string: "about:blank"))
    }

    fileprivate func playerHTMLPath() -> String {
         return Bundle(for: self.classForCoder).path(forResource: "YTPlayer", ofType: "html")!
    }

    fileprivate func htmlStringWithFilePath(_ path: String) -> String? {
        
        var htmlString : String?
        
        // Get HTML string from path and Check for error
        do {
            htmlString = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return htmlString! as String
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

    fileprivate func serializedJSON(_ data: YouTubePlayerParameters) -> String? {
        
        var jsonData: AnyObject!
        
        // Serialize json into NSData
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) as AnyObject!
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
        // Success, return JSON string
        return NSString(data: jsonData as! Data, encoding: String.Encoding.utf8.rawValue) as? String
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

                default:
                    break
            }
        }
    }


    // MARK: UIWebViewDelegate

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        let url = request.url
        
        // Check if ytplayer event, wait some time (timeTimeInterval) and, if so, pass to handleJSEvent and if not show can not load label
        if url!.scheme == "ytplayer" {
            if timer.isValid{
                timer.invalidate()
            }
            handleJSEvent(url!)
        }else if url?.absoluteString == "about:blank"{
            timer = Timer.scheduledTimer(timeInterval: Keys.timerTimeInterval, target: self, selector: Selector("update"), userInfo: nil, repeats: false)
        }
        return true
    }
    
    //show can not load warning if can not load in timerTimeInterval seconds
    func update(){
        actInd.stopAnimating()
        
        self.viewWithTag(1455)?.removeFromSuperview()
        self.viewWithTag(1454)?.removeFromSuperview()
        
        let label = UILabel(frame:CGRect(x: 0, y: 0, width: (self.viewWithTag(1453)?.frame.width)! / Keys.warningLabelFrameWidthRatio, height:((self.viewWithTag(1453)?.frame.height)! / Keys.warningLabelFrameHeightRatio)))
        label.center = (self.viewWithTag(1453)?.center)!
        label.font = UIFont(name: Keys.warningLabelTextFontType, size: Keys.warningLabelTextFontSize)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor(colorCode: Keys.warningLabelTextColor, alpha: 1.0)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = Keys.warningLabelText
        label.adjustsFontSizeToFitWidth = true
        label.tag = 1456
        self.viewWithTag(1453)?.addSubview(label)
    }
}

private func printLog(_ str: String) {
    print(" [YouTubePlayer] \(str)")
}

//input UIColor with colorCode
extension UIColor {
    convenience init(colorCode: String, alpha: Float = 1.0){
        let scanner = Scanner(string:colorCode)
        var color:UInt32 = 0;
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = CGFloat(Float(Int(color >> 16) & mask)/255.0)
        let g = CGFloat(Float(Int(color >> 8) & mask)/255.0)
        let b = CGFloat(Float(Int(color) & mask)/255.0)
        
        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}
