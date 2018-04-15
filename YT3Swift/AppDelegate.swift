//
//  AppDelegate.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2017 Peer Group. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
      
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }


}

