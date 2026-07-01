//
//  FCPXMLCMTimeCodableTests.swift
//  OpenFCPXMLKitTests
//  © 2026 • Licensed under MIT License
//

import XCTest
import CoreMedia
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLCMTimeCodableTests: XCTestCase {
    
    func testCMTimeCodableEncodeDecode() throws {
        let time = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(time)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)
        
        XCTAssertEqual(decoded.value, time.value)
        XCTAssertEqual(decoded.timescale, time.timescale)
    }
    
    func testCMTimeCodableRationalFormat() throws {
        let time = CMTime(value: 7200, timescale: 2400)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(time)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)
        
        XCTAssertEqual(decoded.value, time.value)
        XCTAssertEqual(decoded.timescale, time.timescale)
    }
    
    func testCMTimeCodableZero() throws {
        let time = CMTime.zero
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(time)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)
        
        XCTAssertEqual(decoded.value, 0)
    }
    
    func testCMTimeCodableRoundTrip() throws {
        let original = CMTime(seconds: 10.5, preferredTimescale: 600)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)
        
        XCTAssertEqual(decoded.seconds, original.seconds, accuracy: 0.001)
    }
}
