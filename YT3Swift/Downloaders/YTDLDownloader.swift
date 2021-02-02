//
//  YTDLDownloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation

class YTDLDownloader: ContentDownloader {
    var delegate: ContentDownloaderDelegate?
    private var outputPipe:Pipe!
    private var errorPipe:Pipe!
    private var downloadTask:Process!
    private let downloadQOS: DispatchQoS.QoSClass  = .userInitiated
    static let executableName = "youtube-dl-2021-01-24-1"
    
    private var videoName = ""
    //private var cachedVideo = YTVideo()
    
    // If an error contains the string, the error matching the code is called
    private let errors: [(String, Int)] = [
        ("requested format not available", 415),
        ("has already been downloaded", 409),
        ("Premieres in", 403),
        ("This live event will begin in", 403),
        ("who has blocked it on copyright grounds", 451),
        ("is not a valid URL", 400),
        ("Unable to extract video data",404)
    ]
    
    var isRunning = false
    
    func download(content targetURL: String, with targetFormat: MediaFormat, to downloadDestination: URL, completion: @escaping (YTVideo?, URL) -> Void) {
        let downloadQueue = DispatchQueue.global(qos: downloadQOS)
        var needsToMerge = false
        
        downloadQueue.async {
            
            let executablePath = Bundle.main.path(forResource: YTDLDownloader.executableName, ofType: "sh")
            self.downloadTask = Process()
            
            if #available(OSX 10.13, *) {
                self.downloadTask.executableURL = URL(fileURLWithPath: executablePath!)
            } else {
                self.downloadTask.launchPath = executablePath
            }
            //print("USING EXTENSION \(targetFormat.fileExtension)")
            
            var requestedExtension = targetFormat.fileExtension.rawValue
            
            if targetFormat.fileExtension == .auto {
                if targetFormat.audioOnly {
                    requestedExtension = "bestaudio"//"wav/m4a/mp3/bestaudio"
                } else {
                    requestedExtension = "mp4/flv/best"
                }
            }
            print("TF: \(targetFormat)")
            if !(targetFormat.sizeString?.isEmpty ?? true) {
                if targetFormat.fileExtension == .auto {
                    requestedExtension = "bestvideo"
                }
                requestedExtension += "[height=\(targetFormat.sizeString?.dropLast() ?? "720")]"
            }
            
            if targetFormat.videoOnly {
                print("Video only, will need to merge audio+video")
                needsToMerge = true
                requestedExtension += "+bestaudio[ext=m4a]"
            }
            
            print("RequestedFormat: \(requestedExtension)")
            
           /* var videoNameString = "%(title)s"
            
            if !(AppStateManager.shared.currentRequest.videoTitle?.isEmpty ?? true) && (AppStateManager.shared.currentRequest.contentURL == targetURL) {
                videoNameString = AppStateManager.shared.currentRequest.videoTitle!
            }*/
            
            self.downloadTask.arguments = ["-f \(requestedExtension)", "-o%(title)s.%(ext)s", targetURL]
            print(downloadDestination.absoluteString)
            self.downloadTask.currentDirectoryPath = downloadDestination.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            self.downloadTask.terminationHandler = { task in
                DispatchQueue.main.async(execute: {
                    self.isRunning = false
                    
                    if needsToMerge {
                        let videoFile = downloadDestination.appendingPathComponent(self.videoName).appendingPathExtension(targetFormat.fileExtension.rawValue)
                        let audioFile =  downloadDestination.appendingPathComponent(self.videoName.replacingOccurrences(of: ".f" + String(targetFormat.id ?? 0), with: "")).appendingPathExtension("f" + String(targetFormat.secondaryFormatID ?? 0)).appendingPathExtension("m4a")
                        
                        print(videoFile, targetFormat.id)
                        print(audioFile, targetFormat.secondaryFormatID)
                        
                        MediaConverter().merge(audioURL: audioFile, videoURL: videoFile, withFormat: targetFormat) { (fileLocation, error) in
                            completion(YTVideo(name: self.videoName, url: targetURL), downloadDestination.appendingPathComponent(self.videoName, isDirectory: false).appendingPathExtension(targetFormat.fileExtension.rawValue))
                        }
                    } else {
                    
                        completion(YTVideo(name: self.videoName, url: targetURL), downloadDestination.appendingPathComponent(self.videoName, isDirectory: false).appendingPathExtension(targetFormat.fileExtension.rawValue))
                    }
                })
                
            }
            
            // Set up output processing for the task
            self.registerOutputHandlers(for: self.downloadTask, progressHandler:
            {(percent) in
                if self.delegate != nil {
                    self.delegate?.downloadDidProgress(to: percent)
                }
            }, errorHandler: {(error) in
                
                //progressHandler(100, error, self.currentVideo)
            })
            
            // Set up error handling for the download task
            self.registerErrorHandlers(for: self.downloadTask, errorHandler:
            {(error) in
                #if DEBUG
//                    print(error) //Debug
                #endif
                if self.delegate != nil {
                    self.delegate?.downloadDidProgress(to: 100)
                }
            })
            
            //Launch the task
            if #available(OSX 10.13, *) {
                try! self.downloadTask.run()
                print("Started download")
            } else {
                self.downloadTask.launch()
                print("Started download")
            }
            self.downloadTask.waitUntilExit()
            
        }
    }
    
    func terminateDownload() {
        downloadTask.terminate()
    }
    
    private func registerOutputHandlers(for task:Process, progressHandler: @escaping (Double) -> Void, errorHandler: @escaping (Error) -> Void/*, infoHandler: @escaping (YTVideo) -> Void*/) {
        
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            #if DEBUG
                print(outputString)
            #endif
            
            if outputString.contains("has already been downloaded") {
                self.stopDownload(withError: 409)
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    var videonameString = (outputString.components(separatedBy: "\n").first! .replacingOccurrences(of: "[download] Destination: ", with: ""))
                    videonameString.removeLast(4) // Remove extension // This should probably be made better, don't assume extension length
                    if self.delegate != nil {
                        self.delegate?.didGetVideoName(videonameString)
                        self.videoName = videonameString
                    }
                    print(videonameString)
                } else {
                    print("download update")
                    for i in (outputString.split(separator: " ")) {
                        if i.contains("%") {
                            if self.delegate != nil {
                                self.delegate?.downloadDidProgress(to: (Double(i.replacingOccurrences(of: "%", with: "")))!)
                            }
                        }
                    }
                }
            } else if outputString.contains("[youtube]") && outputString.contains("Downloading webpage") {
                print((outputString.split(separator: " "))[1].replacingOccurrences(of: ":", with: ""))
            }
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
        
    }
    
    private func registerErrorHandlers(for task:Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) { notification in
            
            let errorData = self.errorPipe.fileHandleForReading.availableData
            let errorString = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
            
            #if DEBUG
                print(errorString)
            #endif
            
            if !errorString.isEmpty {
                print("ERROR: \(errorString)")
                
                for error in self.errors {
                    if errorString.contains(error.0) {
                        self.stopDownload(withError: error.1)
                    }
                }
            }
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    func stopDownload(withError downloadError: Int?) {
        downloadTask.terminate()
        if self.delegate != nil {
            self.delegate?.didCompleteDownload(error: downloadError)
        }
    }
    
    
}
