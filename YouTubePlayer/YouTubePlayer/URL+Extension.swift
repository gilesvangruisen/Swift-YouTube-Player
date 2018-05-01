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
        guard let query = self.query else { return [:] }
        
        var dict = [String: String]()
        
        // Loop through pairings (separated by &)
        for pair in query.components(separatedBy: "&") {
            
            // Pull key, val from from pair parts (separated by =) and set dict[key] = value
            let components = pair.components(separatedBy: "=")
            if (components.count > 1) {
                dict[components[0]] = components[1]
            }
        }
        
        return dict
    }
}
