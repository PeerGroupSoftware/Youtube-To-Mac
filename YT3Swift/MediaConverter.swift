//
//  MediaConverter.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation
import AVFoundation

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
    
}

enum FormatType {
    case audio
    case video
}
