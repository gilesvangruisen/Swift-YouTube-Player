//
//  PlayerVars.swift
//  Pods-YoutubeTest
//
//  Created by Islam Qalandarov on 5/1/18.
//

import Foundation

public enum PlayerError: String, Error {
    case invalidParameter = "2"
    case html5Error = "5"
    case videoNotFound = "100"
    case embeddingNotAllowed = "101"
    case embeddingNotAllowedInDisguise = "105"
    case unexpected
}

extension PlayerError: LocalizedError {
    public var errorDescription: String? {
        // Error messages are taken from https://developers.google.com/youtube/iframe_api_reference#onError
        switch self {
        case .invalidParameter:
            return "Incorrect video or playlist id."
        case .html5Error:
            return "The content cannot be played using this player."
        case .videoNotFound:
            return "The video requested was not found: it's either removed or made private."
        case .embeddingNotAllowed, .embeddingNotAllowedInDisguise:
            return "The owner of the requested video does not allow it to be played in embedded players"
        case .unexpected:
            return "Unexpected request error."
        }
    }
}
