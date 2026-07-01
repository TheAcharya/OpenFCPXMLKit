//
//  FCPXMLCodableConverter.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Utilities for converting FCPXML documents to and from JSON/PLIST formats using Codable.
//

import Foundation

/// Converter for FCPXML documents to and from JSON and Property List formats.
@available(macOS 26.0, *)
public struct FCPXMLCodableConverter {
    
    /// Converts an FCPXML document to a JSON string.
    /// - Parameter fcpxml: The FCPXML document to convert.
    /// - Returns: A JSON string representation of the document.
    /// - Throws: An error if encoding fails.
    public static func jsonString(from fcpxml: FinalCutPro.FCPXML) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(fcpxml)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw FCPXMLCodableError.jsonEncodingFailed
        }
        
        return jsonString
    }
    
    /// Converts an FCPXML document to JSON data.
    /// - Parameter fcpxml: The FCPXML document to convert.
    /// - Returns: JSON data representation of the document.
    /// - Throws: An error if encoding fails.
    public static func jsonData(from fcpxml: FinalCutPro.FCPXML) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(fcpxml)
    }
    
    /// Creates an FCPXML document from a JSON string.
    /// - Parameter jsonString: The JSON string to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func fcpxml(from jsonString: String) throws -> FinalCutPro.FCPXML {
        guard let data = jsonString.data(using: .utf8) else {
            throw FCPXMLCodableError.jsonDecodingFailed("Invalid UTF-8 encoding")
        }
        
        return try fcpxml(from: data)
    }
    
    /// Creates an FCPXML document from JSON data.
    /// - Parameter jsonData: The JSON data to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func fcpxml(from jsonData: Data) throws -> FinalCutPro.FCPXML {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(FinalCutPro.FCPXML.self, from: jsonData)
    }
    
    /// Converts an FCPXML document to a Property List string.
    /// - Parameter fcpxml: The FCPXML document to convert.
    /// - Returns: A Property List XML string representation of the document.
    /// - Throws: An error if encoding fails.
    public static func plistString(from fcpxml: FinalCutPro.FCPXML) throws -> String {
        let data = try plistData(from: fcpxml)
        
        guard let plistString = String(data: data, encoding: .utf8) else {
            throw FCPXMLCodableError.plistEncodingFailed
        }
        
        return plistString
    }
    
    /// Converts an FCPXML document to Property List data.
    /// - Parameter fcpxml: The FCPXML document to convert.
    /// - Returns: Property List data representation of the document.
    /// - Throws: An error if encoding fails.
    public static func plistData(from fcpxml: FinalCutPro.FCPXML) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        return try encoder.encode(fcpxml)
    }
    
    /// Creates an FCPXML document from a Property List string.
    /// - Parameter plistString: The Property List XML string to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func fcpxml(fromPlistString plistString: String) throws -> FinalCutPro.FCPXML {
        guard let data = plistString.data(using: .utf8) else {
            throw FCPXMLCodableError.plistDecodingFailed("Invalid UTF-8 encoding")
        }
        
        return try fcpxml(fromPlistData: data)
    }
    
    /// Creates an FCPXML document from Property List data.
    /// - Parameter plistData: The Property List data to decode.
    /// - Returns: An FCPXML document.
    /// - Throws: An error if decoding fails.
    public static func fcpxml(fromPlistData plistData: Data) throws -> FinalCutPro.FCPXML {
        let decoder = PropertyListDecoder()
        
        return try decoder.decode(FinalCutPro.FCPXML.self, from: plistData)
    }
}

/// Errors that can occur during Codable conversion operations.
@available(macOS 26.0, *)
public enum FCPXMLCodableError: Error, LocalizedError {
    case jsonEncodingFailed
    case jsonDecodingFailed(String)
    case plistEncodingFailed
    case plistDecodingFailed(String)
    case xmlStringConversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .jsonEncodingFailed:
            return "Failed to encode FCPXML document to JSON"
        case .jsonDecodingFailed(let message):
            return "Failed to decode JSON to FCPXML document: \(message)"
        case .plistEncodingFailed:
            return "Failed to encode FCPXML document to Property List"
        case .plistDecodingFailed(let message):
            return "Failed to decode Property List to FCPXML document: \(message)"
        case .xmlStringConversionFailed:
            return "Failed to convert between XML string and FCPXML document"
        }
    }
}
