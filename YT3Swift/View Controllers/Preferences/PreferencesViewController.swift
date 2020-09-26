//
//  PreferencesViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 7/1/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var automaticUpdatesBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "automaticUpdateCheck") == nil || defaults.bool(forKey: "automaticUpdateCheck") == true {
            automaticUpdatesBox.state = .on
        }
    }
    
    @IBAction func toggleAutoUpdates(_ sender: NSButton) {
        switch sender.state {
        case .on:
            UserDefaults.standard.set(true, forKey: "automaticUpdateCheck")
        case .off:
            UserDefaults.standard.set(false, forKey: "automaticUpdateCheck")
        default:
            UserDefaults.standard.set(true, forKey: "automaticUpdateCheck")
        }
    }
    
}
