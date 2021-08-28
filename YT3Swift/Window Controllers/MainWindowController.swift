//
//  MainWindowController.swift
//  YT3Swift
//
//  Created by Jake Spann on 1/8/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTouchBarDelegate {
    
    var audioOnlyButton: NSButton?
    var downloadContentButton: NSButton?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if #available(OSX 10.13, *) {
            window?.backgroundColor = NSColor(named: "WindowBackground")
        } else {
            window?.backgroundColor = .white
        }
        
        window?.isMovableByWindowBackground = true
        window?.titlebarAppearsTransparent = true
    }
    
    func updateTBAudioButton(withState state: NSButton.StateValue) {
        if audioOnlyButton != nil {
            audioOnlyButton!.state = state
        }
    }
    
    func updateTBDownloadButton(withState state: NSButton.StateValue) {
        if downloadContentButton != nil {
            downloadContentButton!.isEnabled = (state == .on)
        }
    }
    
    @available(OSX 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.principalItemIdentifier = NSTouchBarItem.Identifier(rawValue: "downloadButton")
        touchBar.customizationIdentifier = "com.youtubetomac.touchbarbar"
        touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier("audioButton"), NSTouchBarItem.Identifier("downloadButton")/*NSTouchBarItem.Identifier("group")*/]
        
        return touchBar
    }
    
    @objc func handleButtonPress(sender: NSButton) {
        switch sender.identifier {
        case NSUserInterfaceItemIdentifier("audioTBButton"):
            (contentViewController as! ViewController).audioToggle(sender)
        case NSUserInterfaceItemIdentifier("downloadTBButton"):
            (contentViewController as! ViewController).startTasks(sender)
            sender.isEnabled = false
        default:
            break
        }
    }
    
    @available(OSX 10.12.1, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        var touchBarButton: NSCustomTouchBarItem?
        
        switch identifier {
        case NSTouchBarItem.Identifier("audioButton"):
            let audioButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "audioButton"))
            let button = NSButton(title: "Audio Only", target: self, action: #selector(handleButtonPress))
            audioOnlyButton = button
            button.setButtonType(.pushOnPushOff)
            button.identifier = NSUserInterfaceItemIdentifier(rawValue: "audioTBButton")
            audioButton.view = button
            
            touchBarButton = audioButton
        case NSTouchBarItem.Identifier("downloadButton"):
            let downloadTBButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "downloadButton"))
            let downloadButton = NSButton(title: "Download", target: self, action: #selector(handleButtonPress))
            downloadContentButton = downloadButton
            downloadButton.bezelColor = .red
            downloadButton.identifier = NSUserInterfaceItemIdentifier(rawValue: "downloadTBButton")
            downloadTBButton.view = downloadButton
            touchBarButton = downloadTBButton
        default:
            break
        }
        return touchBarButton
    }
    
}
