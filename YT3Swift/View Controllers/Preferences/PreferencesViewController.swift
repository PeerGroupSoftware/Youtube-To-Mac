//
//  PreferencesViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 7/1/19.
//  Copyright © 2026 Peer Group Software. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var automaticUpdatesBox: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "automaticUpdateCheck") == nil || defaults.bool(forKey: "automaticUpdateCheck") {
            automaticUpdatesBox.state = .on
        } else {
            automaticUpdatesBox.state = .off
        }
    }

    @IBAction func toggleAutoUpdates(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "automaticUpdateCheck")
    }
}
