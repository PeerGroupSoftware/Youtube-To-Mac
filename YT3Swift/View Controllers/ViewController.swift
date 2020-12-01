//
//  ViewController.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2020 Peer Group. All rights reserved.
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
    @IBOutlet weak var bigConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var recentVideosDisclosureTriangle: NSButton!
    @IBOutlet weak var controlsButton: NSButton!
    @IBOutlet weak var controlsLoadingIndicator: NSProgressIndicator!
    
    var bottomConstraintConstant: Int = 0
    let defaultBottomConstant = 9
    private var controlsPopover: NSPopover?
    
    private let videoFormatsList = ["Auto", "Manual"] + Downloader.allFormats(for: .video).compactMap({$0.rawValue})
    private let audioFormatsList = ["Auto", "Manual"] + Downloader.allFormats(for: .video).compactMap({$0.rawValue})
    
    
    
    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    
    @IBOutlet weak var actionButton: NSButton!
    
    let downloader = Downloader()
    var currentRequest = YTDownloadRequest()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    override func viewWillAppear() {
        //let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
        //view.window?.setFrame(newWindowFrame, display: true, animate: true)
        
        if bottomConstraintConstant == 0 {
            bottomConstraintConstant = Int(bigConstraint.constant)
            bigConstraint.constant = CGFloat(defaultBottomConstant)
        }
        
        // bottomSpaceConstraint.constant = -previousVideosTableView.frame.size.height
    }
    
    override func viewDidLoad() {
        
        URLField.focusRingType = .none
        URLField.underlined()
        URLField.delegate = self
        mainViewController = self
        
        //set video formats in UI
        formatPopup.removeAllItems()
        formatPopup.addItems(withTitles: videoFormatsList)
        
        downloadLocationButton.setAsFolderButton()
        
        previousVideosTableView.delegate = previousVideosTableController
        previousVideosTableView.dataSource = previousVideosTableController
        
        let videoHistory = (UserDefaults().dictionary(forKey: "YTVideoHistory") as? [String:[String:String]] ?? [String:[String:String]]()).reversed()
        //print(videoHistory)
        for item in videoHistory {
            let newVideo = YTVideo()
            newVideo.name = item.key
            newVideo.url = (item.value.first?.key)!
            newVideo.diskPath = (item.value.first?.value)!
            previousVideos.append(newVideo)
        }
        previousVideosTableView.reloadData()
        
        let recentVideosLabelGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(changeWindowSizeLabel))
        recentVideosLabel.addGestureRecognizer(recentVideosLabelGestureRecognizer)
    }
    
    @objc func loadVideoFormats() {
        if URLField.stringValue.containsURL() {
        DispatchQueue.main.async {
            if !(self.controlsPopover?.isShown ?? false) {
                self.controlsLoadingIndicator.startAnimation(self)
                self.controlsButton.isHidden = true
            } else {
                (self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.loading)
            }
        }
        Downloader().getFormats(for: YTVideo(name: "", url: URLField.stringValue), useableOnly: true, completion: {(formats, error) in
            DispatchQueue.main.async {
                if !(self.controlsPopover?.isShown ?? false) {
                    if !formats.isEmpty {self.controlsButton.isEnabled = true}
                    self.controlsLoadingIndicator.stopAnimation(self)
                    self.controlsButton.isHidden = false
                } else {
                    if formats.isEmpty {
                        (self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.waiting)
                    } else {
                        (self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.found)
                    }
                }
            }
            //let directUsableFormats = formats.filter({[YTCodec.mp4a, YTCodec.avc1].contains($0.codec)})
            print(formats.sorted(by: {($0.size?.height ?? 0)<($1.size?.height ?? 0)}))
        })
        } else {
            print("No URL detected")
            if self.controlsPopover != nil {
                (self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.waiting)
            }
        }
    }
    
    @IBAction func videoControlsPopover(_ sender: NSButton) {
        if controlsPopover == nil {
            let popoverVC = NSStoryboard.main?.instantiateController(withIdentifier: "ContentControlsPopover") as! FormatControlsVC
            let popover = NSPopover()
            popover.contentViewController = popoverVC
            popover.behavior = .semitransient
            controlsPopover = popover
        }
        
        if (controlsPopover?.isShown ?? false) {
            controlsPopover?.performClose(self)
        } else {
            controlsPopover!.show(relativeTo: sender.frame, of: view, preferredEdge: .minY)
            (controlsPopover?.contentViewController as! FormatControlsVC).setURLState(currentRequest.directFormats.isEmpty ? .waiting : .found)
        }
    }
    
    @objc func changeWindowSizeLabel() {
        /*if recentVideosDisclosureTriangle.state == .on {
            recentVideosDisclosureTriangle.state = .off
        } else {
            recentVideosDisclosureTriangle.state = .on
        }*/
        recentVideosDisclosureTriangle.state = (recentVideosDisclosureTriangle.state == .on) ? .off : .on
        toggleWindowSize(recentVideosDisclosureTriangle)
    }
    
    @IBAction func clearRecentVideos(_ sender: NSButton) {
        UserDefaults().set([String:[String:String]](), forKey: "YTVideoHistory")
        previousVideos = []
        previousVideosTableView.reloadData()
    }
    
    func saveVideoToHistory(video targetVideo: YTVideo) {
        var videoHistory = (UserDefaults().dictionary(forKey: "YTVideoHistory")) as? [String:[String:String]] ?? [String:[String:String]]()
        //UserDefaults().arr
        videoHistory.updateValue([targetVideo.url:targetVideo.diskPath], forKey: targetVideo.name)
        UserDefaults().set(videoHistory, forKey: "YTVideoHistory")
        
        previousVideos.insert(targetVideo, at: 0)
        self.previousVideosTableView.insertRows(at: IndexSet(integer: 0), withAnimation: NSTableView.AnimationOptions.slideDown)
        
    }
    
    @IBAction func toggleWindowSize(_ sender: NSButton) {
        
        switch (sender.state) {
        case .on:
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.5
                if previousVideosTableView.numberOfRows != 0 {clearTableViewButton.animator().isHidden = false}
            }, completionHandler:{
            })
            // let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!-106, width: 422, height: 309)
            bigConstraint.animator().constant = CGFloat(bottomConstraintConstant)
            // print(bottomConstraintConstant)
            //view.window?.setFrame(newWindowFrame, display: true, animate: true)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                //clearTableViewButton.animator().isHidden = true
                bigConstraint.animator().constant = CGFloat(bottomConstraintConstant)
            }, completionHandler:{
            })
        case .off:
            //let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
            
            // view.window?.setFrame(newWindowFrame, display: true, animate: true)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                clearTableViewButton.animator().isHidden = true
                bigConstraint.animator().constant = CGFloat(defaultBottomConstant)
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
                self.currentRequest.destination = URL(fileURLWithPath: path)
            }
        })
        
        
    }
    
    @IBAction func formatSelectionChanged(_ sender: NSPopUpButton) {
        if  !["Auto", "Manual"].contains(sender.selectedItem?.title) {
            currentRequest.fileFormat = MediaExtension(rawValue:(sender.selectedItem?.title)!)!
        } else {
            switch audioBox.integerValue {
            case 1:
               // currentRequest.fileFormat = .defaultAudio
               // currentRequest.fileFormat = .
                print("set to audio")
            case 0:
               // currentRequest.fileFormat = .defaultVideo//"mp4/flv/best"
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
            formatPopup.addItems(withTitles: audioFormatsList/*["Auto"] + Downloader.allFormats(for: .audio).compactMap({$0.rawValue})*/)
        case 0:
            // print("set video formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: videoFormatsList/*["Auto"] + Downloader.allFormats(for: .video).compactMap({$0.rawValue})*/)
        default:
            print("Audio button error")
        }
        
        if formatPopup.selectedItem?.title == "Auto" {
            switch sender.integerValue {
            case 1:
                currentRequest.fileFormat = .auto//"wav/m4a/mp3/bestaudio"
                print("set to audio")
            case 0:
                currentRequest.fileFormat = .auto//"mp4/flv/best"
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
        if currentRequest.destination == Downloader.desktopFolder || currentRequest.destination == Downloader.downloadsFolder {
            if (UserDefaults.standard.string(forKey: "DownloadDestination") ?? "") == "downloads" {
                currentRequest.destination = Downloader.downloadsFolder//"~/Downloads"
            } else {
                currentRequest.destination = Downloader.desktopFolder
            }
        }
        
        if !currentRequest.contentURL.isEmpty {
            setDownloadInterface(to: true)
            
            currentRequest.progressHandler = {(progress, error, videoInfo) in
                DispatchQueue.main.async {
                if progress >= 0 {
                    self.updateDownloadProgressBar(progress: progress, errorOccured: (error != nil))
                    if progress == 100 && videoInfo != nil {
                        self.setDownloadInterface(to: false)
                    }
                } else if progress != 100 {
                    DispatchQueue.main.async {self.URLField.stringValue = videoInfo!.name}
                }
            }
            }
            
            currentRequest.completionHandler = { (video, error) in
                //print("COMPLETION HANDLER")
                DispatchQueue.main.async {
                self.URLField.stringValue = ""
                sender.isEnabled = true
                
                let downloadNotification = NSUserNotification()
                let formatType = (self.audioBox.state == .on) ? "Audio" : "Video"
                var downloadDestination = ""
                if self.currentRequest.destination == Downloader.desktopFolder {
                    downloadDestination = "Desktop"
                } else if self.currentRequest.destination == Downloader.downloadsFolder {
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
                
                if self.downloadButton.isEnabled && (self.currentRequest.error == nil) && (error == nil) {
                    NSUserNotificationCenter.default.deliver(downloadNotification)
                    self.saveVideoToHistory(video: video!)
                } else {
                    print(self.currentRequest.error)
                }
                    
            
                    if error != nil {
                        if (error! as NSError).code != 499 {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.alertStyle = .critical
                            alert.messageText = "Could not save \(formatType)"
                            alert.informativeText = error!.localizedDescription
                            alert.runModal()
                        }
                        }
                    }
                
                self.setDownloadInterface(to: false)
                print(previousVideos.first?.name ?? "")
                }
            }
            
            downloader.downloadContent(with: currentRequest)
            //URLField.selec
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
            case true: // Animate showing downloading UI
                NSAnimationContext.runAnimationGroup({_ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = false
                    self.audioBox.animator().isHidden = true
                    self.controlsButton.animator().isHidden = true
                    self.recentVideosLabel.animator().isHidden = true
                    self.recentVideosDisclosureTriangle.animator().isHidden = true
                    self.formatPopup.animator().isHidden = true
                    self.downloadButton.isEnabled = false
                    (self.view.window?.windowController as! MainWindowController as MainWindowController).updateTBDownloadButton(withState: .off)
                    self.downloadLocationButton.isEnabled = false
                    //self.nameLabel.animator().isHidden = false
                    
                    self.mainProgressBar.animator().isHidden = false
                    self.stopButton.animator().isHidden = false
                }, completionHandler:{
                })
            case false: // Animate showing normal UI
                NSAnimationContext.runAnimationGroup({_ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = true
                    self.audioBox.animator().isHidden = false
                    self.controlsButton.animator().isHidden = false
                    self.downloadLocationButton.isEnabled = true
                    self.recentVideosLabel.animator().isHidden = false
                    self.recentVideosDisclosureTriangle.animator().isHidden = false
                    self.formatPopup.animator().isHidden = false
                    self.downloadButton.isEnabled = true
                    (self.view.window?.windowController as! MainWindowController as MainWindowController).updateTBDownloadButton(withState: .on)
                    
                    
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
                self.mainProgressBar.animator().increment(by: progress-self.mainProgressBar.doubleValue)
            }, completionHandler:{
            })
            if progress == 100.0 {
                print("progress at 100")
            }
        }
    }
    
    
}

extension ViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
            NSObject.cancelPreviousPerformRequests(
                   withTarget: self,
                   selector: #selector(ViewController.loadVideoFormats),
                   object: nil)
            self.perform(
                    #selector(ViewController.loadVideoFormats),
                    with: nil,
                    afterDelay: 0.6)
    }
}
