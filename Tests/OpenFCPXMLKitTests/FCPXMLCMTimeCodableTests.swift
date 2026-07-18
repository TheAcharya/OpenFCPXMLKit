//
//  FCPXMLCMTimeCodableTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for CMTime Codable encoding and decoding as FCPXML time strings.
//

import Foundation
import Testing
import CoreMedia
@testable import OpenFCPXMLKit

@Suite("CMTime Codable")
struct FCPXMLCMTimeCodableTests {

    @Test("Encode and decode")
    func cmTimeCodableEncodeDecode() throws {
        let time = CMTime(seconds: 5.0, preferredTimescale: 600)

        let encoder = JSONEncoder()
        let data = try encoder.encode(time)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)

        #expect(decoded.value == time.value)
        #expect(decoded.timescale == time.timescale)
    }

    @Test("Rational format")
    func cmTimeCodableRationalFormat() throws {
        let time = CMTime(value: 7200, timescale: 2400)

        let encoder = JSONEncoder()
        let data = try encoder.encode(time)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)

        #expect(decoded.value == time.value)
        #expect(decoded.timescale == time.timescale)
    }

    @Test("Zero")
    func cmTimeCodableZero() throws {
        let time = CMTime.zero

        let encoder = JSONEncoder()
        let data = try encoder.encode(time)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)

        #expect(decoded.value == 0)
    }

    @Test("Round trip")
    func cmTimeCodableRoundTrip() throws {
        let original = CMTime(seconds: 10.5, preferredTimescale: 600)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CMTime.self, from: data)

        let secondsMatch = abs(decoded.seconds - original.seconds) < 0.001
        #expect(secondsMatch)
    }
}

