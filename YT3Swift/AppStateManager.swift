//
//  AppStateManager.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 1/10/21.
//  Copyright © 2021 Peer Group Software. All rights reserved.
//

import Foundation

protocol AppStateDelegate {
    func appStateDidToggleAudioOnly(to newState: Bool)
    func appStateDidSelectFormat(_ newFormat: MediaFormat)
    func appStateDidChange(to newState: AppState)
    func appStateDidEnableManualControls(_ newState: Bool)
}

extension AppStateDelegate {
    func appStateDidSelectFormat(_ newFormat: MediaFormat) {
        print("selected \(newFormat.fileExtension) at \(newFormat.sizeString)")
    }
    
    func appStateDidEnableManualControls(_ newState: Bool) {
        print("Manual controls enabled: \(newState)")
    }
}

class AppStateManager {
    static let shared = AppStateManager()
    private var eventReceivers: [AppStateDelegate] = []
    private(set) var state: AppState = .waitingForURL
    
    var currentRequest = YTDownloadRequest()
    var manualControlsEnabled = false
    var selectedAudioFormat: MediaFormat?
    var selectedVideoFormat: MediaFormat?
    
    func registerForEvents(_ newDelegate: AppStateDelegate) {
        eventReceivers.append(newDelegate)
    }
    
    func setAudioOnly(to isAudioOnly: Bool) {
        currentRequest.audioOnly = isAudioOnly
        for receiver in eventReceivers {
            receiver.appStateDidToggleAudioOnly(to: isAudioOnly)
        }
    }
    
    func setAppState(to newState: AppState) {
        state = newState
        for receiver in eventReceivers {
            receiver.appStateDidChange(to: newState)
        }
    }
    
    func setSelectedVideoFormat(to newFormat: String, resolution: String?, FPS: Int?) {
        var tempResolution: String?
        if resolution != "Auto" {
            tempResolution = resolution
        }
        selectedVideoFormat = MediaFormat(fileExtension: MediaExtension(rawValue: newFormat)!, sizeString: tempResolution, fps: FPS)
    }
    
    func setSelectedAudioFormat(to newFormat: String){
        selectedAudioFormat = MediaFormat(fileExtension: MediaExtension(rawValue: newFormat)!)
    }
    
    func setManualControls(enabled isEnabled: Bool) {
        manualControlsEnabled = isEnabled
        for receiver in eventReceivers {
            receiver.appStateDidEnableManualControls(isEnabled)
        }
    }
}

enum AppState {
    case waitingForURL
    case ready
    case downloading
}
