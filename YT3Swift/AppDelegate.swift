//
//  AppDelegate.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2021 Peer Group. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    let repoLocation = "PeerGroupSoftware/Youtube-To-Mac"
      
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        if UserDefaults.standard.bool(forKey: "automaticUpdateCheck") != false || UserDefaults.standard.object(forKey: "automaticUpdateCheck") == nil {
            checkForUpdates(sender: self)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window: AnyObject in NSApplication.shared.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        checkForUpdates(sender: sender)
    }
    
    @IBAction func submitFeedback(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://github.com/\(repoLocation)/issues")!)
    }
    
    func checkForUpdates(sender: NSObject) {
        print("Checking for updates...")
        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let releaseURL = URL(string: "https://api.github.com/repos/\(repoLocation)/releases/latest")!
        
        var appVersionStatus = -1
        
        //Piggyback on the Downloder's implementation of fetchJSON()
        Downloader().fetchJSON(from: releaseURL, completion: {(json, error) in
            DispatchQueue.main.async {
                
                if error == nil && json != nil && json!["message"] == nil {
                    let newestVersion = (json!["tag_name"] as! String)
                    let newestURL = URL(string: (json!["html_url"] as! String))!
                    
                    let versionComparison = currentVersion.compare(newestVersion, options: .numeric)
                    
                    if versionComparison == .orderedSame { // Local version is current
                        appVersionStatus = 0
                    } else if versionComparison == .orderedAscending { // Update available
                        appVersionStatus = 1
                    } else if versionComparison == .orderedDescending { // Local app version is newer
                        appVersionStatus = 2
                    }
                    
                    let alert = NSAlert()
                    alert.alertStyle = .informational
                    
                    if appVersionStatus == -1 || appVersionStatus == 0 || appVersionStatus == 2 {
                        alert.messageText = "Up to Date"
                        alert.informativeText = "You're using the latest version of \(Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "YoutubeToMac")."
                    } else if appVersionStatus == 1 {
                        alert.messageText = "Update Available"
                        alert.informativeText = "\(Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "YoutubeToMac") (\(newestVersion)) is available on GitHub."
                        alert.addButton(withTitle: "View on GitHub")
                        alert.addButton(withTitle: "Ok")
                    }
                    
                    var shouldAlert = true
                    if sender == self && appVersionStatus != 1 {shouldAlert = false}
                    
                    if shouldAlert {
                        let clickedButton = alert.runModal()
                        
                        if clickedButton == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(newestURL)
                        }
                    }
                    
                    
                } else {
                    print("Could not check for updates: \(String(describing: error))")
                    
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.messageText = "Unable to Check for Updates"
                    if error != nil && (error! as NSError).code == -1009 {
                        alert.informativeText = "There is no Internet connection."
                    }
                    
                    var shouldAlert = true
                    if sender == self && appVersionStatus != 1 {shouldAlert = false}
                    if shouldAlert {alert.runModal()}
                }
            }
        })
    }
    

}

