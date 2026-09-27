//
//  AppDelegate.swift
//  YT3Swift
//
//  Created by Jake Spann on 4/10/17.
//  Copyright © 2026 Peer Group. All rights reserved.
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    let repoLocation = "PeerGroupSoftware/Youtube-To-Mac"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if #available(macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        if UserDefaults.standard.object(forKey: "automaticUpdateCheck") == nil
            || UserDefaults.standard.bool(forKey: "automaticUpdateCheck") {
            checkForUpdates(sender: self)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in NSApplication.shared.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Tear down handled by process lifetime.
    }

    @available(macOS 10.14, *)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        checkForUpdates(sender: sender as NSObject)
    }

    @IBAction func submitFeedback(_ sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/\(repoLocation)/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    func checkForUpdates(sender: NSObject) {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }
        guard let releaseURL = URL(string: "https://api.github.com/repos/\(repoLocation)/releases/latest") else {
            return
        }

        var appVersionStatus = -1
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "YoutubeToMac"

        Downloader().fetchJSON(from: releaseURL) { json, error in
            DispatchQueue.main.async {
                if error == nil, let json = json, json["message"] == nil,
                   let newestVersion = json["tag_name"] as? String,
                   let htmlURL = json["html_url"] as? String,
                   let newestURL = URL(string: htmlURL) {

                    let versionComparison = currentVersion.compare(newestVersion, options: .numeric)
                    if versionComparison == .orderedSame {
                        appVersionStatus = 0
                    } else if versionComparison == .orderedAscending {
                        appVersionStatus = 1
                    } else {
                        appVersionStatus = 2
                    }

                    let alert = NSAlert()
                    alert.alertStyle = .informational

                    if appVersionStatus == 1 {
                        alert.messageText = "Update Available"
                        alert.informativeText = "\(appName) (\(newestVersion)) is available on GitHub."
                        alert.addButton(withTitle: "View on GitHub")
                        alert.addButton(withTitle: "OK")
                    } else {
                        alert.messageText = "Up to Date"
                        alert.informativeText = "You're using the latest version of \(appName)."
                    }

                    let shouldAlert = !(sender === self && appVersionStatus != 1)
                    if shouldAlert {
                        let clickedButton = alert.runModal()
                        if appVersionStatus == 1 && clickedButton == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(newestURL)
                        }
                    }
                } else {
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.messageText = "Unable to Check for Updates"
                    if let error = error as NSError?, error.code == NSURLErrorNotConnectedToInternet {
                        alert.informativeText = "There is no Internet connection."
                    } else {
                        alert.informativeText = "GitHub releases could not be reached. Try again later."
                    }

                    let shouldAlert = !(sender === self)
                    if shouldAlert {
                        alert.runModal()
                    }
                }
            }
        }
    }
}
