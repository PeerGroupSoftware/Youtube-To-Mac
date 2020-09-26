//
//  ViewController.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2017 Peer Group. All rights reserved.
//

import Cocoa

let previousVideosTableController = PreviousTableViewController()
var mainViewController = ViewController()

class ViewController: NSViewController {
    @IBOutlet weak var URLField: NSTextField!
    //@IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var audioBox: NSButton!
    @IBOutlet weak var formatPopup: NSPopUpButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var clearTableViewButton: NSButton!
    @IBOutlet weak var downloadLocationButton: NSButton!
    @IBOutlet weak var previousVideosTableView: NSTableView!
    @IBOutlet weak var recentVideosLabel: NSTextField!
    @IBOutlet weak var recentVideosDisclosureTriangle: NSButton!
    
    
    
    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    
    @IBOutlet weak var actionButton: NSButton!
    
    let downloader = Downloader()
    var currentRequest = YTDownloadRequest()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    override func viewWillAppear() {
        let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
        view.window?.setFrame(newWindowFrame, display: true, animate: true)
    }
    
    override func viewDidLoad() {
        //print("TEST")
        URLField.focusRingType = .none
        URLField.underlined()
        mainViewController = self
        
        //set video formats in UI
        formatPopup.removeAllItems()
        formatPopup.addItems(withTitles: Downloader.videoFormats)
        
        downloadLocationButton.setAsFolderButton()
        
        previousVideosTableView.delegate = previousVideosTableController
        previousVideosTableView.dataSource = previousVideosTableController
        
        let videoHistory = (UserDefaults().dictionary(forKey: "YTVideoHistory") as? [String:[String:String]] ?? [String:[String:String]]()).reversed()
        //print(videoHistory)
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
        UserDefaults().set([String:[String:String]](), forKey: "YTVideoHistory")
        previousVideos = []
        previousVideosTableView.reloadData()
    }
    
    func saveVideoToHistory(video targetVideo: YTVideo) {
        var videoHistory = (UserDefaults().dictionary(forKey: "YTVideoHistory")) as? [String:[String:String]] ?? [String:[String:String]]()
        videoHistory.updateValue([targetVideo.URL:targetVideo.diskPath], forKey: targetVideo.name)
        UserDefaults().set(videoHistory, forKey: "YTVideoHistory")
        
    }
    
    @IBAction func toggleWindowSize(_ sender: NSButton) {
        
        switch (sender.integerValue) {
        case 1:
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.5
                if previousVideosTableView.numberOfRows != 0 {clearTableViewButton.animator().isHidden = false}
            }, completionHandler:{
            })
            let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!-106, width: 422, height: 309)
            view.window?.setFrame(newWindowFrame, display: true, animate: true)
        case 0:
            let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
            view.window?.setFrame(newWindowFrame, display: true, animate: true)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                clearTableViewButton.animator().isHidden = true
            }, completionHandler:{
            })
        default:
            print("disclosure arrow error")
        }
    }
    
    @IBAction func changeDownloadLocation(_ sender: NSButton) {
        let locationSelectPanel = NSOpenPanel()
        locationSelectPanel.showsResizeIndicator=true
        locationSelectPanel.canChooseDirectories = true
        locationSelectPanel.canChooseFiles = false
        locationSelectPanel.allowsMultipleSelection = false
        locationSelectPanel.canCreateDirectories = true
        locationSelectPanel.beginSheetModal(for: view.window!, completionHandler: {(result) in
            if(result.rawValue == NSApplication.ModalResponse.OK.rawValue){
                let path = locationSelectPanel.url!.path
                print("selected folder is \(path)")
                self.currentRequest.destination = path
            }
        })
        
        
    }
    
    @IBAction func formatSelectionChanged(_ sender: NSPopUpButton) {
        if sender.selectedItem?.title != "Auto" {
            currentRequest.fileFormat = FileFormat(rawValue:(sender.selectedItem?.title)!)!
        } else {
            switch audioBox.integerValue {
            case 1:
                currentRequest.fileFormat = .defaultAudio
                print("set to audio")
            case 0:
                currentRequest.fileFormat = .defaultVideo//"mp4/flv/best"
                print("set to video")
            default:
                print("audio box error")
            }
            
        }
    }
    
    @IBAction func audioToggle(_ sender: NSButton) {
        
        if sender.identifier?.rawValue == "audioTBButton" {
            audioBox.state = sender.state
        } else {
            (view.window?.windowController as! MainWindowController as MainWindowController).updateTBAudioButton(withState: sender.state)
        }
        
        switch sender.integerValue {
        case 1:
            //print("set audio formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: Downloader.audioFormats)
        case 0:
           // print("set video formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: Downloader.videoFormats)
        default:
            print("Audio button error")
        }
        
        if formatPopup.selectedItem?.title == "Auto" {
            switch sender.integerValue {
            case 1:
                currentRequest.fileFormat = .defaultAudio//"wav/m4a/mp3/bestaudio"
                print("set to audio")
            case 0:
                currentRequest.fileFormat = .defaultVideo//"mp4/flv/best"
                print("set to video")
            default:
                print("audio box error")
            }
            
        }
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func startTasks(_ sender: NSButton) {
        currentRequest.contentURL = URLField.stringValue
        currentRequest.audioOnly = (audioBox.state == .on)
        currentRequest.error = nil
        
        //print("destination: \(currentRequest.destination)")
        if currentRequest.destination == "~/Desktop" || currentRequest.destination == "~/Downloads" {
            if (UserDefaults.standard.string(forKey: "DownloadDestination") ?? "") == "downloads" {
                currentRequest.destination = "~/Downloads"
            } else {
                currentRequest.destination = "~/Desktop"
            }
        }
        
        if !currentRequest.contentURL.isEmpty {
            setDownloadInterface(to: true)
            
            currentRequest.progressHandler = {(progress, error, videoInfo) in
                if progress >= 0 {
                    self.updateDownloadProgressBar(progress: progress, errorOccured: (error != nil))
                    if progress == 100 && videoInfo != nil {
                        self.setDownloadInterface(to: false)
                    } else if videoInfo != nil {
                        self.URLField.stringValue = videoInfo!.name
                    }
                    
                    if error != nil {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.alertStyle = .critical
                            alert.messageText = "Could not save \(videoInfo!.isAudioOnly ? "audio" : "video")"
                            alert.informativeText = error!.localizedDescription
                            alert.runModal()
                        }
                    }
                } else {
                    DispatchQueue.main.async {self.URLField.stringValue = videoInfo!.name}
                }
            }
            
            currentRequest.completionHandler = { (video, error) in
                self.URLField.stringValue = ""
                sender.isEnabled = true
                
                let downloadNotification = NSUserNotification()
                let formatType = (self.audioBox.state == .on) ? "Audio" : "Video"
                var downloadDestination = ""
                if self.currentRequest.destination == "~/Desktop" {
                    downloadDestination = "Desktop"
                } else if self.currentRequest.destination == "~/Downloads" {
                    downloadDestination = "Downloads"
                }
                
                var informativeText = ""
                if !downloadDestination.isEmpty {
                    informativeText = "Saved \(formatType.lowercased()) to \(downloadDestination)"
                } else {
                    informativeText = "Saved \(formatType.lowercased())"
                }
                
                downloadNotification.title = "Downloaded \(formatType)"
                downloadNotification.informativeText = informativeText
                downloadNotification.soundName = NSUserNotificationDefaultSoundName
                
                if self.downloadButton.isEnabled && (self.currentRequest.error == nil) {
                    NSUserNotificationCenter.default.deliver(downloadNotification)
                    self.saveVideoToHistory(video: video!)
                } else {
                    print(self.currentRequest.error)
                }
                
                self.setDownloadInterface(to: false)
                print(previousVideos.first?.name ?? "")
                
            }
            
            downloader.downloadContent(with: currentRequest)
        } else {
            if (sender.identifier?.rawValue) ?? "" == "downloadTBButton" {
                DispatchQueue.main.async {sender.isEnabled = true}
            }
        }
    }
    
    
    @IBAction func stopButton(_ sender: NSButton) {
        downloader.terminateDownload()
        setDownloadInterface(to: false)
    }
    
    func setDownloadTitleStatus(to downloadName: String) {
        
    }
    
    func setDownloadInterface(to: Bool) {
        DispatchQueue.main.async {
            switch to {
            case true: // Animate showing normal UI
                NSAnimationContext.runAnimationGroup({_ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = false
                    self.audioBox.animator().isHidden = true
                    self.recentVideosLabel.animator().isHidden = true
                    self.recentVideosDisclosureTriangle.animator().isHidden = true
                    self.formatPopup.animator().isHidden = true
                    self.downloadButton.isEnabled = false
                    self.downloadLocationButton.isEnabled = false
                    //self.nameLabel.animator().isHidden = false
                    
                    self.mainProgressBar.animator().isHidden = false
                    self.stopButton.animator().isHidden = false
                }, completionHandler:{
                })
            case false: // Animate hiding normal UI
                NSAnimationContext.runAnimationGroup({_ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = true
                    self.audioBox.animator().isHidden = false
                    self.downloadLocationButton.isEnabled = true
                    self.recentVideosLabel.animator().isHidden = false
                    self.recentVideosDisclosureTriangle.animator().isHidden = false
                    self.formatPopup.animator().isHidden = false
                    self.downloadButton.isEnabled = true
                    
                    
                    self.mainProgressBar.animator().isHidden = true
                    self.stopButton.animator().isHidden = true
                    // self.nameLabel.animator().isHidden = true
                }, completionHandler:{
                })
            }
        }
    }
    
    /*func downloadFinished(errorOccured: Bool) {
        let downloadNotification = NSUserNotification()
        let formatType = (self.audioBox.state == .on) ? "Audio" : "Video"
        /* switch self.audioBox.integerValue {
         case 1:
         formatType = "Audio"
         case 0:
         formatType = "Video"
         default:
         break
         }*/
        var downloadDestination = ""
        if currentRequest.destination == "~/Desktop" {
            downloadDestination = "Desktop"
        } else if currentRequest.destination == "~/Downloads" {
            downloadDestination = "Downloads"
        }
        
        var informativeText = ""
        if !downloadDestination.isEmpty {
            informativeText = "Saved \(formatType) to \(downloadDestination)"
        } else {
            informativeText = "Saved \(formatType)"
        }
        
        downloadNotification.title = "Downloaded \(formatType)"
        downloadNotification.informativeText = informativeText
        downloadNotification.soundName = NSUserNotificationDefaultSoundName
        
        if self.downloadButton.isEnabled && !errorOccured {
            NSUserNotificationCenter.default.deliver(downloadNotification)
            URLField.stringValue = ""
        }
        
        self.setDownloadInterface(to: false)
        print(previousVideos.first?.name ?? "")
        //print(self.currentVideo.name)
        
        /*if (previousVideos.first?.name ?? "" != self.currentVideo.name) && self.currentVideo.name != "" {
         print("adding to list")
         //print(self.currentVideo.name)
         self.saveVideoToHistory(video: self.currentVideo)
         previousVideos.insert(self.currentVideo, at: 0)
         self.previousVideosTableView.insertRows(at: IndexSet(integer: 0), withAnimation: NSTableView.AnimationOptions.slideDown)
         //print("wfh: \(self.view.window?.frame.height)")
         if self.view.window?.frame.height != 106 {
         NSAnimationContext.runAnimationGroup({_ in
         NSAnimationContext.current.duration = 0.5
         if self.previousVideosTableView.numberOfRows != 0 {self.clearTableViewButton.animator().isHidden = false}
         }, completionHandler: {
         })
         }
         }*/
    }*/
    
    func updateDownloadProgressBar(progress: Double, errorOccured: Bool) {
        print("progress update \(progress)")
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({_ in
                self.mainProgressBar.increment(by: progress-self.mainProgressBar.doubleValue)
            }, completionHandler:{
            })
            if progress == 100.0 {
                print("progress at 100")
                //self.downloadFinished(errorOccured: errorOccured)
            }
        }
    }
    
    
}
