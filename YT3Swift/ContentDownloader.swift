//
//  ContentDownloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation
import AVFoundation

protocol ContentDownloaderDelegate {
    func didCompleteDownload(error: Int?)
    func downloadDidProgress(to downloadProgress: Double)
    func didGetVideoName(_ videoName: String)
}

protocol ContentDownloader {
    var delegate: ContentDownloaderDelegate? { get set }
    
    func download(content: String, with: MediaFormat, to: URL, completion: @escaping (URL) -> Void)
    func terminateDownload()
    
}

struct MediaFormat {
    var fileExtension: MediaExtension
    var size: NSSize?
    var videoCodec: YTCodec?
    var audioCodec: YTCodec?
    var audioOnly: Bool = false
    var sizeString: String?
    var fps: Int?
}

enum YTCodec: String, CaseIterable {
    case mp4a = "mp4a"
    case opus = "opus"
    case vp9 = "vp9"
    case avc1 = "avc1"
    case av01 = "av01"
}
/*enum MediaExtension {
    case mp4
    case wav
    case flv
    case webm
    case m4a
    case mp3
    case aac
}*/

let downloadErrors =  [
    400 : "The provided URL is invalid.",
    403 : "The requested content has not yet premiered. Please try again once this content has been made available.",
    404 : "An error occured getting the video information. Please try again.",
    409 : "The requested content already exists at the download destination.",
    415 : "The requested format is not available for this content, please use the automatic format selection.",
    451 : "The requested content was blocked on copyright grounds."
    
]
