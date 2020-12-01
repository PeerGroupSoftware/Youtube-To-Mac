//
//  YTDownloadRequest.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Foundation

class YTDownloadRequest {
    var destination: URL = Downloader.desktopFolder //"~/Desktop"
    var contentURL = ""
    var audioOnly: Bool = false
    var fileFormat = MediaExtension.auto // Default video file format
    var directFormats: [MediaFormat] = []
    var progressHandler: ((Double, Error?, YTVideo?) -> Void)!
    var completionHandler: ((YTVideo?, Error?) -> Void)!
    var error: Error?
    
    convenience init(contentURL: String, destination: URL) {
        self.init()
        self.contentURL = contentURL
        self.destination = destination
    }
    
    convenience init(contentURL: String) {
        self.init()
        self.contentURL = contentURL
    }
}

enum MediaExtension: String {
    case mp4 = "mp4"
    case flv = "flv"
    case webm = "webm"
    case m4a = "m4a"
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"
    case mov = "mov"
    case m4v = "m4v"
    case aiff = "aiff"
    case caf = "caf"
    case auto
}
