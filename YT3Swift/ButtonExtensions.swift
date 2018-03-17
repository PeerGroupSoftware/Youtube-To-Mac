//
//  ButtonExtensions.swift
//  YoutubeToMac
//
//  Created by PhenicieWi on 1/10/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Foundation
import Cocoa



extension NSButton {
    func folderButton() {
    let buttonBorder = CALayer()
    let width = CGFloat(1.2)
    buttonBorder.borderColor = NSColor.lightGray.cgColor
    buttonBorder.frame = CGRect(x: 0, y: (self.frame.size.height - width)-1, width:  self.frame.size.width, height: width)
    
    buttonBorder.borderWidth = width
    self.wantsLayer = true
    self.layer?.addSublayer(buttonBorder)
    self.layer?.masksToBounds = true
    }
}
