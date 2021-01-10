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
    @IBOutlet weak var onButton: NSButton!
    @IBOutlet weak var resolutionPopUpButton: NSPopUpButton!
    
    var formatList: [MediaFormat]? = []
    
    var extensionList: [String]?
    var resolutionList: [String]?
    var mainVC: ViewController?
    
    var isOn = false
    private var selectedFormatVideo = ""
    private var selectedResolutionVideo = ""
    private var selectedFormatAudio = ""
    private var isAudioOnly: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setManualControlsEnabled(_ isEnabled: Bool) {
        isOn = isEnabled
        if mainVC != nil {
            mainVC?.manualControlsStateDidChange(to: isEnabled)
        }
        
        formatsPopUpButton.isEnabled = isEnabled
        resolutionPopUpButton.isEnabled = (isEnabled && !isAudioOnly)
    }
    
    @IBAction func setOnState(_ sender: NSButton) {
        setManualControlsEnabled(sender.state == .on)
    }
    
    @IBAction func selectedFormat(_ sender: NSPopUpButton) {
        setManualControlsEnabled(true)
        onButton.state = .on
        
        if isAudioOnly {
            selectedFormatAudio = sender.titleOfSelectedItem ?? ""
        } else {
            selectedFormatVideo = sender.titleOfSelectedItem ?? ""
        }
        
        let availableResolutions = (formatList?.filter({$0.fileExtension.rawValue == sender.titleOfSelectedItem}).map({$0.sizeString}) ?? []) + ["Auto"]
        
        //print(availableResolutions)
        
        if !availableResolutions.contains(resolutionPopUpButton.titleOfSelectedItem) {
            print("INCOMPATIBLE: \(sender.titleOfSelectedItem) - \(resolutionPopUpButton.titleOfSelectedItem)")
        }
    }
    
    @IBAction func selectedResolution(_ sender: NSPopUpButton) {
        setManualControlsEnabled(true)
        onButton.state = .on
        
        selectedResolutionVideo = sender.titleOfSelectedItem ?? ""
        
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
    
    func setIsAudioOnly(to isAudioOnly: Bool) {
        display(formats: formatList!, audioOnly: isAudioOnly)
    }
    
    func didChangeManualControlsEnabled(to newState: Bool) {
        isOn = newState
        onButton.state = newState ? .on : .off
        
        formatsPopUpButton.isEnabled = newState
        resolutionPopUpButton.isEnabled = (newState && !isAudioOnly)
    }
    
    func loadPreviousSelection() {
        if isAudioOnly {
            if !selectedFormatAudio.isEmpty {
                formatsPopUpButton.selectItem(withTitle: selectedFormatAudio)
            }
        } else {
            if !selectedFormatVideo.isEmpty {
                //print("SELECTING")
                formatsPopUpButton.selectItem(withTitle: selectedFormatVideo)
            }
            
            if !selectedResolutionVideo.isEmpty {
                resolutionPopUpButton.selectItem(withTitle: selectedResolutionVideo)
            }
            
        }
    }
    
    func display(formats: [MediaFormat], audioOnly: Bool = false) {
        formatList = formats
        isAudioOnly = audioOnly
        
        var tempFormats = formats
        tempFormats = tempFormats.filter({$0.audioOnly == audioOnly})
        
        extensionList = tempFormats.map({$0.fileExtension.rawValue})
        resolutionList = tempFormats.sorted(by: {$0.size?.height ?? 0 < $1.size?.height ?? 0}).filter({!$0.audioOnly}).map({$0.sizeString ?? ""})
        
        formatsPopUpButton.removeAllItems()
        formatsPopUpButton.addItems(withTitles: ["Auto"] + (extensionList ?? []))
        resolutionPopUpButton.removeAllItems()
        resolutionPopUpButton.addItems(withTitles: ["Auto"] + (resolutionList ?? []))
        
        
        if audioOnly || isOn == false {
            resolutionPopUpButton?.isEnabled = false
        } else {
            resolutionPopUpButton?.isEnabled = true
        }
        
        loadPreviousSelection()
    }
    
    enum URLState {
        case found
        case waiting
        case loading
    }
    
}
