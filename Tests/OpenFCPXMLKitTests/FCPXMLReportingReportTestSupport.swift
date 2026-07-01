//
//  FCPXMLReportingReportTestSupport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared structural assertions for optional reporting integration tests.
//

import XCTest

enum FCPXMLReportingReportTestSupport {
    private static let timecodePattern = #"^\d{2}:\d{2}:\d{2}:\d{2}$"#
    
    static func assertValidTimecode(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            value.isEmpty,
            "Expected non-empty timecode",
            file: file,
            line: line
        )
        XCTAssertNotNil(
            value.range(of: timecodePattern, options: .regularExpression),
            "Expected HH:MM:SS:FF timecode, got \(value)",
            file: file,
            line: line
        )
    }
    
    static func assertSortedTimelinePositions(
        _ positions: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sorted = positions.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
        XCTAssertEqual(positions, sorted, file: file, line: line)
    }
    
    static func assertCheckmarkOrCross(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(value == "✓" || value == "✗", file: file, line: line)
    }
}
