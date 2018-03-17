//
//  ViewController.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2017 Jake Spann. All rights reserved.
//

import Cocoa

let previousVideosTableController = PreviousTableViewController()

class ViewController: NSViewController {
    @IBOutlet weak var URLField: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var audioBox: NSButton!
    @IBOutlet weak var formatPopup: NSPopUpButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var downloadLocationButton: NSButton!
    @IBOutlet weak var previousVideosTableView: NSTableView!
    @IBOutlet weak var recentVideosLabel: NSTextField!
    @IBOutlet weak var recentVideosDisclosureTriangle: NSButton!
    
    
    
    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    
    var isRunning = false
    var videoID = ""
    var fileFormat = "mp4/flv/best" // Default video file format
    var videoTitle = ""
    var saveLocation = "~/Desktop"
    var currentVideo = YTVideo()
    var outputPipe:Pipe!
    var buildTask:Process!
    var formatTask:Process!
    let videoFormats = ["Auto", "mp4", "flv", "webm"]
    let audioFormats = ["Auto", "m4a", "mp3", "wav", "aac"]
    let defaultQOS = DispatchQoS.QoSClass.userInitiated
    
    @IBOutlet weak var actionButton: NSButton!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        /*let passwordBorder = CALayer()
        let passwordWidth = CGFloat(2.0)
        passwordBorder.borderColor = UIColor.lightGray.cgColor
        passwordBorder.frame = CGRect(x: 0, y: passwordField.frame.size.height - passwordWidth, width:  passwordField.frame.size.width, height: passwordField.frame.size.height)
        
        passwordBorder.borderWidth = passwordWidth
        passwordField.layer.addSublayer(passwordBorder)
        passwordField.layer.masksToBounds = true*/
    }
    override func viewDidLoad() {
        URLField.focusRingType = .none
        URLField.underlined()
        
        print("set video formats")
        formatPopup.removeAllItems()
        formatPopup.addItems(withTitles: videoFormats)
        
        downloadLocationButton.folderButton()
        
        previousVideosTableView.delegate = previousVideosTableController
        previousVideosTableView.dataSource = previousVideosTableController
        
        //URLField.beginDocument()
        
        
        
        
        
        
    }
    @IBAction func toggleWindowSize(_ sender: NSButton) {
        //print(view.window?.frame.height)
        switch (sender.integerValue) {
        case 1:
             let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!-106, width: 422, height: 309)
            view.window?.setFrame(newWindowFrame, display: true, animate: true)
        case 0:
            let newWindowFrame = NSRect(x: (view.window?.frame.minX)!, y: (view.window?.frame.minY)!+106, width: 422, height: 106)
            view.window?.setFrame(newWindowFrame, display: true, animate: true)
        default:
            print("discosure arrow error")
        }
    }
    @IBAction func changeDownloadLocation(_ sender: NSButton) {
            let locationSelectPanel = NSOpenPanel()
           // openPanel.title = ""
           // openPanel.message = ""
            locationSelectPanel.showsResizeIndicator=true
            locationSelectPanel.canChooseDirectories = true
            locationSelectPanel.canChooseFiles = false
            locationSelectPanel.allowsMultipleSelection = false
            locationSelectPanel.canCreateDirectories = true
        locationSelectPanel.beginSheetModal(for: view.window!, completionHandler: {(result) in
            if(result.rawValue == NSApplication.ModalResponse.OK.rawValue){
                let path = locationSelectPanel.url!.path
                print("selected folder is \(path)")
                self.saveLocation = path
        }
        })
       /* locationSelectPanel.begin { (result) -> Void in
 
                }*/
            
        
    }
    @IBAction func formatSelectionChanged(_ sender: NSPopUpButton) {
        if sender.selectedItem?.title != "Auto" {
            fileFormat = (sender.selectedItem?.title)!
        } else {
            switch audioBox.integerValue {
            case 1:
                fileFormat = "wav/m4a/mp3/bestaudio"
                print("set to audio")
            case 0:
                fileFormat = "mp4/flv/best"
                print("set to video")
            default:
                print("audio box error")
            }
            
        }
    }
    @IBAction func audioToggle(_ sender: NSButton) {
        switch sender.integerValue {
        case 1:
            print("set audio formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: audioFormats)
        case 0:
            print("set video formats")
            formatPopup.removeAllItems()
            formatPopup.addItems(withTitles: videoFormats)
        default:
                print("Audio button error")
        }
        if formatPopup.selectedItem?.title == "Auto" {
            switch sender.integerValue {
            case 1:
                fileFormat = "wav/m4a/mp3/bestaudio"
                print("set to audio")
            case 0:
                fileFormat = "mp4/flv/best"
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
            // print("1")
            if !URLField.stringValue.isEmpty{runScript([""])}
    }
    
    
    func shell(_ args: String...) -> Int32 {
        //let bundle = Bundle.main

        let task = Process()
     //   task.launchPath = path
        //task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    @IBAction func stopButton(_ sender: NSButton) {
        if buildTask.isRunning == true {
            buildTask.terminate()
        } else {
            print("thread not running")
        }
        
    }
    
    func setDownloadTitleStatus(to downloadName: String) {
        
    }
    func toggleDownloadInterface(to: Bool) {
        DispatchQueue.main.async {
            switch to {
            case true:
                print("animate showing")
                NSAnimationContext.runAnimationGroup({_ in
                    //Indicate the duration of the animation
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
                   // self.nameLabel.animator().isHidden = false
                }, completionHandler:{
                })
            case false:
                print("animate hiding")
                NSAnimationContext.runAnimationGroup({_ in
                    //Indicate the duration of the animation
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
    func updateDownloadProgressBar(progress: Double) {
        print("progress update \(progress)")
        DispatchQueue.main.async {
        self.mainProgressBar.doubleValue = progress
            if progress == 100 {
                print("progressUpate")
                self.toggleDownloadInterface(to: false)
                print(previousVideos.first?.name ?? "")
                print(self.currentVideo.name)
                if previousVideos.first?.name ?? "" != self.currentVideo.name {
                    print("adding to list")
                    print(self.currentVideo.name)
                previousVideos.insert(self.currentVideo, at: 0)
                    self.previousVideosTableView.insertRows(at: IndexSet(integer: 0), withAnimation: NSTableView.AnimationOptions.slideDown)
                }
            }
        }
    }
    
    func runScript(_ arguments:[String]) {
        let targetURL = URLField.stringValue
        currentVideo.URL = targetURL
        
        //1.
        isRunning = true
        
        let taskQueue = DispatchQueue.global(qos: defaultQOS)
        
        
        taskQueue.async { // Get file formats
            
            let path = Bundle.main.path(forResource: "youtubedl2", ofType: "sh")
            //2.
            self.formatTask = Process()
//            self.formatTask.launchPath = path
//            //  print("using file format \(self.fileFormat)")
//            self.formatTask.arguments = ["--dump-json", targetURL]
//            self.formatTask.currentDirectoryPath = self.saveLocation
//            self.formatTask.terminationHandler = {
//
//                task in
//                DispatchQueue.main.async(execute: {
//                    // self.buildButton.isEnabled = true
//                    // self.spinner.stopAnimation(self)
//                    print("Stopped")
//                    //self.updateDownloadProgressBar(progress: 0.0)
//                   // self.toggleDownloadInterface(to: false)
//                    self.currentVideo = YTVideo()
//                   // self.URLField.stringValue = ""
//                    if self.outputPipe.description.contains("must provide") {
//                        print("123354657")
//                    }
//                    //self.isRunning = false
            
                    taskQueue.async {
                        
                        let path = Bundle.main.path(forResource: "youtubedl2", ofType: "sh")
                        //2.
                        self.buildTask = Process()
                        self.buildTask.launchPath = path
                        print("using file format \(self.fileFormat)")
                        self.buildTask.arguments = ["-f \(self.fileFormat)", targetURL]
                        self.buildTask.currentDirectoryPath = self.saveLocation
                        self.buildTask.terminationHandler = {
                            
                            task in
                            DispatchQueue.main.async(execute: {
                                // self.buildButton.isEnabled = true
                                // self.spinner.stopAnimation(self)
                                print("Stopped")
                                self.updateDownloadProgressBar(progress: 0.0)
                                self.toggleDownloadInterface(to: false)
                                self.currentVideo = YTVideo()
                                self.URLField.stringValue = ""
                                if self.outputPipe.description.contains("must provide") {
                                    print("123354657")
                                }
                                self.isRunning = false
                            })
                            
                        }
                        
                        self.captureStandardOutputAndRouteToTextView(self.buildTask)
                        self.toggleDownloadInterface(to: true)
                        self.buildTask.launch()
                        self.buildTask.waitUntilExit()
                        
                    }
                    
              //  })
                
          //  }
            
//            self.captureStandardOutputAndRouteToTextView(self.formatTask)
//            self.toggleDownloadInterface(to: true)
//            self.formatTask.launch()
//            self.formatTask.waitUntilExit()
    
        }
        
        
        
        //2.
        
        
        
        
    }
    
    
    func captureStandardOutputAndRouteToTextView(_ task:Process) {
        
        //1.
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        //2.
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        //3.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            //4.
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            print(outputString)
            if outputString.contains("fulltitle") {
                for i in (outputString.split(separator: ":")) {
                   (i.split(separator: ",").first?.replacingOccurrences(of: "\"", with: ""))
                }
            }
            if outputString.range(of:"100%: Done") != nil {
                self.buildTask.qualityOfService = .background
                print("Successfully established circut. Set QOS to background")
                NSAppleScript(source: "do shell script \"sudo say hi\" with administrator " +
                    "privileges")!.executeAndReturnError(nil)
            } else if outputString.range(of:"must provide") != nil {
                print("There was some kind of error")
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    var videonameString = (outputString.replacingOccurrences(of: "[download] Destination: ", with: ""))
                    
                    print(videonameString.distance(from: (videonameString.range(of: ("-" + self.videoID))?.lowerBound)!, to: videonameString.endIndex))
                    
                    videonameString.removeSubrange((videonameString.range(of: ("-" + self.videoID))?.lowerBound)!..<videonameString.endIndex)
                    //self.videoTitle = (videonameString)
                    self.currentVideo.name = videonameString
                    DispatchQueue.main.async {
                        self.URLField.stringValue = self.currentVideo.name
                        print("adding name to field")
                    }
                } else {
                print("download update")
                for i in (outputString.split(separator: " ")) {
                    if i.contains("%") {
                        self.updateDownloadProgressBar(progress:(Double(i.replacingOccurrences(of: "%", with: "")))!)
                    }
                }
                }
            } else if outputString.contains("[youtube]") && outputString.contains("Downloading webpage") {
            self.videoID = ((outputString.split(separator: " "))[1].replacingOccurrences(of: ":", with: ""))
            }
            
            //5.
            DispatchQueue.main.async(execute: {
                // let previousOutput = self.outputText.string ?? ""
                // let nextOutput = previousOutput + "\n" + outputString
                // self.outputText.string = nextOutput
                
                // let range = NSRange(location:nextOutput.characters.count,length:0)
                // self.outputText.scrollRangeToVisible(range)
                
            })
            
            //6.
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
            
        }
    }
    
    
    
}

class URLFieldCell: NSTextFieldCell {
    
    @IBInspectable var rightPadding: CGFloat = 10.0
    
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let rectInset = NSMakeRect(rect.origin.x + rightPadding, rect.origin.y, rect.size.width - rightPadding, rect.size.height)
        return super.drawingRect(forBounds: rectInset)
    }
}
