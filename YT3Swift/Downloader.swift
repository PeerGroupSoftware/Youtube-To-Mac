//
//  Downloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation
import Cocoa

class Downloader: ContentDownloaderDelegate {
    
    
    var isRunning = false
    var videoID = ""
    var videoTitle = ""
    var saveLocation = "~/Desktop"
    var currentVideo = YTVideo()
    var cachedRequest: YTDownloadRequest?
    //private var downloadTask:Process!
    static let videoFormats = ["Auto", "mp4", "flv", "webm"]
    static let audioFormats = ["Auto", "m4a", "mp3", "wav", "aac"]
    private let defaultQOS: DispatchQoS.QoSClass  = .userInitiated
    
    var progressHandler: ((Double, Error?, YTVideo?) -> Void)?
    var completionHandler: ((YTVideo?, Error?) -> Void)?
    
    var downloader: ContentDownloader = YTDLDownloader()
    
    static func allFormats(for contentType: FormatType) -> [MediaExtension] {
        switch contentType {
        case .video:
            return [.mp4, .flv, .webm, .mov, .m4v]
        case .audio:
            return [.m4a, .mp3, .wav, .aac, .aiff, .caf]
        }
    }
    
    func downloadContent(with downloadRequest: YTDownloadRequest) {
        downloadContent(from: downloadRequest.contentURL, toLocation: downloadRequest.destination, audioOnly: downloadRequest.audioOnly, fileFormat: downloadRequest.fileFormat, progress: downloadRequest.progressHandler!, completionHandler: downloadRequest.completionHandler)
        
        cachedRequest = downloadRequest
    }
    
    func terminateDownload() {
        //downloadTask.terminate()
    }
    
    func downloadContent(from targetURL: String, toLocation downloadDestination: String, audioOnly: Bool, fileFormat: MediaExtension, progress progressHandler: @escaping (Double, Error?, YTVideo?) -> Void, completionHandler: @escaping (YTVideo?, Error?) -> Void) {
        
        downloader.delegate = self
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        
        currentVideo.url = targetURL
        currentVideo.isAudioOnly = audioOnly
        
        downloader.download(content: targetURL, with: MediaFormat.init(fileExtension: fileFormat), to: URL(string: downloadDestination)!, completion: {
            completionHandler(nil, nil)
        })
        
        /*
        //if !(downloadTask.isRunning ?? false) {
        let downloaderVersion = YoutubeDLVersion.latest
        currentVideo.url = targetURL
        currentVideo.isAudioOnly = audioOnly
        
        isRunning = true
        let taskQueue = DispatchQueue.global(qos: defaultQOS)
        
        taskQueue.async {
            
            let path = Bundle.main.path(forResource: downloaderVersion.rawValue, ofType: "sh")
            self.downloadTask = Process()
            if #available(OSX 10.13, *) {
                self.downloadTask.executableURL = URL(fileURLWithPath: path!)
            } else {
                self.downloadTask.launchPath = path
            }
            //print("using file format \(fileFormat.rawValue)")
            self.downloadTask.arguments = ["-f \(fileFormat.rawValue)[height>=?1080]", "-o%(title)s.%(ext)s", targetURL]
            self.downloadTask.currentDirectoryPath = downloadDestination
            
            self.downloadTask.terminationHandler = {
                
                task in
                DispatchQueue.main.async(execute: {
                    print("Stopped")
                    let terminationReason = self.downloadTask.terminationReason.rawValue
                    progressHandler(100, nil, nil)
                    //print(terminationReason)
                    if terminationReason == 2 {
                        completionHandler(self.currentVideo,NSError(domain: "", code: 499, userInfo: [NSLocalizedDescriptionKey: "Cancelled Task"]))
                    } else {
                        completionHandler(self.currentVideo, nil)
                    }
                    self.currentVideo = YTVideo()
                    if self.outputPipe.description.contains("must provide") {
                        print("error")
                    }
                    self.isRunning = false
                })
                
            }
            
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
            
            self.readError(self.downloadTask, errorHandler: {(error) in
                progressHandler(100, error, self.currentVideo)
            })
            if #available(OSX 10.13, *) {
                try! self.downloadTask.run()
            } else {
                self.downloadTask.launch()
            }
            self.downloadTask.waitUntilExit()
            
        }
        
        /*  } else {
         print("Can't start download, task is already running")
         }*/
        */
    }
    
    func didCompleteDownload(error: Int?) {
        print("COMPLETED: \(error)")
        if completionHandler != nil {
            completionHandler!(currentVideo, (error == nil ? nil : NSError(domain: "", code: error!, userInfo: [NSLocalizedDescriptionKey:downloadErrors[error!]])))
        }
    }
    
    func downloadDidProgress(to downloadProgress: Double) {
        print("PROGRESS: \(downloadProgress)")
        if progressHandler != nil {
            progressHandler!(downloadProgress, nil, self.currentVideo)
        }
        
    }
    
    func didGetVideoName(_ videoName: String) {
        print("Video name found: \(videoName)")
        self.currentVideo.name = videoName
        if progressHandler != nil {
            self.progressHandler!(-1, nil, currentVideo)
        }
    }
    
    /*private func readError(_ task:Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = self.errorPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            if !outputString.isEmpty {
                //print("got error")
                print("ERROR: \(outputString)")
                
                if outputString.contains("requested format not available") {
                    print("format not available")
                    self.sendFatalError(error: NSError(domain: "", code: 415, userInfo: [NSLocalizedDescriptionKey: "The requested format is not available for this content, please use the automatic format selection."]), handler: errorHandler)
                    
                } else if outputString.contains("Premieres in") {
                    self.sendFatalError(error: NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "The requested content has not yet premiered. Please try again once this content has been made available."]), handler: errorHandler)
                    
                } else if outputString.contains("This live event will begin in") {
                    self.sendFatalError(error: NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "The requested content has not yet premiered. Please try again once this content has been made available."]), handler: errorHandler)
                } else if outputString.contains("who has blocked it on copyright grounds") {
                    print("Video was blocked")
                    self.sendFatalError(error: NSError(domain: "", code: 451, userInfo: [NSLocalizedDescriptionKey: "The requested content was blocked on copyright grounds."]), handler: errorHandler)
                } else if outputString.contains("is not a valid URL") {
                    self.sendFatalError(error: NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid."]), handler: errorHandler)
                    
                } else if outputString.contains("Unable to extract video data") {
                    self.sendFatalError(error: NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid."]), handler: errorHandler)
                } else if !outputString.isEmpty {
                    //errorHandler(NSError(domain: "", code: 520, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured. Please file a bug report."]))
                }
                
                self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                
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
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            if outputString.range(of:"100%: Done") != nil {
                self.downloadTask.qualityOfService = .background
                
                //   } else if outputString.contains("requested format not available") {
                
            } else if outputString.contains("has already been downloaded") {
                errorHandler(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "The requested content already exists at the download destination."]))
            } else if outputString.range(of:"must provide") != nil {
                print("There was some kind of error")
                
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    //print("OUT: \"\(outputString)\"")
                    var videonameString = (outputString.components(separatedBy: "\n").first! .replacingOccurrences(of: "[download] Destination: ", with: ""))
                    videonameString.removeLast(4) // Remove extension
                    // print(videonameString)
                    
                    //print(videonameString.distance(from: (videonameString.range(of: ("-" + self.videoID))?.lowerBound)!, to: videonameString.endIndex))
                    //videonameString.removeSubrange((videonameString.range(of: ("-" + self.videoID))?.lowerBound)!..<videonameString.endIndex)
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
    }*/
    
    func getFormats(for targetVideo: YTVideo, useableOnly: Bool = false, completion: @escaping ([MediaFormat], Error?) -> Void) {
        let executablePath = Bundle.main.path(forResource: YTDLDownloader.executableName, ofType: "sh")
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let fetchInfoTask = Process()
        
        var retreivedJSONString = ""
        var foundFormats: [MediaFormat] = []
        
        
        if #available(OSX 10.13, *) {
            fetchInfoTask.executableURL = URL(fileURLWithPath: executablePath!)
        } else {
            fetchInfoTask.launchPath = executablePath
        }
        
        fetchInfoTask.arguments = ["--dump-json", targetVideo.url]
        fetchInfoTask.qualityOfService = .default
        
        fetchInfoTask.standardOutput = outputPipe
        fetchInfoTask.standardError = errorPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        fetchInfoTask.terminationHandler = {(process) in
            print("Finsihed checking JSON")
            //fetchInfoTask.standardOutput = nil
            do {
                let dataResponse = retreivedJSONString.data(using: .utf8)!
                //print(dataResponse)
                    let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String : Any]
                let retreivedFormats = (jsonResponse!["formats"] as! [[String: Any]])
                //print(retreivedFormats)
                for format in retreivedFormats {
                    //print("\(format["ext"] ?? "unknown") - \(format["width"] ?? 0)x\(format["height"] ?? 0)")
                    guard let newExtension = MediaExtension(rawValue: (format["ext"] as! String) ?? "unknown") else {return}
                    var newFormat = MediaFormat(fileExtension: newExtension)
                    
                    if ((format["format"] as? String) ?? "unknown").contains("audio only") {
                        newFormat.audioOnly = true
                    }
                    
                    if ((format["format_note"] as? String) ?? "unknown").last == "p" {
                        newFormat.sizeString = (format["format_note"] as! String)
                    }
                    
                    for codec in YTCodec.allCases {
                        if ((format["acodec"] as? String) ?? "unknown").contains(codec.rawValue) {
                            newFormat.codec = codec
                        } else if ((format["vcodec"] as? String) ?? "unknown").contains(codec.rawValue) {
                            newFormat.codec = codec
                        }
                    }
                    
                    newFormat.fps = (format["fps"] as? Int)
                    
                    var newSize = NSSize()
                    newSize.width = CGFloat((format["width"] as? Int) ?? 0)
                    newSize.height = CGFloat((format["height"] as? Int) ?? 0)
                    
                    if (newSize.width != 0) || (newSize.height != 0) {
                        newFormat.size = newSize
                    }
                    foundFormats.append(newFormat)
                }
            } catch {
               print(error)
                completion([], error)
            }
            
            if useableOnly {
                foundFormats = foundFormats.filter({[YTCodec.mp4a, YTCodec.avc1].contains($0.codec)})
            }
            completion(foundFormats, nil)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            retreivedJSONString += (outputString)
            if !outputString.isEmpty {
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) { notification in
            let output = errorPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            print(outputString)
            if !outputString.isEmpty {
                errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
        fetchInfoTask.waitUntilExit()
        
        try! fetchInfoTask.run()
        //("REsumed?")
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
    case latest = "youtube-dl-2020-11-01"
}
