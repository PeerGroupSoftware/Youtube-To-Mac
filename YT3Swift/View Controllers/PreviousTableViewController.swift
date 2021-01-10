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
        newVideo.title = (previousVideos[row].title)
        newVideo.url = (previousVideos[row].url)
        newCell.video = newVideo
        newCell.videoNameLabel.stringValue = previousVideos[row].title
        
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
        NSWorkspace.shared.open(URL(string: self.video.url)!)
            //print("default browser was successfully opened")
        
    }
    
}
