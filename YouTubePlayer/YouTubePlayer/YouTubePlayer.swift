//
//  VideoPlayerView.swift
//  YouTubePlayer
//
//  Created by Giles Van Gruisen on 12/21/14.
//  Copyright (c) 2014 Giles Van Gruisen. All rights reserved.
//

import WebKit

public enum YouTubeError: Error {
    case internalError(Int)
    case unknownValue

    var debugDescription: String {
        switch self {
        case .internalError(let code): return "YouTube encounterred an error with code '\(code)'."
        case .unknownValue: return "Unrecognized YouTube command."
        }
    }
}

public enum YouTubeCommand {
    case playerReady
    case error(PlayerErrorCommand)
    case playerStateChanged(PlayerStateChangeCommand)
    case playbackQualityChange(PlaybackQualityChangeCommand)
}

public struct PlayerErrorCommand: Codable {
    let exception: Int
}

public struct PlaybackQualityChangeCommand: Codable {
    let quality: YouTubePlaybackQuality
}

public struct PlayerStateChangeCommand: Codable {
    let state: YouTubePlayerState
}

private struct YouTubeJsCommand: Decodable {
    let command: YouTubeCommand

    private enum CodingKeys: String, CodingKey {
        case command
        case data
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let commandString = try values.decode(String.self, forKey: .command)

        switch commandString {
        case "onReady":
            command = .playerReady
        case "onPlayerError":
            let data = try values.decode(PlayerErrorCommand.self, forKey: .data)
            command = .error(data)
        case "onPlaybackQualityChange":
            let data = try values.decode(PlaybackQualityChangeCommand.self, forKey: .data)
            command = .playbackQualityChange(data)
        case "onPlayerStateChange":
            let data = try values.decode(PlayerStateChangeCommand.self, forKey: .data)
            command = .playerStateChanged(data)
        default:
            throw YouTubeError.unknownValue
        }
    }
}

public enum YouTubePlayerState: Int, Codable {
    case Unstarted = -1
    case Ended = 0
    case Playing = 1
    case Paused = 2
    case Buffering = 3
    case Queued = 5
}

public enum YouTubePlaybackQuality: String, Codable {
    case Small = "small"
    case Medium = "medium"
    case Large = "large"
    case HD720 = "hd720"
    case HD1080 = "hd1080"
    case HighResolution = "highres"
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
                    dict[components[0]] = components[1]
                }
            }
        }

        return dict
    }
}

public protocol YouTubePlayerDelegate: class {
    func playerReady(_ videoPlayer: YouTubePlayerView)
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState)
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality)
    func playerEncounteredAnError(_ videoPlayer: YouTubePlayerView, error: Error)
}

open class YouTubePlayerView: WKWebView {
    public typealias YouTubePlayerParameters = [String: Any]

    /** The readiness of the player */
    public fileprivate(set) var ready = false

    /** The current state of the video player */
    public fileprivate(set) var playerState = YouTubePlayerState.Unstarted

    /** The current playback quality of the video player */
    public fileprivate(set) var playbackQuality = YouTubePlaybackQuality.Small

    /** Used to configure the player */
    open var playerVars: YouTubePlayerParameters = ["controls": 0]

    open weak var delegate: YouTubePlayerDelegate?

    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        // https://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
        configuration.userContentController.add(LeakAvoider(delegate: self), name: "callback")
    }

    deinit {
        print("YouTubePlayerView: deinit called.")
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configuration.userContentController.add(LeakAvoider(delegate: self), name: "callback")
    }

    private func evaluatePlayerCommand(_ command: String, completion: ((Double) -> Void)? = nil) {
        let fullCommand = "player." + command + ";"
        self.evaluateJavaScript(fullCommand) { (result, error) in
            if let error = error {
                print("YouTubePlayerView: Failed evaluating JS command with error: '\(error)'.")
            }
            guard let response = result, let seconds = response as? Double else { return }
            guard let completion = completion else { return }
            completion(seconds)
        }
    }

    private func playerCallbacks() -> YouTubePlayerParameters {
        return [
            "onReady": "onPlayerReady",
            "onStateChange": "onPlayerStateChange",
            "onPlaybackQualityChange": "onPlaybackQualityChange",
            "onError": "onPlayerError"
        ]
    }

    private func playerParameters() -> YouTubePlayerParameters {
        return [
            "height": "100%",
            "width": "100%",
            "events": self.playerCallbacks(),
            "playerVars": self.playerVars
        ]
    }

    public func videoIdFromYouTubeUrl(_ videoUrl: URL) -> String? {
        if videoUrl.pathComponents.count > 1 && (videoUrl.host?.hasSuffix("youtu.be"))! {
            return videoUrl.pathComponents[1]
        } else if videoUrl.pathComponents.contains("embed") {
            return videoUrl.pathComponents.last
        }
        return videoUrl.queryStringComponents()["v"] as? String
    }

    public func loadVideoUrl(_ videoURL: URL) {
        if let videoId = self.videoIdFromYouTubeUrl(videoURL) {
            self.loadVideoId(videoId)
        }
    }

    private func htmlStringWithFilePath(_ path: String) -> String? {
        do {
            // Get HTML string from path
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch let error {
            // Error fetching HTML
            print("YouTubePlayerView: Failed loading HTML with error '\(error)'.")
            return nil
        }
    }

    private func playerHtmlPath() -> String {
        return Bundle(for: YouTubePlayerView.self).path(forResource: "YTPlayer", ofType: "html")!
    }

    private func serializedJSON(_ object: Any) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)

            return String(data: jsonData, encoding: .utf8)
        } catch let jsonError {
            print("YouTubePlayerView: Failed serializing parameters with error '\(jsonError)'.")
            return nil
        }
    }

    private func loadWebViewWithParameters(_ parameters: YouTubePlayerParameters) {
        // Get HTML from player file in bundle
        let rawHtmlString = self.htmlStringWithFilePath(playerHtmlPath())!

        // Get JSON serialized parameters string
        let jsonParameters = self.serializedJSON(parameters)!

        // Replace %@ in rawHtmlString with jsonParameters string
        let htmlString = rawHtmlString.replacingOccurrences(of: "%@", with: jsonParameters)

        // Load HTML in web view
        self.loadHTMLString(htmlString, baseURL: URL(string: "about:blank"))
    }

    public func loadVideoId(_ videoId: String) {
        var playerParams = playerParameters()
        playerParams["videoId"] = videoId

        self.loadWebViewWithParameters(playerParams)
    }

    public func loadPlaylistId(_ playlistID: String) {
        // No videoId necessary when listType = playlist, list = [playlist Id]
        self.playerVars["listType"] = "playlist" as AnyObject?
        self.playerVars["list"] = playlistID as AnyObject?

        self.loadWebViewWithParameters(playerParameters())
    }
}

// MARK: Player controls
public extension YouTubePlayerView {
    func mute() {
        self.evaluatePlayerCommand("mute()")
    }

    func unMute() {
        self.evaluatePlayerCommand("unMute()")
    }

    func play() {
        self.evaluatePlayerCommand("playVideo()")
    }

    func pause() {
        self.evaluatePlayerCommand("pauseVideo()")
    }

    func stop() {
        self.evaluatePlayerCommand("stopVideo()")
    }

    func destroy() {
        self.evaluatePlayerCommand("destroy()")
        self.configuration.userContentController.removeScriptMessageHandler(forName: "callback")
    }

    func seekTo(_ seconds: Float, seekAhead: Bool) {
        self.evaluatePlayerCommand("seekTo(\(seconds), \(seekAhead))")
    }

    func getDuration(completion: @escaping((Double) -> Void)) {
        self.evaluatePlayerCommand("getDuration()") { (response) in
            completion(response)
        }
    }

    func getCurrentTime(completion: @escaping((Double) -> Void)) {
        self.evaluatePlayerCommand("getCurrentTime()") { (response) in
            completion(response)
        }
    }
}

// MARK: Playlist controls
public extension YouTubePlayerView {
    func previousVideo() {
        self.evaluatePlayerCommand("previousVideo()")
    }

    func nextVideo() {
        self.evaluatePlayerCommand("nextVideo()")
    }
}

// MARK: - WKScriptMessageHandler
extension YouTubePlayerView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let commandString = message.body as? String else { fatalError("YouTubePlayerView: Unknown YouTube command!") }
        do {
            let jsCommand = try JSONDecoder().decode(YouTubeJsCommand.self, from: Data(commandString.utf8))
            print("YouTubePlayerView: Received chat command: '\(jsCommand.command)'.")
            switch jsCommand.command {
            case .playerReady:
                self.ready = true
                self.delegate?.playerReady(self)
            case .error(let errorCommand):
                self.delegate?.playerEncounteredAnError(self, error: YouTubeError.internalError(errorCommand.exception))
            case .playerStateChanged(let stateCommand):
                self.playerState = stateCommand.state
                self.delegate?.playerStateChanged(self, playerState: stateCommand.state)
            case .playbackQualityChange(let qualityCommand):
                self.playbackQuality = qualityCommand.quality
                self.delegate?.playerQualityChanged(self, playbackQuality: qualityCommand.quality)
            }
        } catch let error {
            print("YouTubePlayerView: Failed decoding YouTubeJsCommand with error: '\(error)'.")
        }
    }
}
