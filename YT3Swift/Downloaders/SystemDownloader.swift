//
//  SystemDownloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/18/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation

class SystemDownloader: NSObject, ContentDownloader {
    var delegate: ContentDownloaderDelegate?
    let downloadQueue = OperationQueue()
    
    private var targetExtension:  MediaExtension!
    private var finalDestination: URL!
    private var completionHandler: ((YTVideo, URL) -> Void)!
    private var downloadTask: URLSessionDownloadTask!
    
    func download(content: String, with targetFormat: MediaFormat, to targetDestination: URL, completion: @escaping (YTVideo?, URL) -> Void) {
        downloadQueue.qualityOfService = .utility
        targetExtension = targetFormat.fileExtension
        finalDestination = targetDestination
        completionHandler = completion
        
        let urlSession = URLSession(configuration: .default,
                                                 delegate: self,
                                                 delegateQueue: downloadQueue)
        downloadTask = urlSession.downloadTask(with: URL(string:content)!)
        downloadTask.resume()
    }
    
    func terminateDownload() {
        downloadTask.cancel()
    }
    
    
}

extension SystemDownloader:URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished downloading to \(location)")
        
        do {
               let savedURL = finalDestination.appendingPathComponent(
                location.lastPathComponent).deletingPathExtension().appendingPathExtension(targetExtension.rawValue)
               try FileManager.default.moveItem(at: location, to: savedURL)
            print("Moved to location")
           } catch {
               print(error)
           }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(error)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        //print("Received \(bytesWritten) bytes")
        print(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100.0)
        
        if delegate != nil {
            delegate!.downloadDidProgress(to: (Double(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100.0))
        }
    }
    
    
}
