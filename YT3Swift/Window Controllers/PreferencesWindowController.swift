//
//  PreferencesWindowController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 7/1/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSToolbarDelegate {
    
    @IBAction func clickedTab(_ sender: NSToolbarItem) {
        /*switch (sender.itemIdentifier) {
        case NSToolbarItem.Identifier("General"):
            //(contentViewController as! GeneralVC).containerView
        case "Downloading":
        }*/
    }
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.toolbar!.delegate = self
    
        if #available(OSX 10.13, *) {
            window?.backgroundColor = NSColor(named: "WindowBackground")
        } else {
            window?.backgroundColor = .white
        }
        
        window?.isMovableByWindowBackground = true
        window?.titlebarAppearsTransparent = true

    }

}
