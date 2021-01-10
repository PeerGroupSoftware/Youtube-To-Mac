//
//  DownloadingPreferencesViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 8/12/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Cocoa

class DownloadingPreferencesViewController: NSViewController {
    @IBOutlet weak var showContentTitleNotificationCheckbox: NSButton!
    
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
        
        switch defaults.bool(forKey: "shouldShowTitleInNotification") {
        case true:
            showContentTitleNotificationCheckbox.state = .on
        case false:
            showContentTitleNotificationCheckbox.state = .off
        }
    }
    
    @IBAction func setDownloadDestination(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        
        switch sender.identifier!.rawValue {
        case "DownloadsRadio":
            defaults.set("downloads", forKey: "DownloadDestination")
        case "DesktopRadio":
            defaults.set("desktop", forKey: "DownloadDestination")
        default:
            defaults.set("desktop", forKey: "DownloadDestination")
        }
    }
    
    @IBAction func setTitleInNotification(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        
        switch sender.state {
        case .on:
            defaults.set(true, forKey: "shouldShowTitleInNotification")
        case .off:
            defaults.set(false, forKey: "shouldShowTitleInNotification")
        default:
            break
        }
    }
    
}
