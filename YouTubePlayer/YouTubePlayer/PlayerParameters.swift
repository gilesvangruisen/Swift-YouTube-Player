//
//  PlayerParameters.swift
//  Pods-YoutubeTest
//
//  Created by Islam Qalandarov on 5/1/18.
//

import Foundation

public class PlayerParameters: Encodable {
    
    var videoId: String? = nil
    
    private var playerVars = PlayerVars()
    
    // Hard-coded values
    private let height = "100%"
    private let width  = "100%"
    private let events = [
        "onReady": "onReady",
        "onStateChange": "onStateChange",
        "onPlaybackQualityChange": "onPlaybackQualityChange",
        "onError": "onPlayerError"
    ]
    
}

// Properties of the playerVars
extension PlayerParameters {
    
    var list: String? {
        get { return playerVars.list }
        set { playerVars.list = newValue }
    }
    
    public var playsInline: Bool {
        get { return playerVars.playsInline }
        set { playerVars.playsInline = newValue }
    }
    
    public var showInfo: Bool {
        get { return playerVars.showInfo }
        set { playerVars.showInfo = newValue }
    }
    
    public var showControls: Bool {
        get { return playerVars.showControls }
        set { playerVars.showControls = newValue }
    }
    
}
