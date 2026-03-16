//
//  FCPXML.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Core FCPXML struct definition wrapping a PNXMLDocument for high-level access.
//

import Foundation

extension FinalCutPro {
    /// Final Cut Pro XML file (FCPXML/FCPXMLD)
    ///
    /// General structure when exporting from Final Cut Pro:
    ///
    /// ```xml
    /// <fcpxml version="1.9">
    ///   <resources>
    ///     <format id="r1" ... >
    ///   </resources>
    ///   <library location="file:/// ...">
    ///     <event name="MyEvent" ... >
    ///       <project name="MyProject" ... >
    ///         <sequence ... >
    ///           <spine>
    ///             <!-- clips listed here -->
    ///           </spine>
    ///         </sequence>
    ///       </project>
    ///     </event>
    ///   </library>
    /// </fcpxml>
    /// ```
    ///
    /// > Note: Starting in FCPXML 1.9, the elements that describe how to organize and use media assets are optional.
    /// > The only required element in the `fcpxml` root element is the `resources` element.
    /// >
    /// > ```xml
    /// > <fcpxml version="1.9">
    /// >   <resources> ... </resources>
    /// >   <project name="MyProject" ... >
    /// >     <sequence ... > ... </sequence>
    /// >   </project>
    /// >   <event name="MyEvent" ... > ... </event>
    /// >   <asset-clip ... />
    /// > </fcpxml>
    /// > ```
    ///
    /// > Final Cut Pro FCPXML 1.11 Reference:
    /// >
    /// > The root element in an FCPXML document is `fcpxml`, which can contain the following elements:
    /// > - A `resources` element, that contains descriptions of media assets and other resources.
    /// > - An optional `import-options` element, that controls how Final Cut Pro imports the FCPXML document.
    /// > - One of the following optional elements that describe how to organize and use media assets:
    /// >   - a `library` element that contains a list of event elements;
    /// >   - a series of `event` elements that contain story elements and project elements; or
    /// >   - a combination of story elements and `project` elements.
    /// >
    /// > Note: Starting in FCPXML 1.9, the elements that describe how to organize and use media assets are optional.
    /// > The only required element in the `fcpxml` root element is the `resources` element.
    ///
    /// [Official FCPXML Apple docs](
    /// https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/
    /// )
    ///
    /// > Note: This struct conforms to `Codable` for JSON/PLIST conversion, but cannot be `Sendable`
    /// > because it wraps `PNXMLDocument` which is not `Sendable`. Use with caution in concurrent contexts.
    public struct FCPXML: Codable {
        /// The FCPXML document.
        public var xml: any PNXMLDocument
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case xmlString
        }
        
        /// Encodes the FCPXML document to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            // Convert PNXMLDocument to XML string
            let xmlData = xml.xmlData(options: [.preserveWhitespace, .prettyPrint, .compactEmptyElements])
            guard let xmlString = String(data: xmlData, encoding: .utf8) else {
                throw FCPXMLCodableError.xmlStringConversionFailed
            }
            
            try container.encode(xmlString, forKey: .xmlString)
        }
        
        /// Creates an FCPXML document from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode XML string
            let xmlString = try container.decode(String.self, forKey: .xmlString)
            
            // Convert XML string to PNXMLDocument
            guard let xmlData = xmlString.data(using: .utf8) else {
                throw FCPXMLCodableError.xmlStringConversionFailed
            }

            do {
                let xmlDocument = try PNXMLDefaultFactory().makeDocument(data: xmlData, options: [])
                self.xml = xmlDocument
            } catch {
                throw FCPXMLCodableError.xmlStringConversionFailed
            }
        }
    }
}

// MARK: - Codable Convenience Methods

extension FinalCutPro.FCPXML {
    /// Converts this FCPXML document to a JSON string.
    /// - Returns: A JSON string representation of the document.
    /// - Throws: An error if encoding fails.
    public func jsonString() throws -> String {
        return try FCPXMLCodableConverter.jsonString(from: self)
    }
    
    /// Converts this FCPXML document to JSON data.
    /// - Returns: JSON data representation of the document.
    /// - Throws: An error if encoding fails.
    public func jsonData() throws -> Data {
        return try FCPXMLCodableConverter.jsonData(from: self)
    }
    
    /// Converts this FCPXML document to a Property List string.
    /// - Returns: A Property List XML string representation of the document.
    /// - Throws: An error if encoding fails.
    public func plistString() throws -> String {
        return try FCPXMLCodableConverter.plistString(from: self)
    }
    
    /// Converts this FCPXML document to Property List data.
    /// - Returns: Property List data representation of the document.
    /// - Throws: An error if encoding fails.
    public func plistData() throws -> Data {
        return try FCPXMLCodableConverter.plistData(from: self)
    }
    
    /// Creates an FCPXML document from a JSON string.
    /// - Parameter jsonString: The JSON string to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func from(jsonString: String) throws -> FinalCutPro.FCPXML {
        return try FCPXMLCodableConverter.fcpxml(from: jsonString)
    }
    
    /// Creates an FCPXML document from JSON data.
    /// - Parameter jsonData: The JSON data to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func from(jsonData: Data) throws -> FinalCutPro.FCPXML {
        return try FCPXMLCodableConverter.fcpxml(from: jsonData)
    }
    
    /// Creates an FCPXML document from a Property List string.
    /// - Parameter plistString: The Property List XML string to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func from(plistString: String) throws -> FinalCutPro.FCPXML {
        return try FCPXMLCodableConverter.fcpxml(fromPlistString: plistString)
    }
    
    /// Creates an FCPXML document from Property List data.
    /// - Parameter plistData: The Property List data to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func from(plistData: Data) throws -> FinalCutPro.FCPXML {
        return try FCPXMLCodableConverter.fcpxml(fromPlistData: plistData)
    }
}
