//
//  YTVideo.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation

class YTVideo {
    var title = ""
    var url = ""
    var diskPath = ""
    var isAudioOnly = false
    var availableFormats: [MediaExtension] = []
    
    convenience init(name: String) {
        self.init()
        self.title = name
    }
    
    convenience init(name: String, url: String) {
        self.init()
        self.title = name
        self.url = url
        
    }
}
