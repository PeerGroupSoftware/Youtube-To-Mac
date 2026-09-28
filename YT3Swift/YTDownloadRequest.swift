//
//  YTDownloadRequest.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2026 Peer Group Software. All rights reserved.
//

import Foundation

class YTDownloadRequest {
    var destination = "~/Desktop"
    var contentURL = ""
    var audioOnly: Bool = false
    var fileFormat = FileFormat.defaultVideo
    var progressHandler: ((Double, Error?, YTVideo?) -> Void)!
    var completionHandler: ((YTVideo?, Error?) -> Void)!
    var error: Error?

    convenience init(contentURL: String, destination: String) {
        self.init()
        self.contentURL = contentURL
        self.destination = destination
    }

    convenience init(contentURL: String) {
        self.init()
        self.contentURL = contentURL
    }

    /// Absolute, tilde-expanded destination directory.
    var expandedDestination: String {
        (destination as NSString).expandingTildeInPath
    }
}

/// Download / conversion format requested by the UI.
enum FileFormat: String {
    // Video
    case defaultVideo = "bestvideo*+bestaudio/best"
    case best1080 = "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"
    case best720 = "bestvideo[height<=720]+bestaudio/best[height<=720]/best"
    case best480 = "bestvideo[height<=480]+bestaudio/best[height<=480]/best"
    case mp4 = "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b"
    case webm = "bv*[ext=webm]+ba[ext=webm]/b[ext=webm]/b"

    // Audio (used with -x --audio-format)
    case defaultAudio = "bestaudio/best"
    case m4a = "m4a"
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"

    var isAudioConversionFormat: Bool {
        switch self {
        case .m4a, .mp3, .wav, .aac:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .defaultVideo, .defaultAudio:
            return "Auto"
        case .best1080:
            return "1080p"
        case .best720:
            return "720p"
        case .best480:
            return "480p"
        case .mp4, .webm, .m4a, .mp3, .wav, .aac:
            return rawValue
        }
    }

    static func fromDisplayName(_ name: String, audioOnly: Bool) -> FileFormat {
        switch name {
        case "Auto":
            return audioOnly ? .defaultAudio : .defaultVideo
        case "1080p":
            return .best1080
        case "720p":
            return .best720
        case "480p":
            return .best480
        case "mp4":
            return .mp4
        case "webm":
            return .webm
        case "m4a":
            return .m4a
        case "mp3":
            return .mp3
        case "wav":
            return .wav
        case "aac":
            return .aac
        default:
            return audioOnly ? .defaultAudio : .defaultVideo
        }
    }
}
