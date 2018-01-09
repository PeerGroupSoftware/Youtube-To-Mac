//
//  ViewController.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2017 Jake Spann. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var URLField: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var audioBox: NSButton!
    @IBOutlet weak var formatPopup: NSPopUpButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
    
    
    @IBOutlet weak var mainProgressBar: NSProgressIndicator!
    
    var isRunning = false
    var outputPipe:Pipe!
    var buildTask:Process!
    let defaultQOS = DispatchQoS.QoSClass.userInitiated
    
    @IBOutlet weak var actionButton: NSButton!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //buildTask.terminate()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    @IBAction func startTasks(_ sender: NSButton) {
        switch sender.integerValue {
        case 1:
            // print("1")
            if !URLField.stringValue.isEmpty{runScript([""])}
            
        default:
            //print("2")
            buildTask.terminate()
        }
    }
    
    
    func shell(_ args: String...) -> Int32 {
        let bundle = Bundle.main
      //  let path = bundle.path(forResource: "tor", ofType: "real")
        //let libpath = bundle.path(forResource: "libevent-2.0.5", ofType: "dylib")
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
                    self.URLField.animator().isHidden = true
                    self.audioBox.animator().isHidden = true
                    self.formatPopup.animator().isHidden = true
                    self.downloadButton.animator().isHidden = true
                    self.nameLabel.animator().isHidden = false
                    
                    self.mainProgressBar.animator().isHidden = false
                    self.stopButton.animator().isHidden = false
                    self.nameLabel.animator().isHidden = false
                }, completionHandler:{
                })
            case false:
                print("animate hiding")
                NSAnimationContext.runAnimationGroup({_ in
                    //Indicate the duration of the animation
                    NSAnimationContext.current.duration = 0.25
                    self.URLField.animator().isHidden = false
                    self.audioBox.animator().isHidden = false
                    self.formatPopup.animator().isHidden = false
                    self.downloadButton.animator().isHidden = false
                    
                    
                    self.mainProgressBar.animator().isHidden = true
                    self.stopButton.animator().isHidden = true
                    self.nameLabel.animator().isHidden = true
                }, completionHandler:{
                })
            }
        }
    }
    func updateDownloadProgressBar(progress: Double) {
        print("progress update \(progress)")
        DispatchQueue.main.async {
        self.mainProgressBar.doubleValue = progress
            if progress == 100 {self.toggleDownloadInterface(to: false)}
        }
    }
    
    func runScript(_ arguments:[String]) {
        let targetURL = URLField.stringValue
        
        //1.
        isRunning = true
        
        let taskQueue = DispatchQueue.global(qos: defaultQOS)
        
        
        //2.
        taskQueue.async {
            let bundle = Bundle.main
            //1.
            //guard let path = bundle.path(forResource: "tor.command", ofType: "command") else {
            //  print("Unable to locate BuildScript.command")
            //     return
            // }
            let path = bundle.path(forResource: "youtubedl2", ofType: "sh")
            //2.
            self.buildTask = Process()
            self.buildTask.launchPath = path
            self.buildTask.arguments = [targetURL]
            self.buildTask.currentDirectoryPath = "~/Desktop"
            self.buildTask.terminationHandler = {
                
                task in
                DispatchQueue.main.async(execute: {
                    // self.buildButton.isEnabled = true
                    // self.spinner.stopAnimation(self)
                    print("Stopped")
                    self.toggleDownloadInterface(to: false)
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
                   print(i.split(separator: ",").first?.replacingOccurrences(of: "\"", with: ""))
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
                print("download update")
                for i in (outputString.split(separator: " ")) {
                    if i.contains("%") {
                        self.updateDownloadProgressBar(progress:(Double(i.replacingOccurrences(of: "%", with: "")))!)
                    }
                }
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
