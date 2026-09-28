//
//  PreviousTableViewController.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 1/9/18.
//  Copyright © 2026 Peer Group. All rights reserved.
//

import Foundation
import Cocoa

var previousVideos = [YTVideo]()

class PreviousTableViewController: NSObject, NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        previousVideos.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn,
              let newCell = tableView.makeView(withIdentifier: column.identifier, owner: self) as? PreviousVideoCellView,
              row < previousVideos.count else {
            return nil
        }

        let source = previousVideos[row]
        let newVideo = YTVideo()
        newVideo.name = source.name
        newVideo.URL = source.URL
        newVideo.diskPath = source.diskPath
        newVideo.isAudioOnly = source.isAudioOnly
        newCell.video = newVideo
        newCell.videoNameLabel.stringValue = source.name
        newCell.microphoneIcon?.isHidden = !source.isAudioOnly
        return newCell
    }
}

@objc(previousVideoCellView)
class PreviousVideoCellView: NSTableCellView {
    var video = YTVideo()
    @IBOutlet weak var videoNameLabel: NSTextField!
    @IBOutlet weak var microphoneIcon: NSImageView!

    @IBAction func openVideoLink(_ sender: NSButton) {
        guard let url = URL(string: video.URL) else { return }
        NSWorkspace.shared.open(url)
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
