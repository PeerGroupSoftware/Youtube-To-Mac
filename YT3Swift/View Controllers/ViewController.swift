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

class ViewController: NSViewController, AppStateDelegate {
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
    private var popoverState: FormatControlsVC.URLState?
    private var popoverTitle: String?
    private var popoverFormats: [MediaFormat]?
    private var showingDownloadUI: Bool = false
    
    private let videoFormatsList = ["Auto", "Manual"] + Downloader.allFormats(for: .video, compatbility: .compatibleAndConvertable).compactMap({$0.rawValue})
    private let audioFormatsList = ["Auto", "Manual"] + Downloader.allFormats(for: .audio, compatbility: .compatibleAndConvertable).compactMap({$0.rawValue})
    private var selectedFormatVideo = "Auto"
    private var selectedFormatAudio = "Auto"
    
    
    
    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    //@IBOutlet weak var actionButton: NSButton!
    
    let downloader = Downloader()
    //var currentRequest = YTDownloadRequest()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }
    
    func appStateDidToggleAudioOnly(to newState: Bool) {
        //print("VC: audioOnly set to \(newState)")
        audioBox.state = newState ? .on : .off
        
        switch newState {
        case true:
            //print("set audio formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: audioFormatsList/*["Auto"] + Downloader.allFormats(for: .audio).compactMap({$0.rawValue})*/)
        case false:
            // print("set video formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: videoFormatsList/*["Auto"] + Downloader.allFormats(for: .video).compactMap({$0.rawValue})*/)
        }
        
        if formatPopup.selectedItem?.title == "Auto" {
            switch newState {
            case true:
                AppStateManager.shared.currentRequest.fileFormat = MediaFormat(fileExtension: .auto) //.auto//"wav/m4a/mp3/bestaudio"
                print("set to audio")
            case false:
                AppStateManager.shared.currentRequest.fileFormat = MediaFormat(fileExtension: .auto)//.auto//"mp4/flv/best"
                print("set to video")
            }
            
        }
    }
    
    func appStateDidEnableManualControls(_ newState: Bool) {
        if newState == true {
            formatPopup.selectItem(withTitle: "Manual")
        } else {
            if AppStateManager.shared.currentRequest.audioOnly {
                if !selectedFormatAudio.isEmpty {
                    formatPopup.selectItem(withTitle: selectedFormatAudio)
                }
            } else {
                if !selectedFormatVideo.isEmpty {
                    formatPopup.selectItem(withTitle: selectedFormatVideo)
                }
            }
        }
    }
    
    func appStateDidChange(to newState: AppState) {
        switch newState {
        case .waitingForURL:
            self.setDownloadInterface(to: false)
            //controlsButton.isEnabled = false
            AppStateManager.shared.setManualControls(enabled: false)
        case .downloading:
            setDownloadInterface(to: true)
        case .ready:
            controlsButton.isEnabled = true
        default:
            break
        }
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
        
        AppStateManager.shared.registerForEvents(self)
        
        let videoHistory = (UserDefaults().dictionary(forKey: "YTVideoHistory") as? [String:[String:String]] ?? [String:[String:String]]()).reversed()
        //print(videoHistory)
        for item in videoHistory {
            let newVideo = YTVideo()
            newVideo.title = item.key
            newVideo.url = (item.value.first?.key)!
            newVideo.diskPath = (item.value.first?.value)!
            previousVideos.append(newVideo)
        }
        previousVideosTableView.reloadData()
        
        let recentVideosLabelGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(changeWindowSizeLabel))
        recentVideosLabel.addGestureRecognizer(recentVideosLabelGestureRecognizer)
    }
    
    @objc func getBasicVideoInfo() {
        loadVideoFormats()
        getVideoTitle()
    }
    
    func getVideoTitle() {
        downloader.getTitle(for: YTVideo(name: "", url: URLField.stringValue), completion: { [self](title, error) in
            //if title != nil {
            print("GOT VIDEO TITLE")
            setControlsPopoverTitle(to: title)
            // }
        })
    }
    
    @objc func loadVideoFormats() {
        if URLField.stringValue.containsURL() {
            DispatchQueue.main.async {
                if !(self.controlsPopover?.isShown ?? false) {
                    if AppStateManager.shared.state != .downloading {
                        self.controlsLoadingIndicator.startAnimation(self)
                    }
                    self.controlsButton.isHidden = true
                } else {
                    //(self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.loading)
                    self.setControlsPopoverState(to: .loading)
                }
            }
            
            downloader.getFormats(for: YTVideo(name: "", url: URLField.stringValue), formatType: .compatibleAndConvertable, completion: {(formats, error) in
                print("formats: \(formats)")
                
                DispatchQueue.main.async {
                    //print("controls popover: \(self.controlsPopover)")
                    if !(self.controlsPopover?.isShown ?? false) {
                        print("controls popover is shown or nil")
                        if !formats.isEmpty {self.controlsButton.isEnabled = true}
                        self.controlsLoadingIndicator.stopAnimation(self)
                        if !self.showingDownloadUI {
                            self.controlsButton.isHidden = false
                        }
                    }
                    if formats.isEmpty {
                        print("Found formats is empty")
                        //if self.controlsPopover != nil {
                        //(self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.waiting)
                        self.setControlsPopoverState(to: .waiting)
                        AppStateManager.shared.setAppState(to: .waitingForURL)
                        // }
                    } else {
                        print("Found formats is NOT empty")
                        //if self.controlsPopover != nil {
                        //(self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.found)
                        self.setControlsPopoverState(to: .found)
                        AppStateManager.shared.setAppState(to: .ready)
                        //}
                        AppStateManager.shared.currentRequest.directFormats = formats
                        self.setControlsPopoverFormats(to: formats)
                    }
                    
                }
                //let directUsableFormats = formats.filter({[YTCodec.mp4a, YTCodec.avc1].contains($0.codec)})
                //print(formats.sorted(by: {($0.size?.height ?? 0)<($1.size?.height ?? 0)}))
            })
        } else {
            print("No URL detected")
            /*if self.controlsPopover != nil {
             (self.controlsPopover?.contentViewController as! FormatControlsVC).setURLState(.waiting)
             }*/
            setControlsPopoverState(to: .waiting)
        }
    }
    
    func setControlsPopoverState(to newState: FormatControlsVC.URLState) {
        print("Requesting new state \(newState)")
        popoverState = newState
        if self.controlsPopover != nil {
            (controlsPopover?.contentViewController as! FormatControlsVC).setURLState(newState)
        }
    }
    
    func setControlsPopoverTitle(to newTitle: String?) {
        print("Requesting new popover title \(newTitle)")
        popoverTitle = newTitle
        if self.controlsPopover != nil {
            DispatchQueue.main.async {(self.controlsPopover?.contentViewController as! FormatControlsVC).updateVideoTitle(to: newTitle)}
        }
    }
    
    func setControlsPopoverFormats(to newFormats: [MediaFormat]) {
        print("Requesting new popover formats")
        popoverFormats = newFormats
        if self.controlsPopover != nil {
            DispatchQueue.main.async {(self.controlsPopover?.contentViewController as! FormatControlsVC).display(formats: newFormats)}
        }
    }
    
    @IBAction func videoControlsPopover(_ sender: NSButton) {
        if controlsPopover == nil {
            let popoverVC = NSStoryboard.main?.instantiateController(withIdentifier: "ContentControlsPopover") as! FormatControlsVC
            popoverVC.mainVC = self
            let popover = NSPopover()
            popover.contentViewController = popoverVC
            popover.behavior = .semitransient
            controlsPopover = popover
        }
        
        if (controlsPopover?.isShown ?? false) {
            controlsPopover?.performClose(self)
        } else {
            controlsPopover!.show(relativeTo: sender.frame, of: view, preferredEdge: .minY)
            (controlsPopover?.contentViewController as! FormatControlsVC).setURLState(popoverState ?? .waiting)
            (controlsPopover?.contentViewController as! FormatControlsVC).updateVideoTitle(to: popoverTitle)
            (controlsPopover?.contentViewController as! FormatControlsVC).display(formats: popoverFormats ?? [], audioOnly: (audioBox.state == .on))
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
        videoHistory.updateValue([targetVideo.url:targetVideo.diskPath], forKey: targetVideo.title)
        UserDefaults().set(videoHistory, forKey: "YTVideoHistory")
        
        previousVideos.insert(targetVideo, at: 0)
        self.previousVideosTableView.insertRows(at: IndexSet(integer: 0), withAnimation: NSTableView.AnimationOptions.slideDown)
        
    }
    
    @IBAction func toggleWindowSize(_ sender: NSButton) {
        
        switch (sender.state) {
        //Expand window
        case .on:
            previousVideosTableView.isHidden = false //This should stay outside of animation
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.5
                if previousVideosTableView.numberOfRows != 0 {clearTableViewButton.animator().isHidden = false}
            })
            // let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!-106, width: 422, height: 309)
            //bigConstraint.animator().constant = CGFloat(bottomConstraintConstant)
            // print(bottomConstraintConstant)
            //view.window?.setFrame(newWindowFrame, display: true, animate: true)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                //clearTableViewButton.animator().isHidden = true
                bigConstraint.animator().constant = CGFloat(bottomConstraintConstant)
            }, completionHandler:{
            })
            //Collapse window
        case .off:
            //let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
            
            // view.window?.setFrame(newWindowFrame, display: true, animate: true)
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                clearTableViewButton.animator().isHidden = true
                previousVideosTableView.animator().isHidden = true
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
        
        let newButton = NSButton(title: "Reset to Default", target: nil, action: nil)
        newButton.isEnabled = false
        locationSelectPanel.accessoryView = newButton
        locationSelectPanel.isAccessoryViewDisclosed = true
        
        locationSelectPanel.beginSheetModal(for: view.window!, completionHandler: {(result) in
            if(result.rawValue == NSApplication.ModalResponse.OK.rawValue){
                let path = locationSelectPanel.url!.path
                print("selected folder is \(path)")
                AppStateManager.shared.currentRequest.destination = URL(fileURLWithPath: path)
            }
        })
        
        
    }
    
    @IBAction func formatSelectionChanged(_ sender: NSPopUpButton) {
        if  !["Auto", "Manual"].contains(sender.selectedItem?.title) {
            AppStateManager.shared.currentRequest.fileFormat = MediaFormat(fileExtension: MediaExtension(rawValue:(sender.selectedItem?.title)!)!)
        /*} else {
            switch audioBox.integerValue {
            case 1:
                print("set to \(sender.titleOfSelectedItem ?? "") (audio)")
                selectedFormatAudio = sender.titleOfSelectedItem ?? ""
            case 0:
                // AppStateManager.shared.currentRequest.fileFormat = .defaultVideo//"mp4/flv/best"
                print("set to \(sender.titleOfSelectedItem ?? "") (video)")
                selectedFormatVideo = sender.titleOfSelectedItem ?? ""
            default:
                print("audio box error")
            }*/
            
        }
        switch audioBox.integerValue {
        case 1:
            print("set to \(sender.titleOfSelectedItem ?? "") (audio)")
            if sender.titleOfSelectedItem != "Manual" {selectedFormatAudio = sender.titleOfSelectedItem ?? ""}
        case 0:
            // AppStateManager.shared.currentRequest.fileFormat = .defaultVideo//"mp4/flv/best"
            print("set to \(sender.titleOfSelectedItem ?? "") (video)")
            if sender.titleOfSelectedItem != "Manual" {selectedFormatVideo = sender.titleOfSelectedItem ?? ""}
        default:
            print("audio box error")
        }
        
        //if sender.titleOfSelectedItem != "Manual" {
            if self.controlsPopover != nil {
                //(controlsPopover?.contentViewController as! FormatControlsVC).didChangeManualControlsEnabled(to: sender.titleOfSelectedItem == "Manual")
                AppStateManager.shared.setManualControls(enabled: sender.titleOfSelectedItem == "Manual")
            }
    //  }
    }
    
    func setControlsPopoverAudioOnly(_ isAudioOnly: Bool) {
        //print("Requesting new state \(newState)")
        //popoverState = newState
        if self.controlsPopover != nil {
            (controlsPopover?.contentViewController as! FormatControlsVC).setIsAudioOnly(to: isAudioOnly)
        }
    }
    
    @IBAction func audioToggle(_ sender: NSButton) {
        
        AppStateManager.shared.setAudioOnly(to: sender.state == .on)
        
       /* if sender.identifier?.rawValue == "audioTBButton" {
            audioBox.state = sender.state
        } else {
            (view.window?.windowController as! MainWindowController as MainWindowController).updateTBAudioButton(withState: sender.state)
        }*/
        
        //setControlsPopoverAudioOnly(sender.state == .on)
        //currentRequest.audioOnly = sender.state == .on
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func startDownload(_ sender: NSButton) {
        AppStateManager.shared.currentRequest.contentURL = URLField.stringValue
        //currentRequest.audioOnly = AppStateManager.shared.currentRequest.audioOnly
        AppStateManager.shared.currentRequest.error = nil
        
        if AppStateManager.shared.currentRequest.fileFormat.videoOnly {
            AppStateManager.shared.currentRequest.fileFormat.secondaryFormatID = AppStateManager.shared.currentRequest.directFormats.first(where: {$0.audioOnly == true && $0.fileExtension == .m4a})?.id
            print("Got secondary format id \(AppStateManager.shared.currentRequest.fileFormat.secondaryFormatID)")
        }
        
        /*if AppStateManager.shared.manualControlsEnabled {
            AppStateManager.shared.currentRequest.fileFormat =
        }*/
        
        //currentRequest.fileFormat = AppStateManager.shared.currentRequest.fileFormat
        print("CRFF: \(AppStateManager.shared.currentRequest.fileFormat)")
        
        //print("destination: \(currentRequest.destination)")
        if AppStateManager.shared.currentRequest.destination == Downloader.desktopFolder || AppStateManager.shared.currentRequest.destination == Downloader.downloadsFolder {
            if (UserDefaults.standard.string(forKey: "DownloadDestination") ?? "") == "downloads" {
                AppStateManager.shared.currentRequest.destination = Downloader.downloadsFolder//"~/Downloads"
            } else {
                AppStateManager.shared.currentRequest.destination = Downloader.desktopFolder
            }
        }
        
        if !AppStateManager.shared.currentRequest.contentURL.isEmpty {
            //setDownloadInterface(to: true)
            AppStateManager.shared.setAppState(to: .downloading)
            
            AppStateManager.shared.currentRequest.progressHandler = {(progress, error, videoInfo) in
                DispatchQueue.main.async {
                    if progress >= 0 {
                        self.updateDownloadProgressBar(progress: progress, errorOccured: (error != nil))
                        if progress == 100 && videoInfo != nil {
                            //self.setDownloadInterface(to: false)
                            //AppStateManager.shared.setAppState(to: .waitingForURL)
                        }
                    } else if progress != 100 {
                        DispatchQueue.main.async {self.URLField.stringValue = videoInfo!.title}
                    }
                }
            }
            
            AppStateManager.shared.currentRequest.completionHandler = { (video, error) in
                //print("COMPLETION HANDLER")
                //print("DOWNLOADED: \(video?.title)")
                DispatchQueue.main.async {
                    self.URLField.stringValue = ""
                    sender.isEnabled = true
                    
                    let downloadNotification = NSUserNotification()
                    let formatType = (self.audioBox.state == .on) ? "Audio" : "Video"
                    var downloadDestination = ""
                    if AppStateManager.shared.currentRequest.destination == Downloader.desktopFolder {
                        downloadDestination = "Desktop"
                    } else if AppStateManager.shared.currentRequest.destination == Downloader.downloadsFolder {
                        downloadDestination = "Downloads"
                    }
                    
                    var informativeText = ""
                    if UserDefaults.standard.bool(forKey: "shouldShowTitleInNotification") {
                        informativeText = video?.title ?? ""
                    } else {
                        if !downloadDestination.isEmpty {
                            informativeText = "Saved \(formatType.lowercased()) to \(downloadDestination)"
                        } else {
                            informativeText = "Saved \(formatType.lowercased())"
                        }
                    }
                    
                    downloadNotification.title = "Downloaded \(formatType)"
                    downloadNotification.informativeText = informativeText
                    downloadNotification.soundName = NSUserNotificationDefaultSoundName
                    
                    if self.downloadButton.isEnabled && (AppStateManager.shared.currentRequest.error == nil) && (error == nil) {
                        NSUserNotificationCenter.default.deliver(downloadNotification)
                        if video != nil {
                            self.saveVideoToHistory(video: video!)
                        }
                    } else {
                        print(AppStateManager.shared.currentRequest.error)
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
                    
                    //self.setDownloadInterface(to: false)
                    AppStateManager.shared.setAppState(to: .waitingForURL)
                    print(previousVideos.first?.title ?? "")
                }
            }
            
            downloader.downloadContent(with: AppStateManager.shared.currentRequest)
            //URLField.selec
        } else {
            if (sender.identifier?.rawValue) ?? "" == "downloadTBButton" {
                DispatchQueue.main.async {sender.isEnabled = true}
            }
        }
    }
    
    
    @IBAction func stopButton(_ sender: NSButton) {
        downloader.terminateDownload()
        //setDownloadInterface(to: false)
        AppStateManager.shared.setAppState(to: .waitingForURL)
    }
    
    func setDownloadTitleStatus(to downloadName: String) {
        
    }
    
    func setDownloadInterface(to isDownloading: Bool) {
        showingDownloadUI = isDownloading
        DispatchQueue.main.async {
            switch isDownloading {
            case true: // Animate showing downloading UI
                NSAnimationContext.runAnimationGroup({_ in
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.isEditable = false
                    self.audioBox.animator().isHidden = true
                    //self.button
                    self.controlsButton.animator().isHidden = true
                    self.controlsPopover?.performClose(self)
                    self.controlsLoadingIndicator.stopAnimation(self)
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
            selector: #selector(ViewController.getBasicVideoInfo),
            object: nil)
        self.perform(
            #selector(ViewController.getBasicVideoInfo),
            with: nil,
            afterDelay: 0.6)
    }
}
