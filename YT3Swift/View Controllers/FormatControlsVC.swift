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
    @IBOutlet weak var formatsPopUpButton: NSPopUpButton!
    @IBOutlet weak var resolutionPopUpButton: NSPopUpButton!
    
    var formatList: [MediaFormat]?
    
    var extensionList: [String]?
    var resolutionList: [String]?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func selectedFormat(_ sender: NSPopUpButton) {
        let availableResolutions = (formatList?.filter({$0.fileExtension.rawValue == sender.titleOfSelectedItem}).map({$0.sizeString}) ?? []) + ["Auto"]
        
        //print(availableResolutions)
        
        if !availableResolutions.contains(resolutionPopUpButton.titleOfSelectedItem) {
            print("INCOMPATIBLE: \(sender.titleOfSelectedItem) - \(resolutionPopUpButton.titleOfSelectedItem)")
        }
    }
    
    @IBAction func selectedExtension(_ sender: NSPopUpButton) {
        let availableExtensions = (formatList?.filter({$0.sizeString == sender.titleOfSelectedItem}).map({$0.fileExtension.rawValue}) ?? []) + ["Auto"]
        
        if !availableExtensions.contains(formatsPopUpButton.titleOfSelectedItem!) {
            print("INCOMPATIBLE: \(sender.titleOfSelectedItem) - \(resolutionPopUpButton.titleOfSelectedItem)")
        }
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
    
    func display(formats: [MediaFormat]) {
        formatList = formats
        extensionList = formats.map({$0.fileExtension.rawValue})
        resolutionList = formats.sorted(by: {$0.size?.height ?? 0 < $1.size?.height ?? 0}).filter({!$0.audioOnly}).map({$0.sizeString ?? ""})
        
        formatsPopUpButton.removeAllItems()
        formatsPopUpButton.addItems(withTitles: ["Auto"] + (extensionList ?? []))
        resolutionPopUpButton.removeAllItems()
        resolutionPopUpButton.addItems(withTitles: ["Auto"] + (resolutionList ?? []))
    }
    
    enum URLState {
        case found
        case waiting
        case loading
    }
    
}
