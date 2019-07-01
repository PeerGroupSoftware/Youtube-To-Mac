//
//  YTDownloadRequest.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Foundation

class YTDownloadRequest {
    var destination = "~/Desktop"
    var contentURL = ""
    var audioOnly: Bool = false
    var fileFormat = FileFormat.defaultVideo // Default video file format
    var progressHandler: ((Double, Error?, YTVideo?) -> Void)!
    
    convenience init(contentURL: String, destination: String) {
        self.init()
        self.contentURL = contentURL
        self.destination = destination
    }
    
    convenience init(contentURL: String) {
        self.init()
        self.contentURL = contentURL
    }
}

enum FileFormat: String {
    case mp4 = "mp4"
    case defaultAudio = "wav/m4a/mp3/bestaudio"
    case defaultVideo = "mp4/flv/best"
}
