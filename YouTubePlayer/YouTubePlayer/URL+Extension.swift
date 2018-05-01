//
//  PlayerVars.swift
//  Pods-YoutubeTest
//
//  Created by Islam Qalandarov on 5/1/18.
//

import Foundation

extension URL {
    var youtubeID: String? {
        let rule = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: rule, options: .caseInsensitive)
        let range = NSRange(location: 0, length: absoluteString.count)
        guard let checkingResult = regex?.firstMatch(in: absoluteString, options: [], range: range) else { return nil }
        
        return (absoluteString as NSString).substring(with: checkingResult.range)
    }
    
    var queryParams: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems
            else {
                return [:]
        }
        
        var dict = [String: String]()
        
        for item in queryItems {
            dict[item.name] = item.value
        }
        
        return dict
    }
}
