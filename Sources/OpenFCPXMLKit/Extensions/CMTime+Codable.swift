//
//  CMTime+Codable.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	CMTime Codable extension for FCPXML time string encoding/decoding.
//

import Foundation
import CoreMedia

// Note: This extension adds Codable conformance to CMTime for FCPXML time string encoding/decoding.
// @retroactive is used to suppress the compiler warning about retroactive conformance, acknowledging
// that we understand the risks and accept responsibility for potential conflicts if CoreMedia
// adds Codable conformance in the future.
@available(macOS 26.0, *)
extension CMTime: @retroactive Codable {
    
    /// Creates a CMTime from a decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = CMTime.fcpxmlTime(from: string)
    }
    
    /// Encodes the CMTime to an encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fcpxmlString)
    }
}
