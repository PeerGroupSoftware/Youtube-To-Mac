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
        //print(defaults.string(forKey: "DownloadDestination")!)
        
        switch defaults.string(forKey: "DownloadDestination") ?? "" {
        case "downloads":
            (view.subviews.first(where: {($0.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "")).rawValue == "DownloadsRadio"}) as! NSButton).state = .on
        default:
            (view.subviews.first(where: {($0.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "")).rawValue == "DesktopRadio"}) as! NSButton).state = .on
        }
        
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
    
    @IBAction func setDownloadDestination(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        //print(sender.identifier?.rawValue)
        
        switch sender.identifier!.rawValue {
        case "DownloadsRadio":
            defaults.set("downloads", forKey: "DownloadDestination")
        case "DesktopRadio":
            defaults.set("desktop", forKey: "DownloadDestination")
        default:
            defaults.set("desktop", forKey: "DownloadDestination")
        }
        //defaults.synchronize()
    }
    
}
