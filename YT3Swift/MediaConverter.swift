//
//  MediaConverter.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation

class MediaConverter {
    static let availableVideoFormats: [MediaExtension] = [.mp4, .m4v, .mov]
    static let availableAudioFormats: [MediaExtension] = [.aiff, .wav, .m4a, .mp3, .caf]
    
}

enum FormatType {
    case audio
    case video
}
