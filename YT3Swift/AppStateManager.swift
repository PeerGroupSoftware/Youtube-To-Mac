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
}

extension AppStateDelegate {
    func appStateDidSelectFormat(_ newFormat: MediaFormat) {
        print("selected \(newFormat.fileExtension) at \(newFormat.sizeString)")
    }
}

class AppStateManager {
    static let shared = AppStateManager()
    private var eventReceivers: [AppStateDelegate] = []
    
    var currentRequest = YTDownloadRequest()
    var selectedAudioFormat = ""
    var selectedVideoFormat = ""
    
    func registerForEvents(_ newDelegate: AppStateDelegate) {
        eventReceivers.append(newDelegate)
    }
    
    func setAudioOnly(to isAudioOnly: Bool) {
        currentRequest.audioOnly = isAudioOnly
        for receiver in eventReceivers {
            receiver.appStateDidToggleAudioOnly(to: isAudioOnly)
        }
    }
    
    func setSelectedVideoFormat(to newFormat: String) {
        selectedVideoFormat = newFormat
    }
    
    func setSelectedAudioFormat(to newFormat: String){
        selectedAudioFormat = newFormat
    }
    
    func setManualControls(enabled isEnabled: Bool) {
        
    }
}
