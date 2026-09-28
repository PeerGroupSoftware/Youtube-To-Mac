//
//  Downloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2026 Peer Group Software. All rights reserved.
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
    private var outputPipe: Pipe!
    private var errorPipe: Pipe!
    private var downloadTask: Process!
    private var outputObserver: NSObjectProtocol?
    private var errorObserver: NSObjectProtocol?

    static let videoFormats = ["Auto", "1080p", "720p", "480p", "mp4", "webm"]
    static let audioFormats = ["Auto", "m4a", "mp3", "wav", "aac"]
    private let defaultQOS: DispatchQoS.QoSClass = .userInitiated

    /// Bundled yt-dlp binary resource name (no extension).
    private let bundledDownloaderName = "yt-dlp_macos"

    func downloadContent(with downloadRequest: YTDownloadRequest) {
        cachedRequest = downloadRequest
        downloadContent(
            from: downloadRequest.contentURL,
            toLocation: downloadRequest.expandedDestination,
            audioOnly: downloadRequest.audioOnly,
            fileFormat: downloadRequest.fileFormat,
            progress: downloadRequest.progressHandler!,
            completionHandler: downloadRequest.completionHandler
        )
    }

    func terminateDownload() {
        guard let task = downloadTask, task.isRunning else { return }
        task.terminate()
    }

    func downloadContent(
        from targetURL: String,
        toLocation downloadDestination: String,
        audioOnly: Bool,
        fileFormat: FileFormat,
        progress progressHandler: @escaping (Double, Error?, YTVideo?) -> Void,
        completionHandler: @escaping (YTVideo?, Error?) -> Void
    ) {
        currentVideo = YTVideo()
        currentVideo.URL = targetURL
        currentVideo.isAudioOnly = audioOnly
        currentVideo.diskPath = downloadDestination

        isRunning = true
        let taskQueue = DispatchQueue.global(qos: defaultQOS)

        taskQueue.async { [weak self] in
            guard let self = self else { return }

            guard let path = Bundle.main.path(forResource: self.bundledDownloaderName, ofType: nil)
                    ?? Bundle.main.path(forResource: self.bundledDownloaderName, ofType: "") else {
                let error = NSError(
                    domain: "YoutubeToMac",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "The yt-dlp downloader could not be found in the app bundle."]
                )
                self.sendFatalError(error: error) { err in
                    progressHandler(100, err, self.currentVideo)
                }
                completionHandler(nil, error)
                self.isRunning = false
                return
            }

            // Ensure destination exists
            try? FileManager.default.createDirectory(
                atPath: downloadDestination,
                withIntermediateDirectories: true,
                attributes: nil
            )

            self.downloadTask = Process()
            self.downloadTask.executableURL = URL(fileURLWithPath: path)
            self.downloadTask.arguments = self.buildArguments(
                url: targetURL,
                audioOnly: audioOnly,
                fileFormat: fileFormat
            )
            self.downloadTask.currentDirectoryPath = downloadDestination

            // Prefer system ffmpeg when available (Homebrew / MacPorts paths).
            var environment = ProcessInfo.processInfo.environment
            let extraPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin"]
            let pathValue = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
            environment["PATH"] = (extraPaths + [pathValue]).joined(separator: ":")
            self.downloadTask.environment = environment

            self.downloadTask.terminationHandler = { [weak self] task in
                guard let self = self else { return }
                self.removePipeObservers()

                let terminationReason = task.terminationReason
                let status = task.terminationStatus

                if terminationReason == .uncaughtSignal || status == 15 || status == 9 {
                    // SIGTERM / SIGKILL — cancelled
                    progressHandler(100, nil, nil)
                    completionHandler(
                        self.currentVideo,
                        NSError(domain: "YoutubeToMac", code: 499, userInfo: [NSLocalizedDescriptionKey: "Cancelled Task"])
                    )
                } else if status != 0, self.cachedRequest?.error == nil {
                    let error = NSError(
                        domain: "YoutubeToMac",
                        code: Int(status),
                        userInfo: [NSLocalizedDescriptionKey: "Download failed (exit code \(status)). Check the URL and that ffmpeg is installed for audio conversion."]
                    )
                    self.cachedRequest?.error = error
                    progressHandler(100, error, self.currentVideo)
                    completionHandler(self.currentVideo, error)
                } else {
                    progressHandler(100, self.cachedRequest?.error, self.currentVideo)
                    completionHandler(self.currentVideo, self.cachedRequest?.error)
                }

                self.currentVideo = YTVideo()
                self.isRunning = false
            }

            self.captureStandardOutput(self.downloadTask, progressHandler: { percent in
                progressHandler(percent, nil, nil)
            }, errorHandler: { error in
                self.cachedRequest?.error = error
                progressHandler(100, error, self.currentVideo)
            }, infoHandler: { videoInfo in
                progressHandler(-1, nil, videoInfo)
            })

            self.readError(self.downloadTask, errorHandler: { error in
                progressHandler(100, error, self.currentVideo)
            })

            do {
                try self.downloadTask.run()
                self.downloadTask.waitUntilExit()
            } catch {
                let nsError = error as NSError
                self.sendFatalError(error: nsError) { err in
                    progressHandler(100, err, self.currentVideo)
                }
                completionHandler(nil, nsError)
                self.isRunning = false
            }
        }
    }

    /// Build yt-dlp CLI arguments for the requested mode/format.
    private func buildArguments(url: String, audioOnly: Bool, fileFormat: FileFormat) -> [String] {
        var args: [String] = [
            "--newline",
            "--no-playlist",
            "--no-mtime",
            "-o", "%(title)s.%(ext)s",
            "--restrict-filenames"
        ]

        if audioOnly {
            args.append(contentsOf: ["-x", "--audio-quality", "0"])
            switch fileFormat {
            case .defaultAudio:
                // Prefer best audio; keep original codec when possible.
                args.append(contentsOf: ["-f", FileFormat.defaultAudio.rawValue])
            case .m4a, .mp3, .wav, .aac:
                args.append(contentsOf: ["--audio-format", fileFormat.rawValue])
            default:
                args.append(contentsOf: ["--audio-format", "m4a"])
            }
        } else {
            args.append(contentsOf: ["-f", fileFormat.rawValue])
            // Merge into mp4 when selecting height-limited best formats for broader playback.
            switch fileFormat {
            case .best1080, .best720, .best480, .defaultVideo:
                args.append(contentsOf: ["--merge-output-format", "mp4"])
            default:
                break
            }
        }

        args.append(url)
        return args
    }

    private func readError(_ task: Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

        errorObserver = NotificationCenter.default.addObserver(
            forName: .NSFileHandleDataAvailable,
            object: errorPipe.fileHandleForReading,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }

            let output = self.errorPipe.fileHandleForReading.availableData
            let errorString = String(data: output, encoding: .utf8) ?? ""

            if !errorString.isEmpty {
                print("yt-dlp stderr: \(errorString)")

                if errorString.contains("requested format not available")
                    || errorString.contains("Requested format is not available") {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 415, userInfo: [NSLocalizedDescriptionKey: "The requested format is not available for this content. Try Auto, or install ffmpeg for audio conversion."]),
                        handler: errorHandler
                    )
                } else if errorString.contains("Premieres in") || errorString.contains("This live event will begin") {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 403, userInfo: [NSLocalizedDescriptionKey: "The requested content has not yet premiered. Please try again once it is available."]),
                        handler: errorHandler
                    )
                } else if errorString.contains("who has blocked it on copyright grounds") {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 451, userInfo: [NSLocalizedDescriptionKey: "The requested content was blocked on copyright grounds."]),
                        handler: errorHandler
                    )
                } else if errorString.contains("is not a valid URL")
                    || errorString.contains("Unsupported URL")
                    || errorString.contains("Unable to extract") {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 400, userInfo: [NSLocalizedDescriptionKey: "The provided URL is invalid or unsupported."]),
                        handler: errorHandler
                    )
                } else if errorString.localizedCaseInsensitiveContains("ffmpeg")
                    && (errorString.localizedCaseInsensitiveContains("not found")
                        || errorString.localizedCaseInsensitiveContains("ffprobe")) {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 500, userInfo: [NSLocalizedDescriptionKey: "ffmpeg is required for this format. Install it with Homebrew: brew install ffmpeg"]),
                        handler: errorHandler
                    )
                } else if errorString.contains("env: python") {
                    self.sendFatalError(
                        error: NSError(domain: "YoutubeToMac", code: 500, userInfo: [NSLocalizedDescriptionKey: "A Python runtime was required but could not be found. This build uses a standalone yt-dlp binary and should not need Python."]),
                        handler: errorHandler
                    )
                }

                self.errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
    }

    func sendFatalError(error: Error, handler: @escaping (Error) -> Void) {
        cachedRequest?.error = error
        handler(error)
    }

    private func captureStandardOutput(
        _ task: Process,
        progressHandler: @escaping (Double) -> Void,
        errorHandler: @escaping (Error) -> Void,
        infoHandler: @escaping (YTVideo) -> Void
    ) {
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

        outputObserver = NotificationCenter.default.addObserver(
            forName: .NSFileHandleDataAvailable,
            object: outputPipe.fileHandleForReading,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }

            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: .utf8) ?? ""

            if outputString.contains("has already been downloaded") {
                errorHandler(NSError(
                    domain: "YoutubeToMac",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "The requested content already exists at the download destination."]
                ))
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    if let line = outputString.components(separatedBy: "\n").first(where: { $0.contains("Destination:") }) {
                        var name = line.replacingOccurrences(of: "[download] Destination: ", with: "")
                        if let ext = name.split(separator: ".").last, ext.count <= 5 {
                            name = (name as NSString).deletingPathExtension
                        }
                        self.currentVideo.name = name
                        infoHandler(self.currentVideo)
                    }
                } else {
                    for token in outputString.split(separator: " ") {
                        if token.contains("%"), let value = Double(token.replacingOccurrences(of: "%", with: "")) {
                            progressHandler(min(value, 99.9))
                        }
                    }
                }
            } else if outputString.contains("[ExtractAudio]") || outputString.contains("[Merger]") {
                // Conversion / merge stage — keep UI in downloading state near completion.
                progressHandler(95)
            } else if (outputString.contains("[youtube]") || outputString.contains("[Youtube]"))
                        && outputString.contains("Downloading webpage") {
                let parts = outputString.split(separator: " ")
                if parts.count > 1 {
                    self.videoID = parts[1].replacingOccurrences(of: ":", with: "")
                }
            }

            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }

    private func removePipeObservers() {
        if let outputObserver = outputObserver {
            NotificationCenter.default.removeObserver(outputObserver)
            self.outputObserver = nil
        }
        if let errorObserver = errorObserver {
            NotificationCenter.default.removeObserver(errorObserver)
            self.errorObserver = nil
        }
    }

    func fetchJSON(from targetURL: URL, completion: @escaping ([String: Any]?, Error?) -> Void) {
        var request = URLRequest(url: targetURL)
        request.setValue("YoutubeToMac", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let dataResponse = data, error == nil else {
                completion(nil, error)
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String: Any]
                completion(jsonResponse, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }

    /// Returns true if a YouTube / supported media URL looks present in the string.
    static func looksLikeDownloadURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let host = url.host?.lowercased() else { return false }
        let supported = ["youtube.com", "youtu.be", "m.youtube.com", "music.youtube.com", "www.youtube.com"]
        return supported.contains(where: { host == $0 || host.hasSuffix(".\($0)") })
            || trimmed.contains("youtube.com/")
            || trimmed.contains("youtu.be/")
    }
}
