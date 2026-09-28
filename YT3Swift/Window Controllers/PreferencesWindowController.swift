//
//  PreferencesWindowController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 7/1/19.
//  Copyright © 2026 Peer Group Software. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        if #available(macOS 10.13, *) {
            window?.backgroundColor = NSColor(named: "WindowBackground")
        } else {
            window?.backgroundColor = .white
        }

        window?.isMovableByWindowBackground = true
        window?.titlebarAppearsTransparent = true
    }
}
