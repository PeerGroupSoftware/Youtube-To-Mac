//
//  ViewController.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2026 Peer Group. All rights reserved.
//

import Cocoa
import UserNotifications

let previousVideosTableController = PreviousTableViewController()
var mainViewController = ViewController()

class ViewController: NSViewController {
    @IBOutlet weak var URLField: NSTextField!
    @IBOutlet weak var audioBox: NSButton!
    @IBOutlet weak var formatPopup: NSPopUpButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var clearTableViewButton: NSButton!
    @IBOutlet weak var downloadLocationButton: NSButton!
    @IBOutlet weak var previousVideosTableView: NSTableView!
    @IBOutlet weak var recentVideosLabel: NSTextField!
    @IBOutlet weak var bigConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var recentVideosDisclosureTriangle: NSButton!

    var bottomConstraintConstant: Int = 0
    let defaultBottomConstant = 9

    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    @IBOutlet weak var actionButton: NSButton!

    let downloader = Downloader()
    var currentRequest = YTDownloadRequest()
    private var lastClipboardString = ""

    override func viewWillAppear() {
        if bottomConstraintConstant == 0 {
            bottomConstraintConstant = Int(bigConstraint.constant)
            bigConstraint.constant = CGFloat(defaultBottomConstant)
        }
    }

    override func viewDidLoad() {
        URLField.focusRingType = .none
        URLField.underlined()
        mainViewController = self

        formatPopup.removeAllItems()
        formatPopup.addItems(withTitles: Downloader.videoFormats)

        downloadLocationButton.setAsFolderButton()

        previousVideosTableView.delegate = previousVideosTableController
        previousVideosTableView.dataSource = previousVideosTableController

        let videoHistory = (UserDefaults.standard.dictionary(forKey: "YTVideoHistory") as? [String: [String: String]] ?? [:]).reversed()
        for item in videoHistory {
            let newVideo = YTVideo()
            newVideo.name = item.key
            newVideo.URL = (item.value.first?.key)!
            newVideo.diskPath = (item.value.first?.value)!
            previousVideos.append(newVideo)
        }
        previousVideosTableView.reloadData()

        let recentVideosLabelGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(changeWindowSizeLabel))
        recentVideosLabel.addGestureRecognizer(recentVideosLabelGestureRecognizer)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        pasteClipboardURLIfNeeded(force: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidBecomeActive() {
        pasteClipboardURLIfNeeded(force: false)
    }

    /// Auto-fill the URL field when the clipboard holds a YouTube link.
    private func pasteClipboardURLIfNeeded(force: Bool) {
        guard !downloader.isRunning else { return }
        guard URLField.isEditable else { return }

        let pasteboard = NSPasteboard.general
        guard let clipboard = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboard.isEmpty else { return }

        if !force && clipboard == lastClipboardString { return }
        lastClipboardString = clipboard

        guard Downloader.looksLikeDownloadURL(clipboard) else { return }

        let current = URLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty || Downloader.looksLikeDownloadURL(current) {
            URLField.stringValue = clipboard
        }
    }

    @objc func changeWindowSizeLabel() {
        if recentVideosDisclosureTriangle.integerValue == 1 {
            recentVideosDisclosureTriangle.integerValue = 0
        } else {
            recentVideosDisclosureTriangle.integerValue = 1
        }
        toggleWindowSize(recentVideosDisclosureTriangle)
    }

    @IBAction func clearRecentVideos(_ sender: NSButton) {
        UserDefaults.standard.set([String: [String: String]](), forKey: "YTVideoHistory")
        previousVideos = []
        previousVideosTableView.reloadData()
    }

    func saveVideoToHistory(video targetVideo: YTVideo) {
        var videoHistory = (UserDefaults.standard.dictionary(forKey: "YTVideoHistory")) as? [String: [String: String]] ?? [:]
        videoHistory.updateValue([targetVideo.URL: targetVideo.diskPath], forKey: targetVideo.name)
        UserDefaults.standard.set(videoHistory, forKey: "YTVideoHistory")

        previousVideos.insert(targetVideo, at: 0)
        previousVideosTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
    }

    @IBAction func toggleWindowSize(_ sender: NSButton) {
        switch sender.integerValue {
        case 1:
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 0.5
                if previousVideosTableView.numberOfRows != 0 {
                    clearTableViewButton.animator().isHidden = false
                }
            })
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 0.2
                bigConstraint.animator().constant = CGFloat(bottomConstraintConstant)
            })
        case 0:
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 0.2
                clearTableViewButton.animator().isHidden = true
                bigConstraint.animator().constant = CGFloat(defaultBottomConstant)
            })
        default:
            break
        }
    }

    @IBAction func changeDownloadLocation(_ sender: NSButton) {
        let locationSelectPanel = NSOpenPanel()
        locationSelectPanel.showsResizeIndicator = true
        locationSelectPanel.canChooseDirectories = true
        locationSelectPanel.canChooseFiles = false
        locationSelectPanel.allowsMultipleSelection = false
        locationSelectPanel.canCreateDirectories = true
        locationSelectPanel.beginSheetModal(for: view.window!) { result in
            if result == .OK, let path = locationSelectPanel.url?.path {
                self.currentRequest.destination = path
            }
        }
    }

    @IBAction func formatSelectionChanged(_ sender: NSPopUpButton) {
        let title = sender.selectedItem?.title ?? "Auto"
        currentRequest.fileFormat = FileFormat.fromDisplayName(title, audioOnly: audioBox.state == .on)
    }

    @IBAction func audioToggle(_ sender: NSButton) {
        if sender.identifier?.rawValue == "audioTBButton" {
            audioBox.state = sender.state
        } else if let windowController = view.window?.windowController as? MainWindowController {
            windowController.updateTBAudioButton(withState: sender.state)
        }

        let audioOnly = sender.state == .on
        formatPopup.removeAllItems()
        formatPopup.addItems(withTitles: audioOnly ? Downloader.audioFormats : Downloader.videoFormats)
        currentRequest.fileFormat = FileFormat.fromDisplayName(
            formatPopup.selectedItem?.title ?? "Auto",
            audioOnly: audioOnly
        )
    }

    @IBAction func startTasks(_ sender: NSButton) {
        currentRequest.contentURL = URLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        currentRequest.audioOnly = (audioBox.state == .on)
        currentRequest.error = nil
        currentRequest.fileFormat = FileFormat.fromDisplayName(
            formatPopup.selectedItem?.title ?? "Auto",
            audioOnly: currentRequest.audioOnly
        )

        if currentRequest.destination == "~/Desktop" || currentRequest.destination == "~/Downloads" {
            if (UserDefaults.standard.string(forKey: "DownloadDestination") ?? "") == "downloads" {
                currentRequest.destination = "~/Downloads"
            } else {
                currentRequest.destination = "~/Desktop"
            }
        }

        guard !currentRequest.contentURL.isEmpty else {
            if (sender.identifier?.rawValue) ?? "" == "downloadTBButton" {
                DispatchQueue.main.async { sender.isEnabled = true }
            }
            return
        }

        // Warn early when conversion / stream merge needs ffmpeg.
        let needsFFmpeg = currentRequest.audioOnly
            ? currentRequest.fileFormat.isAudioConversionFormat
            : [.defaultVideo, .best1080, .best720, .best480, .mp4, .webm].contains(currentRequest.fileFormat)
        if needsFFmpeg && !Self.ffmpegAvailable() {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "ffmpeg Recommended"
            alert.informativeText = "This format usually needs ffmpeg to merge or convert streams. Install it with Homebrew (brew install ffmpeg), or continue anyway."
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
        }

        setDownloadInterface(to: true)

        currentRequest.progressHandler = { [weak self] progress, error, videoInfo in
            guard let self = self else { return }
            if progress >= 0 {
                self.updateDownloadProgressBar(progress: progress, errorOccured: (error != nil))
                if progress == 100 && videoInfo != nil {
                    self.setDownloadInterface(to: false)
                } else if let info = videoInfo, !info.name.isEmpty {
                    DispatchQueue.main.async { self.URLField.stringValue = info.name }
                }

                if let error = error, (error as NSError).code != 499 {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.alertStyle = .critical
                        alert.messageText = "Could not save \(videoInfo?.isAudioOnly == true ? "audio" : "video")"
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    }
                }
            } else if let info = videoInfo {
                DispatchQueue.main.async { self.URLField.stringValue = info.name }
            }
        }

        currentRequest.completionHandler = { [weak self] video, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.URLField.stringValue = ""
                sender.isEnabled = true

                let formatType = (self.audioBox.state == .on) ? "Audio" : "Video"
                var downloadDestination = ""
                let dest = self.currentRequest.destination
                if dest == "~/Desktop" || dest.hasSuffix("/Desktop") {
                    downloadDestination = "Desktop"
                } else if dest == "~/Downloads" || dest.hasSuffix("/Downloads") {
                    downloadDestination = "Downloads"
                }

                let informativeText: String
                if downloadDestination.isEmpty {
                    informativeText = "Saved \(formatType.lowercased())"
                } else {
                    informativeText = "Saved \(formatType.lowercased()) to \(downloadDestination)"
                }

                if self.downloadButton.isEnabled && self.currentRequest.error == nil && error == nil, let video = video {
                    self.deliverDownloadNotification(title: "Downloaded \(formatType)", body: informativeText)
                    video.diskPath = self.currentRequest.expandedDestination
                    self.saveVideoToHistory(video: video)
                }

                self.setDownloadInterface(to: false)
                self.mainProgressBar.doubleValue = 0
            }
        }

        downloader.downloadContent(with: currentRequest)
    }

    @IBAction func stopButton(_ sender: NSButton) {
        downloader.terminateDownload()
        setDownloadInterface(to: false)
        mainProgressBar.doubleValue = 0
    }

    func setDownloadInterface(to: Bool) {
        DispatchQueue.main.async {
            let windowController = self.view.window?.windowController as? MainWindowController

            switch to {
            case true:
                windowController?.setIsDownloading(downloading: true)
                NSAnimationContext.runAnimationGroup({ _ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = false
                    self.audioBox.animator().isHidden = true
                    self.recentVideosLabel.animator().isHidden = true
                    self.recentVideosDisclosureTriangle.animator().isHidden = true
                    self.formatPopup.animator().isHidden = true
                    self.downloadButton.isEnabled = false
                    windowController?.updateTBDownloadButton(withState: .off)
                    self.downloadLocationButton.isEnabled = false
                    self.mainProgressBar.doubleValue = 0
                    self.mainProgressBar.animator().isHidden = false
                    self.stopButton.animator().isHidden = false
                })
            case false:
                windowController?.setIsDownloading(downloading: false)
                NSAnimationContext.runAnimationGroup({ _ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = true
                    self.audioBox.animator().isHidden = false
                    self.downloadLocationButton.isEnabled = true
                    self.recentVideosLabel.animator().isHidden = false
                    self.recentVideosDisclosureTriangle.animator().isHidden = false
                    self.formatPopup.animator().isHidden = false
                    self.downloadButton.isEnabled = true
                    windowController?.updateTBDownloadButton(withState: .on)
                    self.mainProgressBar.animator().isHidden = true
                    self.stopButton.animator().isHidden = true
                })
            }
        }
    }

    func updateDownloadProgressBar(progress: Double, errorOccured: Bool) {
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ _ in
                self.mainProgressBar.increment(by: progress - self.mainProgressBar.doubleValue)
            })
        }
    }

    private func deliverDownloadNotification(title: String, body: String) {
        if #available(macOS 10.14, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            let downloadNotification = NSUserNotification()
            downloadNotification.title = title
            downloadNotification.informativeText = body
            downloadNotification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(downloadNotification)
        }
    }

    private static func ffmpegAvailable() -> Bool {
        let candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/opt/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        if candidates.contains(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return true
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
