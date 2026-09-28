//
//  Extensions.swift
//  YoutubeToMac
//
//  Created by PhenicieWi on 1/10/18.
//  Copyright © 2026 Peer Group. All rights reserved.
//

import Foundation
import Cocoa

extension NSButton {
    func setAsFolderButton() {
        let buttonBorder = CALayer()
        let width = CGFloat(1.2)
        buttonBorder.borderColor = NSColor.separatorColor.cgColor
        buttonBorder.frame = CGRect(
            x: 0,
            y: (frame.size.height - width) - 1,
            width: frame.size.width,
            height: width
        )
        buttonBorder.borderWidth = width
        wantsLayer = true
        layer?.addSublayer(buttonBorder)
        layer?.masksToBounds = true
    }
}

extension NSTextField {
    func underlined() {
        let border = CALayer()
        let width = CGFloat(1.2)
        border.borderColor = NSColor.separatorColor.cgColor
        border.frame = CGRect(
            x: 0,
            y: frame.size.height - width,
            width: frame.size.width,
            height: frame.size.height
        )
        border.borderWidth = width
        wantsLayer = true
        layer?.addSublayer(border)
        layer?.masksToBounds = true
    }
}

class URLFieldCell: NSTextFieldCell {
    @IBInspectable var rightPadding: CGFloat = 10.0

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let rectInset = NSRect(
            x: rect.origin.x + rightPadding,
            y: rect.origin.y,
            width: rect.size.width - rightPadding,
            height: rect.size.height
        )
        return super.drawingRect(forBounds: rectInset)
    }
}
