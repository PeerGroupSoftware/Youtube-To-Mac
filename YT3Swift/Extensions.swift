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
    
    func setAsFolderButton() {
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


extension NSTextField {
    func underlined(){
        let border = CALayer()
        let width = CGFloat(1.2)
        border.borderColor = NSColor.lightGray.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: self.frame.size.height)
        
        border.borderWidth = width
        self.wantsLayer = true
        self.layer?.addSublayer(border)
        self.layer?.masksToBounds = true
    }
}

class URLFieldCell: NSTextFieldCell {
    
    @IBInspectable var rightPadding: CGFloat = 10.0
    
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let rectInset = NSMakeRect(rect.origin.x + rightPadding, rect.origin.y, rect.size.width - rightPadding, rect.size.height)
        return super.drawingRect(forBounds: rectInset)
    }
}
