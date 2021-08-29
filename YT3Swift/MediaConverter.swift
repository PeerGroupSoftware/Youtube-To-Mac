//
//  MediaConverter.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2021 Peer Group Software. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class MediaConverter {
    private let temporaryFolder = FileManager.default.temporaryDirectory
    
    static let availableVideoFormats: [MediaExtension] = [.mp4, .m4v, .mov]
    static let availableAudioFormats: [MediaExtension] = [.aiff, .wav, .m4a, .mp3, .caf]
    
    /*func makeTempFolder() {
        if !FileManager.default.fileExists(atPath: temporaryFolder.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: temporaryFolder, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error)
            }
        }
    }*/
    
    func convert(videoAt fileLocation: URL, withID videoID: String, to outFileType: MediaExtension, destination: URL?, completion: @escaping (Error?) -> Void) {
        
        var outFormat: AVFileType!
        
        switch outFileType {
        case .mp4:
            outFormat = .mp4
        case .wav:
            outFormat = .wav
        case .mov:
            outFormat = .mov
        case .m4a:
            outFormat = .m4a
        case .mp3:
            outFormat = .mp3
        case .m4v:
            outFormat = .m4v
        case .aiff:
            outFormat = .aiff
        case .caf:
            outFormat = .caf
        default:
            print("Not using any file format. This will likely crash")
            break
        }
        print("Starting conversion from \(fileLocation.pathExtension) to \(outFileType.rawValue)")
        print("\(fileLocation) to \(destination)")
        
        
        let anAsset = AVAsset(url: fileLocation)
        let outputURL = temporaryFolder.appendingPathComponent(videoID).appendingPathExtension(outFileType.rawValue)
        
        let preset = AVAssetExportPresetHighestQuality
        
        
        AVAssetExportSession.determineCompatibility(ofExportPreset: preset,
                                                    with: anAsset, outputFileType: outFormat) { isCompatible in
            guard isCompatible else { print("Not compatible"); return }
            
            guard let exportSession = AVAssetExportSession(asset: anAsset,
                                                           presetName: preset) else { return }
            exportSession.outputFileType = outFormat
            exportSession.outputURL = outputURL
            exportSession.exportAsynchronously {
                do {
                    var outputDestination: URL!
                    if destination != nil {
                        outputDestination = destination!.appendingPathComponent(fileLocation.lastPathComponent).deletingPathExtension().appendingPathExtension(outFileType.rawValue)
                        print("MC1: \(outputDestination.absoluteString)")
                    } else {
                        if !outputDestination.hasDirectoryPath {
                        outputDestination = fileLocation.deletingPathExtension().appendingPathExtension(outFileType.rawValue)
                        } else {
                            print("MC0: \(fileLocation)")
                            print("MC1: \(fileLocation.lastPathComponent)")
                            outputDestination = fileLocation.deletingPathExtension().appendingPathExtension(outFileType.rawValue)
                        }
                        
                    }
                    print("MC2: \(outputDestination.absoluteString)")
                     /*if outputDestination.hasDirectoryPath {
                         outputDestination.appendPathComponent(fileLocation.lastPathComponent, isDirectory: false)
                     }
                    print("MC3: \(outputDestination.absoluteString)")*/
                    
                    try FileManager.default.moveItem(at: outputURL, to: outputDestination)
                    try FileManager.default.removeItem(at: fileLocation)
                    completion(nil)
                } catch {
                    print(error)
                    completion(error)
                }
            }
        }
    }
    
    func merge(audioURL: URL, videoURL: URL, withFormat targetFormat: MediaFormat?, completion: @escaping (URL?, Error?) -> Void) {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()


        //start merge

        let aVideoAsset : AVAsset = AVAsset(url: videoURL)
        let aAudioAsset : AVAsset = AVAsset(url: audioURL)
        
        if aVideoAsset.tracks.isEmpty || aAudioAsset.tracks.isEmpty {
            
            if aVideoAsset.tracks.isEmpty {
                print("Video tracks is empty")
            }
            if aAudioAsset.tracks.isEmpty {
                print("Audio tracks is empty")
            }
            
            print("Either video or audio tracks is empty")
            completion(nil, NSError())
            return
        }

        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)

        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]



        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)

            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)

        } catch {
            print(error)
        }

        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration )

        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(targetFormat?.fps ?? 60))

        //print("TF2: \(targetFormat)")
        mutableVideoComposition.renderSize = CGSize(width: targetFormat?.size?.width ?? 1280 ,height: targetFormat?.size?.height ?? 720)

        let savePathUrl = videoURL.deletingPathExtension().deletingPathExtension().appendingPathExtension(videoURL.pathExtension)
        //print("SavePathURL: \(savePathUrl)")

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {

            case AVAssetExportSession.Status.completed:
                print("success")
                completion(videoURL, nil)
                do {
                    try FileManager.default.removeItem(at: videoURL)
                    try FileManager.default.removeItem(at: audioURL)
                } catch {
                    print(error)
                }
            case  AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error)")
                completion(nil, assetExport.error)
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error)")
                completion(nil, assetExport.error)
            default:
                print("complete")
            }
        }
    }
    
}

enum FormatType {
    case audio
    case video
}
