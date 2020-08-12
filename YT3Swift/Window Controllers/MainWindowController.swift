//
//  MainWindowController.swift
//  YT3Swift
//
//  Created by Jake Spann on 1/8/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Cocoa

fileprivate extension NSTouchBarItem.Identifier {
    static let champagne = NSTouchBarItem.Identifier("champagne")
    static let cocktail = NSTouchBarItem.Identifier("cocktail")
    static let beer = NSTouchBarItem.Identifier("beer")
    static let martini = NSTouchBarItem.Identifier("martini")
}

class MainWindowController: NSWindowController, NSTouchBarDelegate {
    
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
    
    @available(OSX 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.principalItemIdentifier = NSTouchBarItem.Identifier(rawValue: "group")
        touchBar.customizationIdentifier = "com.youtubetomac.touchbarbar"
        touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier("group")]
        
        return touchBar
    }
    
    @objc func Isaac(sender: NSButton) {
        switch sender.identifier {
        case NSUserInterfaceItemIdentifier("audioTBButton"):
            print("audio")
            (contentViewController as! ViewController).audioToggle(sender)
        case NSUserInterfaceItemIdentifier("downloadTBButton"):
            print("download")
            (contentViewController as! ViewController).startTasks(sender)
            sender.isEnabled = false
        default:
            break
        }
    }
    
    @available(OSX 10.12.1, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let audioButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "audioButton"))
        let button = NSButton(title: "Audio Only", target: self, action: #selector(Isaac))
        button.setButtonType(.pushOnPushOff)
        button.identifier = NSUserInterfaceItemIdentifier(rawValue: "audioTBButton")
        audioButton.view = button
        
        let downloadTBButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "downloadButton"))
        let downloadButton = NSButton(title: "Download", target: self, action: #selector(Isaac))
        downloadButton.bezelColor = .red
        downloadButton.identifier = NSUserInterfaceItemIdentifier(rawValue: "downloadTBButton")
        downloadTBButton.view = downloadButton
        
        let itemGroup = NSGroupTouchBarItem(identifier: NSTouchBarItem.Identifier(rawValue: "group"), items: [audioButton, downloadTBButton])
        return itemGroup
        /*
         let touchBarItem = NSCustomTouchBarItem(identifier: identifier)
         switch identifier {
         case NSTouchBarItem.Identifier.champagne:
         let button = NSButton(title: "Audio Only", target: self, action: #selector(Isaac))
         button.setButtonType(.pushOnPushOff)
         touchBarItem.view = button
         return touchBarItem
         
         case NSTouchBarItem.Identifier.beer:
         let button = NSButton(title: "Download", target: self, action: #selector(Isaac))
         
         button.bezelColor = .red
         
         touchBarItem.view = button
         return touchBarItem
         case NSTouchBarItem.Identifier.cocktail:
         let button = NSButton(title: "🍹", target: self, action: #selector(Isaac))
         touchBarItem.view = button
         return touchBarItem
         case NSTouchBarItem.Identifier.martini:
         let button = NSButton(title: "🍸", target: self, action: #selector(Isaac))
         touchBarItem.view = button
         return touchBarItem
         default:
         let button = NSButton(title: "🍹", target: self, action: #selector(Isaac))
         touchBarItem.view = button
         return touchBarItem
         }*/
    }
    
}
