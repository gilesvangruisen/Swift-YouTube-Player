//
//  PlayerVars.swift
//  Pods-YoutubeTest
//
//  Created by Islam Qalandarov on 5/1/18.
//

import Foundation

struct PlayerVars: Encodable {
    var playsInline: Bool {
        get { return playsinline.boolValue }
        set { playsinline = newValue.stringValue }
    }
    
    var showInfo: Bool {
        get { return showinfo.boolValue }
        set { showinfo = newValue.stringValue }
    }
    
    var showControls: Bool {
        get { return controls.boolValue }
        set { controls = newValue.stringValue }
    }
    
    var list: String? = nil {
        didSet { listType = "playlist" }
    }
    
    // The variables that will be encoded
    private var playsinline = false.stringValue
    private var showinfo = false.stringValue
    private var controls = false.stringValue
    private var listType: String? = nil
}

private extension String {
    var boolValue: Bool {
        return self == "1"
    }
}

private extension Bool {
    var stringValue: String {
        return self ? "1" : "0"
    }
}
