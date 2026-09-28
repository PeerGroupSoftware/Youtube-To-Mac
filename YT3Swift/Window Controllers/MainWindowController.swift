//
//  MainWindowController.swift
//  YT3Swift
//
//  Created by Jake Spann on 1/8/18.
//  Copyright © 2026 Peer Group. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTouchBarDelegate {

    var audioOnlyButton: NSButton?
    var downloadContentButton: NSButton?

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

    func updateTBAudioButton(withState state: NSButton.StateValue) {
        audioOnlyButton?.state = state
    }

    func setIsDownloading(downloading: Bool) {
        audioOnlyButton?.isEnabled = !downloading
    }

    func updateTBDownloadButton(withState state: NSButton.StateValue) {
        downloadContentButton?.isEnabled = (state == .on)
    }

    @available(macOS 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.principalItemIdentifier = NSTouchBarItem.Identifier(rawValue: "downloadButton")
        touchBar.customizationIdentifier = "com.youtubetomac.touchbarbar"
        touchBar.defaultItemIdentifiers = [
            NSTouchBarItem.Identifier("audioButton"),
            NSTouchBarItem.Identifier("downloadButton")
        ]
        return touchBar
    }

    @objc func handleButtonPress(sender: NSButton) {
        guard let viewController = contentViewController as? ViewController else { return }
        switch sender.identifier {
        case NSUserInterfaceItemIdentifier("audioTBButton"):
            viewController.audioToggle(sender)
        case NSUserInterfaceItemIdentifier("downloadTBButton"):
            viewController.startTasks(sender)
            sender.isEnabled = false
        default:
            break
        }
    }

    @available(macOS 10.12.1, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier("audioButton"):
            let audioButton = NSCustomTouchBarItem(identifier: NSTouchBarItem.Identifier(rawValue: "audioButton"))
            let button = NSButton(title: "Audio Only", target: self, action: #selector(handleButtonPress))
            audioOnlyButton = button
            button.setButtonType(.pushOnPushOff)
            button.identifier = NSUserInterfaceItemIdentifier(rawValue: "audioTBButton")
            audioButton.view = button
            return audioButton
        case NSTouchBarItem.Identifier("downloadButton"):
            let downloadTBButton = NSCustomTouchBarItem(identifier: NSTouchBarItem.Identifier(rawValue: "downloadButton"))
            let downloadButton = NSButton(title: "Download", target: self, action: #selector(handleButtonPress))
            downloadContentButton = downloadButton
            downloadButton.bezelColor = .systemRed
            downloadButton.identifier = NSUserInterfaceItemIdentifier(rawValue: "downloadTBButton")
            downloadTBButton.view = downloadButton
            return downloadTBButton
        default:
            return nil
        }
    }
}
