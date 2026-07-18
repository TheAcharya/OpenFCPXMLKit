//
//  FCPXMLRootVersionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Logic and Parsing: FinalCutPro.FCPXML.Version (init, rawValue, Comparable).
//

import Testing
@testable import OpenFCPXMLKit

@Suite("FCPXML root version")
struct FCPXMLRootVersionTests {
    private typealias Version = FinalCutPro.FCPXML.Version

    @Test("Version 1.12 has expected components")
    func version_1_12() {
        let v = Version(1, 12)
        #expect(v.major == 1)
        #expect(v.minor == 12)
        #expect(v.patch == 0)
        #expect(v.rawValue == "1.12")
    }

    @Test("Version 1.12.1 has expected components")
    func version_1_12_1() {
        let v = Version(1, 12, 1)
        #expect(v.major == 1)
        #expect(v.minor == 12)
        #expect(v.patch == 1)
        #expect(v.rawValue == "1.12.1")
    }

    @Test("Version equatable")
    func version_Equatable() {
        #expect(Version(1, 12) == Version(1, 12))
        #expect(Version(1, 12) != Version(1, 13))
        #expect(Version(1, 12) != Version(2, 12))
    }

    @Test("Version comparable")
    func version_Comparable() {
        #expect(!(Version(1, 12) < Version(1, 12)))
        #expect(!(Version(1, 12) > Version(1, 12)))
        #expect(Version(1, 11) < Version(1, 12))
        #expect(Version(1, 12) > Version(1, 11))
        #expect(Version(1, 10) < Version(2, 3))
        #expect(Version(2, 3) > Version(1, 10))
    }

    @Test("Raw value major-only edge case")
    func version_RawValue_EdgeCase_MajorVersionOnly() {
        let v = Version(rawValue: "2")
        #expect(v != nil)
        #expect(v?.major == 2)
        #expect(v?.minor == 0)
        #expect(v?.patch == 0)
        #expect(v?.rawValue == "2.0")
    }

    @Test("Invalid raw values return nil")
    func version_RawValue_Invalid() {
        #expect(Version(rawValue: "") == nil)
        #expect(Version(rawValue: "1.") == nil)
        #expect(Version(rawValue: "1.A") == nil)
        #expect(Version(rawValue: "A") == nil)
        #expect(Version(rawValue: "A.1") == nil)
        #expect(Version(rawValue: "1.12.") == nil)
        #expect(Version(rawValue: "1.12.A") == nil)
    }

    @Test("Init from raw value 1.12")
    func version_Init_RawValue() {
        let v = Version(rawValue: "1.12")
        #expect(v != nil)
        #expect(v?.major == 1)
        #expect(v?.minor == 12)
    }

    @Test("Raw value roundtrip")
    func version_RawValue_Roundtrip() {
        let v = Version(rawValue: "1.12")
        #expect(v != nil)
        #expect(v?.rawValue == "1.12")
    }

    @Test("Static members and latest")
    func version_StaticMembers() {
        #expect(Version.ver1_11.rawValue == "1.11")
        #expect(Version.ver1_14.rawValue == "1.14")
        #expect(Version.latest == .ver1_14)
        #expect(Version.allCases.contains(.ver1_10))
        #expect(Version.allCases.contains(.ver1_14))
    }
}

