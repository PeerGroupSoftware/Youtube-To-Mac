//
//  FormatControlsVC.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/15/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Cocoa

class FormatControlsVC: NSViewController {
    @IBOutlet weak var mainTabView: NSTabView!
    @IBOutlet weak var instructionalLabel: NSTextField!
    @IBOutlet weak var formatsLoadingIndicator: NSProgressIndicator!
    @IBOutlet weak var videoTitleLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setURLState(_ state: URLState) {
        print("Received state set to \(state)")
        switch state {
        case .found:
            formatsLoadingIndicator.stopAnimation(self)
            mainTabView.selectTabViewItem(at: 0)
        case .waiting:
            instructionalLabel.isHidden = false
            mainTabView.selectTabViewItem(at: 1)
            formatsLoadingIndicator.stopAnimation(self)
        case .loading:
            mainTabView.selectTabViewItem(at: 1)
            instructionalLabel.isHidden = true
            formatsLoadingIndicator.startAnimation(self)
        }
    }
    
    func updateVideoTitle(to newTitle: String?) {
        videoTitleLabel.stringValue = newTitle ?? "No Content Selected"
    }
    
    enum URLState {
        case found
        case waiting
        case loading
    }
    
}
