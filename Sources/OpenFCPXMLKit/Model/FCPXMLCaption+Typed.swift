//
// FCPXMLCaption+Typed.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Typed helpers for Caption (inventory clip name).
//

import Foundation

extension FinalCutPro.FCPXML.Caption {
    /// Caption text for workbook inventory rows (`text-style` body, then `name`).
    var workbookInventoryClipName: String {
        let body = element.fcpTexts.flatMap { text in
            text.textStyles.compactMap(\.stringValue)
        }
        .joined()
        .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !body.isEmpty {
            return body
        }
        
        return element.fcpName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
