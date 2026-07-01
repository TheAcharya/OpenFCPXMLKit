//
//  FCPXMLParserDelegate.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	XML parser delegate for FCPXML document structure parsing.
//

import Foundation

/// An XMLParser delegate for parsing roles and IDs from FCPXML documents.
@available(macOS 26.0, *)
final class FCPXMLParserDelegate: NSObject, XMLParserDelegate {
    
    /// Unique roles found by the parser (insertion-ordered).
    private var foundRoles: [String] = []
    private var roleSet: Set<String> = []
    
    /// Unique resource IDs found by the parser (insertion-ordered).
    private var foundResourceIDs: [String] = []
    private var resourceIDSet: Set<String> = []
    
    /// Unique text style IDs found by the parser (insertion-ordered).
    private var foundTextStyleIDs: [String] = []
    private var textStyleIDSet: Set<String> = []
    
    override init() {
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let role = attributeDict["role"], roleSet.insert(role).inserted {
            foundRoles.append(role)
        }
        if let id = attributeDict["id"], resourceIDSet.insert(id).inserted {
            foundResourceIDs.append(id)
        }
        if let textStyleID = attributeDict["textStyleID"], textStyleIDSet.insert(textStyleID).inserted {
            foundTextStyleIDs.append(textStyleID)
        }
    }
    
    /// The unique roles found during parsing.
    var roles: [String] { foundRoles }
    
    /// The unique resource IDs found during parsing.
    var resourceIDs: [String] { foundResourceIDs }
    
    /// The unique text style IDs found during parsing.
    var textStyleIDs: [String] { foundTextStyleIDs }
}
