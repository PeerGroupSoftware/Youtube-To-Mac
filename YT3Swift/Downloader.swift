//
//  Downloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2021 Peer Group Software. All rights reserved.
//

import Foundation
import Cocoa

class Downloader {
    
    var isRunning = false
    var videoID = ""
    var videoTitle = ""
    var saveLocation = "~/Desktop"
    var currentVideo = YTVideo()
    var cachedRequest: YTDownloadRequest?
    private var outputPipe:Pipe!
    private var errorPipe:Pipe!
    private var downloadTask:Process!
    static let videoFormats = ["Auto", "mp4", "flv", "webm"]
    static let audioFormats = ["Auto", "m4a", "mp3", "wav", "aac"]
    private let defaultQOS: DispatchQoS.QoSClass  = .userInitiated
    
    func downloadContent(with downloadRequest: YTDownloadRequest) {
        downloadContent(from: downloadRequest.contentURL, toLocation: downloadRequest.destination, audioOnly: downloadRequest.audioOnly, fileFormat: downloadRequest.fileFormat, progress: downloadRequest.progressHandler!, completionHandler: downloadRequest.completionHandler)
        
        cachedRequest = downloadRequest
    }
    
    func terminateDownload() {
        downloadTask.terminate()
    }
    
    func downloadContent(from targetURL: String, toLocation downloadDestination: String, audioOnly: Bool, fileFormat: FileFormat, progress progressHandler: @escaping (Double, Error?, YTVideo?) -> Void, completionHandler: @escaping (YTVideo?, Error?) -> Void) {

        let downloaderVersion = YoutubeDLVersion.latest
        currentVideo.URL = targetURL
        currentVideo.isAudioOnly = audioOnly
        
        isRunning = true
        let taskQueue = DispatchQueue.global(qos: defaultQOS)
        
        
        
        taskQueue.async {
            
            let path = Bundle.main.path(forResource: downloaderVersion.rawValue, ofType: "sh")
            self.downloadTask = Process()
            //self.downloadTask.environment?["python"] = "/usr/bin/python3"
            if #available(OSX 10.13, *) {
                self.downloadTask.executableURL = URL(fileURLWithPath: path!)
            } else {
                self.downloadTask.launchPath = path
            }
            print("using file format \(fileFormat.rawValue)")
            self.downloadTask.arguments = ["-f \(fileFormat.rawValue)", "-o%(title)s.%(ext)s", targetURL]
            self.downloadTask.currentDirectoryPath = downloadDestination
            
            self.downloadTask.terminationHandler = {
                
                task in
                print("Stopped")
                let terminationReason = self.downloadTask.terminationReason.rawValue
                progressHandler(100, nil, nil)
                if terminationReason == 2 {
                    completionHandler(self.currentVideo,NSError(domain: "", code: 499, userInfo: [NSLocalizedDescriptionKey: "Cancelled Task"]))
                } else {
                    completionHandler(self.currentVideo, nil)
                }
                self.currentVideo = YTVideo()
                if self.outputPipe != nil {
                    if self.outputPipe.description.contains("must provide") {
                        print("error")
                    }
                }
                
                self.isRunning = false
            }
            
            //if !audioOnly {
            //print("GETTING STANDARD OUTPUT")
            self.captureStandardOutput(self.downloadTask, progressHandler: {(percent) in
                progressHandler(percent, nil, nil)
            }, errorHandler: {(error) in
                if self.cachedRequest != nil {
                    self.cachedRequest?.error = error
                }
                
                progressHandler(100, error, self.currentVideo)
            }, infoHandler: {(videoInfo) in
                progressHandler(-1, nil, videoInfo)
                //print("SENT \"\(videoInfo.name)\"")
            })
            
            // if !audioOnly {
            //print("GETTING ERROR")
            self.readError(self.downloadTask, errorHandler: {(error) in
                progressHandler(100, error, self.currentVideo)
            })
            // }
            
            if #available(OSX 10.13, *) {
                try! self.downloadTask.run()
            }
            //print("THREAD: \(Thread.current.name)")
            self.downloadTask.waitUntilExit()
            
        }
        
        /*  } else {
         print("Can't start download, task is already running")
         }*/
    }
    
    private func readError(_ task:Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        
        //print ("ERROR FUNC 2")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) {
            notification in
            print ("ERROR FUNC")
            
            let output = self.errorPipe.fileHandleForReading.availableData
            let errorString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            
            if !errorString.isEmpty {
                print("got error")
                print("ERROR: \(errorString)")
                
                if errorString.contains("requested format not available") {
                    print("format not available")
                    self.sendFatalError(error: NSError(domain: "", code: 415, userInfo: [NSLocalizedDescriptionKey: "The requested format is not available for this content, please use the automatic format selection."]), handler: errorHandler)
                    
                } else if errorString.contains("Premieres in") {
                    self.sendFatalError(error: NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "The requested content has not yet premiered. Please try again once this content has been made available."]), handler: errorHandler)
                    
                } else if errorString.contains("This live event will begin in") {
                    self.sendFatalError(error: NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "The requested content has not yet premiered. Please try again once this content has been made available."]), handler: errorHandler)
                } else if errorString.contains("who has blocked it on copyright grounds") {
                    print("Video was blocked")
                    self.sendFatalError(error: NSError(domain: "", code: 451, userInfo: [NSLocalizedDescriptionKey: "The requested content was blocked on copyright grounds."]), handler: errorHandler)
                } else if errorString.contains("is not a valid URL") {
                    self.sendFatalError(error: NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid."]), handler: errorHandler)
                    
                } else if errorString.contains("Unable to extract video data") {
                    self.sendFatalError(error: NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid."]), handler: errorHandler)
                } else if errorString.contains("env: python: No such file or directory") {
                    self.sendFatalError(error: NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "The python installation could not be found"]), handler: errorHandler)
                } else if !errorString.isEmpty {
                    //errorHandler(NSError(domain: "", code: 520, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured. Please file a bug report."]))
                }
                
                self.errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                
            }
        }
    }
    
    func sendFatalError(error: Error, handler: @escaping (Error) -> Void) {
        if self.cachedRequest != nil {
            self.cachedRequest?.error = error
        }
        handler(error)
        
    }
    
    
    private func captureStandardOutput(_ task:Process, progressHandler: @escaping (Double) -> Void, errorHandler: @escaping (Error) -> Void, infoHandler: @escaping (YTVideo) -> Void) {
        
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            //print ("OUTPUT FUNC")
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            //print("got output")
            //print(outputString)
            
            if outputString.range(of:"100%: Done") != nil {
                self.downloadTask.qualityOfService = .background
                
                //   } else if outputString.contains("requested format not available") {
                
            } else if outputString.contains("has already been downloaded") {
                errorHandler(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "The requested content already exists at the download destination."]))
            } else if outputString.range(of:"must provide") != nil {
                print("There was some kind of error")
                
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    var videonameString = (outputString.components(separatedBy: "\n").first! .replacingOccurrences(of: "[download] Destination: ", with: ""))
                    videonameString.removeLast(4) // Remove extension
                    self.currentVideo.name = videonameString
                    print(videonameString)
                    infoHandler(self.currentVideo)
                    print("adding name to field")
                } else {
                    print("download update")
                    for i in (outputString.split(separator: " ")) {
                        if i.contains("%") {
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
    case latest = "youtube-dl-2021-12-17"
}
