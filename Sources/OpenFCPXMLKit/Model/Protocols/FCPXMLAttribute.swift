//
//  FCPXMLAttribute.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for FCPXML attributes with attribute name.
//

import Foundation
import SwiftTimecode

public protocol FCPXMLAttribute {
    /// The XML attribute name.
    static var attributeName: String { get }
}
