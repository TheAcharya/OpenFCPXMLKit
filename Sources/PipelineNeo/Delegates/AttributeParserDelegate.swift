//
//  AttributeParserDelegate.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	XML parser delegate for extracting element attributes.
//

import Foundation

/// An XMLParser delegate for parsing attributes in PNXMLElement objects.
@available(macOS 12.0, *)
final class AttributeParserDelegate: NSObject, XMLParserDelegate {

    private let attribute: String
    private let elementName: String?
    private var parsedValues: [String] = []

    init(attribute: String, elementName: String? = nil) {
        self.attribute = attribute
        self.elementName = elementName
        super.init()
    }

    init(element: any PNXMLElement, attribute: String, inElementsWithName elementName: String?) {
        self.attribute = attribute
        self.elementName = elementName
        super.init()

        // Serialize the element to XML data via the protocol, then feed to SAX parser.
        let xmlString = element.xmlString
        guard let data = xmlString.data(using: .utf8) else { return }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let targetElementName = self.elementName, elementName != targetElementName {
            return
        }
        if let value = attributeDict[attribute] {
            parsedValues.append(value)
        }
    }
    
    /// The attribute values found during parsing.
    var values: [String] { parsedValues }
}
