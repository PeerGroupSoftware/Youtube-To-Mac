//
//  MainWindowController.swift
//  YT3Swift
//
//  Created by Jake Spann on 1/8/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        if #available(OSX 10.13, *) {
            window?.backgroundColor = NSColor(named: "WindowBackground")
        } else {
            window?.backgroundColor = .white
        }
        window?.isMovableByWindowBackground = true
        
       //self.window?.appearance = NSAppearance(named: NSAppearance.Name.li)
        window?.titlebarAppearsTransparent = true
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
