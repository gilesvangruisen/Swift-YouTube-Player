//
//  LeakAvoider.swift
//  YouTubePlayer
//
//  Created by Piotr Panasewicz on 26/04/2020.
//  Copyright © 2020 Piotr Panasewicz. All rights reserved.
//

import WebKit

class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}
