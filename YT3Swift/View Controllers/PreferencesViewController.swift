//
//  PreferencesViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 7/1/19.
//  Copyright © 2019 Peer Group Software. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

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
        //defaults.removeObject(forKey: "DownloadDestination") //Test Code
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
