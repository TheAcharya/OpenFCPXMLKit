//
//  FCPXMLRootVersionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Logic and Parsing: FinalCutPro.FCPXML.Version (init, rawValue, Comparable).
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRootVersionTests: XCTestCase {

    typealias Version = FinalCutPro.FCPXML.Version

    func testVersion_1_12() {
        let v = Version(1, 12)
        XCTAssertEqual(v.major, 1)
        XCTAssertEqual(v.minor, 12)
        XCTAssertEqual(v.patch, 0)
        XCTAssertEqual(v.rawValue, "1.12")
    }

    func testVersion_1_12_1() {
        let v = Version(1, 12, 1)
        XCTAssertEqual(v.major, 1)
        XCTAssertEqual(v.minor, 12)
        XCTAssertEqual(v.patch, 1)
        XCTAssertEqual(v.rawValue, "1.12.1")
    }

    func testVersion_Equatable() {
        XCTAssertEqual(Version(1, 12), Version(1, 12))
        XCTAssertNotEqual(Version(1, 12), Version(1, 13))
        XCTAssertNotEqual(Version(1, 12), Version(2, 12))
    }

    func testVersion_Comparable() {
        XCTAssertFalse(Version(1, 12) < Version(1, 12))
        XCTAssertFalse(Version(1, 12) > Version(1, 12))
        XCTAssertTrue(Version(1, 11) < Version(1, 12))
        XCTAssertTrue(Version(1, 12) > Version(1, 11))
        XCTAssertTrue(Version(1, 10) < Version(2, 3))
        XCTAssertTrue(Version(2, 3) > Version(1, 10))
    }

    func testVersion_RawValue_EdgeCase_MajorVersionOnly() {
        let v = Version(rawValue: "2")
        XCTAssertNotNil(v)
        XCTAssertEqual(v?.major, 2)
        XCTAssertEqual(v?.minor, 0)
        XCTAssertEqual(v?.patch, 0)
        XCTAssertEqual(v?.rawValue, "2.0")
    }

    func testVersion_RawValue_Invalid() {
        XCTAssertNil(Version(rawValue: ""))
        XCTAssertNil(Version(rawValue: "1."))
        XCTAssertNil(Version(rawValue: "1.A"))
        XCTAssertNil(Version(rawValue: "A"))
        XCTAssertNil(Version(rawValue: "A.1"))
        XCTAssertNil(Version(rawValue: "1.12."))
        XCTAssertNil(Version(rawValue: "1.12.A"))
    }

    func testVersion_Init_RawValue() {
        let v = Version(rawValue: "1.12")
        XCTAssertNotNil(v)
        XCTAssertEqual(v?.major, 1)
        XCTAssertEqual(v?.minor, 12)
    }

    func testVersion_RawValue_Roundtrip() {
        let v = Version(rawValue: "1.12")
        XCTAssertNotNil(v)
        XCTAssertEqual(v?.rawValue, "1.12")
    }

    func testVersion_StaticMembers() {
        XCTAssertEqual(Version.ver1_11.rawValue, "1.11")
        XCTAssertEqual(Version.ver1_14.rawValue, "1.14")
        XCTAssertEqual(Version.latest, .ver1_14)
        XCTAssertTrue(Version.allCases.contains(.ver1_10))
        XCTAssertTrue(Version.allCases.contains(.ver1_14))
    }
}
