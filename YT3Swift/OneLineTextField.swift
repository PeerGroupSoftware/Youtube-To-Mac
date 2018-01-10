//
//  OneLineTextField.swift
//  YoutubeToMac
//
//  Created by PhenicieWi on 1/10/18.
//  Copyright © 2018 Jake Spann. All rights reserved.
//

import Foundation
import Cocoa

extension NSTextField {
    func underlined(){
        /*let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = NSColor.lightGray.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = width
        self.layer?.addSublayer(border)
        self.layer?.masksToBounds = true*/
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
