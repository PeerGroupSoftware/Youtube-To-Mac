//
//  DownloadingPreferencesViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 8/12/20.
//  Copyright © 2026 Peer Group Software. All rights reserved.
//

import Cocoa

class DownloadingPreferencesViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        let destination = defaults.string(forKey: "DownloadDestination") ?? "desktop"

        let downloadsButton = view.subviews.first {
            ($0.identifier ?? NSUserInterfaceItemIdentifier("")).rawValue == "DownloadsRadio"
        } as? NSButton
        let desktopButton = view.subviews.first {
            ($0.identifier ?? NSUserInterfaceItemIdentifier("")).rawValue == "DesktopRadio"
        } as? NSButton

        if destination == "downloads" {
            downloadsButton?.state = .on
            desktopButton?.state = .off
        } else {
            desktopButton?.state = .on
            downloadsButton?.state = .off
        }
    }

    @IBAction func setDownloadDestination(_ sender: NSButton) {
        switch sender.identifier?.rawValue {
        case "DownloadsRadio":
            UserDefaults.standard.set("downloads", forKey: "DownloadDestination")
        default:
            UserDefaults.standard.set("desktop", forKey: "DownloadDestination")
        }
    }
}
