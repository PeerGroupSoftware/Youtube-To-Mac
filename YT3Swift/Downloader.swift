//
//  Downloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Foundation
import Cocoa

class Downloader {
    
    var isRunning = false
    var videoID = ""
    var videoTitle = ""
    var saveLocation = "~/Desktop"
    var currentVideo = YTVideo()
    private var outputPipe:Pipe!
    private var errorPipe:Pipe!
    private var downloadTask:Process!
    static let videoFormats = ["Auto", "mp4", "flv", "webm"]
    static let audioFormats = ["Auto", "m4a", "mp3", "wav", "aac"]
    private let defaultQOS = DispatchQoS.QoSClass.userInitiated
    
    /*func latestYTDLVersion() -> YoutubeDLVersion {
        return .version10
    }*/
    
    func downloadContent(with downloadRequest: YTDownloadRequest) {
        downloadContent(from: downloadRequest.contentURL, toLocation: downloadRequest.destination, audioOnly: downloadRequest.audioOnly, fileFormat: downloadRequest.fileFormat, progress: downloadRequest.progressHandler!, completionHandler: downloadRequest.completionHandler)
    }
    
    func terminateDownload() {
        downloadTask.terminate()
    }
    
    func downloadContent(from targetURL: String, toLocation downloadDestination: String, audioOnly: Bool, fileFormat: FileFormat, progress progressHandler: @escaping (Double, Error?, YTVideo?) -> Void, completionHandler: @escaping (YTVideo?) -> Void) {
        let downloaderVersion = YoutubeDLVersion.latest//latestYTDLVersion()
        currentVideo.URL = targetURL
        currentVideo.isAudioOnly = audioOnly
        
        isRunning = true
        let taskQueue = DispatchQueue.global(qos: defaultQOS)
        
        //taskQueue.async {
            taskQueue.async {
                
                let path = Bundle.main.path(forResource: downloaderVersion.rawValue, ofType: "sh")
               // print(path)
                self.downloadTask = Process()
                if #available(OSX 10.13, *) {
                    self.downloadTask.executableURL = URL(fileURLWithPath: path!)
                } else {
                    self.downloadTask.launchPath = path
                }
                print("using file format \(fileFormat.rawValue)")
                self.downloadTask.arguments = ["-v", "-f \(fileFormat.rawValue)", targetURL]
                self.downloadTask.currentDirectoryPath = downloadDestination
                /*if #available(OSX 10.13, *) {
                    self.downloadTask.currentDirectoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                } else {
                    // Fallback on earlier versions
                }*/
                //self.downloadTask.director
                if #available(OSX 10.13, *) {
                    //print(self.downloadTask.currentDirectoryURL)
                    //print(self.downloadTask.currentDirectoryPath)
                } else {
                    // Fallback on earlier versions
                }
                
                self.downloadTask.terminationHandler = {
                    
                    task in
                    DispatchQueue.main.async(execute: {
                        print("Stopped")
                        print(self.downloadTask.terminationReason.rawValue)
                        //self.updateDownloadProgressBar(progress: 0.0)
                        progressHandler(100, nil, nil)
                        completionHandler(self.currentVideo)
                        //self.toggleDownloadInterface(to: false)
                        self.currentVideo = YTVideo()
                        //self.URLField.stringValue = ""
                        if self.outputPipe.description.contains("must provide") {
                            print("error")
                        }
                        self.isRunning = false
                    })
                    
                }
                
                self.captureStandardOutput(self.downloadTask, progressHandler: {(percent) in
                    progressHandler(percent, nil, nil)
                }, errorHandler: {(error) in
                    progressHandler(100, error, self.currentVideo)
                }, infoHandler: {(videoInfo) in
                    progressHandler(-1, nil, videoInfo)
                })
                
                self.readError(self.downloadTask, errorHandler: {(error) in
                   progressHandler(100, error, self.currentVideo)
                })
                //self.toggleDownloadInterface(to: true)
                if #available(OSX 10.13, *) {
                    try! self.downloadTask.run()
                } else {
                    self.downloadTask.launch()
                }
                self.downloadTask.waitUntilExit()
                
            }
            
      //  }
    }
    
    private func readError(_ task:Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = self.errorPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            print("got error")
            print(outputString)
            
            if outputString.contains("requested format not available") {
                print("format not available")
                errorHandler(NSError(domain: "", code: 415, userInfo: [NSLocalizedDescriptionKey: "The requested format is not available for this content, please use the automatic format selection."]))
            } else if outputString.contains("who has blocked it on copyright grounds") {
                print("Video was blocked")
                errorHandler(NSError(domain: "", code: 451, userInfo: [NSLocalizedDescriptionKey: "The requested content was blocked on copyright grounds."]))
            } else if outputString.contains("writing DASH m4a") {
            } else if !outputString.isEmpty {
                //errorHandler(NSError(domain: "", code: 520, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured. Please file a bug report."]))
            }
            
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
        }
    }
    
    
    private func captureStandardOutput(_ task:Process, progressHandler: @escaping (Double) -> Void, errorHandler: @escaping (Error) -> Void, infoHandler: @escaping (YTVideo) -> Void) {
        
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            //print("got output")
            //print(outputString)
            
            /*if outputString.contains("fulltitle") {
                for i in (outputString.split(separator: ":")) {
                    (i.split(separator: ",").first?.replacingOccurrences(of: "\"", with: ""))
                }
            }*/
            if outputString.range(of:"100%: Done") != nil {
                self.downloadTask.qualityOfService = .background
                
                //   } else if outputString.contains("requested format not available") {
                
            } else if outputString.contains("has already been downloaded") {
                errorHandler(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "The requested content already exists at the download destination."]))
            } else if outputString.range(of:"must provide") != nil {
                print("There was some kind of error")
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    var videonameString = (outputString.replacingOccurrences(of: "[download] Destination: ", with: ""))
                   // print(videonameString)
                    
                    //print(videonameString.distance(from: (videonameString.range(of: ("-" + self.videoID))?.lowerBound)!, to: videonameString.endIndex))
                    
                    videonameString.removeSubrange((videonameString.range(of: ("-" + self.videoID))?.lowerBound)!..<videonameString.endIndex)
                    //self.videoTitle = (videonameString)
                    self.currentVideo.name = videonameString
                    DispatchQueue.main.async {
                        //self.URLField.stringValue = self.currentVideo.name
                        infoHandler(self.currentVideo)
                        print("adding name to field")
                    }
                } else {
                    print("download update")
                    for i in (outputString.split(separator: " ")) {
                        if i.contains("%") {
                            //self.updateDownloadProgressBar(progress:(Double(i.replacingOccurrences(of: "%", with: "")))!)
                            progressHandler((Double(i.replacingOccurrences(of: "%", with: "")))!)
                        }
                    }
                }
            } else if outputString.contains("[youtube]") && outputString.contains("Downloading webpage") {
                self.videoID = ((outputString.split(separator: " "))[1].replacingOccurrences(of: ":", with: ""))
            }
            
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
            
        }
    }
    
    func fetchJSON(from targetURL: URL, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let jsonRequest = URLRequest(url: targetURL)
        
        let task = URLSession.shared.dataTask(with: jsonRequest) { (data, response, error) in
            guard let dataResponse = data, error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                completion(nil, error)
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String : Any]
                completion(jsonResponse, error)
                
            } catch let parsingError {
                print("Error \(parsingError)")
                completion(nil, error)
            }
        }
        
        
        task.resume()
    }

    
}

enum YoutubeDLVersion: String {
    @available(*, deprecated) case version9 = "youtube-dl-2019-05-20"
    @available(*, deprecated) case version10 = "youtube-dl-2019-06-08"
    //case version11 = "youtube-dl-2019-06-08"
    case latest = "youtube-dl-2020-03-24"
}
