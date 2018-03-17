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
        newCell.videoNameLabel.stringValue = previousVideos[row].name
        return newCell
    }
    
}

class previousVideoCellView: NSTableCellView {
    @IBOutlet weak var videoNameLabel: NSTextField!
    
}

class YTVideo {
    var name = ""
    var URL = ""
    var diskPath = ""
}
