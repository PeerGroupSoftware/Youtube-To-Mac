//
//  PreviousTableViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 1/9/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Foundation
import Cocoa

var previousVideos = [YTVideo]()

class PreviousTableViewController: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return previousVideos.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let newCell = tableView.makeView(withIdentifier: (tableColumn?.identifier)!, owner: self) as! previousVideoCellView
        let newVideo = YTVideo()
        newVideo.name = (previousVideos[row].name)
        newVideo.URL = (previousVideos[row].URL)
        newCell.video = newVideo
        newCell.videoNameLabel.stringValue = previousVideos[row].name
        
//        if previousVideos[row].isAudioOnly {
//        }
        return newCell
    }
    
    func insert(video: YTVideo) {
        
    }
    
}

class previousVideoCellView: NSTableCellView {
    var video = YTVideo()
    @IBOutlet weak var videoNameLabel: NSTextField!
    @IBOutlet weak var microphoneIcon: NSImageView!
    
    @IBAction func openVideoLink(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(string: self.video.URL)!)
            //print("default browser was successfully opened")
        
    }
    
}

class YTVideo {
    var name = ""
    var URL = ""
    var diskPath = ""
    var isAudioOnly = false
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
