//
//  FCPXMLReportingReportTestSupport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared structural assertions for optional reporting integration tests.
//

import XCTest
@testable import OpenFCPXMLKit

enum FCPXMLReportingReportTestSupport {
    /// Non-drop: `HH:MM:SS:FF`; drop-frame: `HH:MM:SS;FF` (SMPTE delimiter before frames).
    private static let smpteTimecodePattern = #"^\d{2}:\d{2}:\d{2}[:;]\d{2}$"#
    private static let smpteNoFramesPattern = #"^\d{2}:\d{2}:\d{2}$"#
    private static let feetAndFramesPattern = #"^\d+\+\d{2}$"#
    
    static func assertValidTimecode(
        _ value: String,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat = .smpteFrames,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            value.isEmpty,
            "Expected non-empty timecode",
            file: file,
            line: line
        )
        
        switch format {
        case .smpteFrames:
            XCTAssertNotNil(
                value.range(of: smpteTimecodePattern, options: .regularExpression),
                "Expected HH:MM:SS:FF or HH:MM:SS;FF timecode, got \(value)",
                file: file,
                line: line
            )
        case .frames:
            XCTAssertNotNil(
                Int(value),
                "Expected integer frame count, got \(value)",
                file: file,
                line: line
            )
        case .feetAndFrames:
            XCTAssertNotNil(
                value.range(of: feetAndFramesPattern, options: .regularExpression),
                "Expected feet+frames timecode, got \(value)",
                file: file,
                line: line
            )
        case .smpteNoFrames:
            XCTAssertNotNil(
                value.range(of: smpteNoFramesPattern, options: .regularExpression),
                "Expected HH:MM:SS timecode, got \(value)",
                file: file,
                line: line
            )
        }
    }
    
    static func assertAllValidTimecodes(
        _ values: [String],
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for value in values where !value.isEmpty {
            assertValidTimecode(value, format: format, file: file, line: line)
        }
    }
    
    static func assertDropFrameTimecode(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertValidTimecode(value, format: .smpteFrames, file: file, line: line)
        XCTAssertTrue(
            value.contains(";"),
            "Expected drop-frame semicolon before frames, got \(value)",
            file: file,
            line: line
        )
    }
    
    static func assertNonDropFrameTimecode(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertValidTimecode(value, format: .smpteFrames, file: file, line: line)
        XCTAssertFalse(
            value.contains(";"),
            "Expected non-drop-frame colons only, got \(value)",
            file: file,
            line: line
        )
    }
    
    /// Asserts every non-empty timecode cell in a built report matches ``format``.
    static func assertReportTimecodeValues(
        _ report: FinalCutPro.FCPXML.Report,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if let markers = report.markers {
            for row in markers.rows {
                assertValidTimecode(row.position, format: format, file: file, line: line)
                if !row.sourcePosition.isEmpty {
                    assertValidTimecode(row.sourcePosition, format: format, file: file, line: line)
                }
            }
            assertSortedTimelinePositions(
                markers.rows.map(\.position),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let keywords = report.keywords {
            for row in keywords.rows {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
                assertValidTimecode(row.duration, format: format, file: file, line: line)
            }
            assertSortedTimelinePositions(
                keywords.rows.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let titles = report.titlesAndGenerators {
            for row in titles.rows {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
                assertValidTimecode(row.duration, format: format, file: file, line: line)
            }
            assertSortedTimelinePositions(
                titles.rows.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let transitions = report.transitions {
            for row in transitions.rows {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
                assertValidTimecode(row.duration, format: format, file: file, line: line)
            }
            assertSortedTimelinePositions(
                transitions.rows.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let effects = report.effects {
            for row in effects.rows {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
            }
            assertSortedTimelinePositions(
                effects.rows.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let speedChangeEffects = report.speedChangeEffects {
            for row in speedChangeEffects.rows {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
            }
            assertSortedTimelinePositions(
                speedChangeEffects.rows.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
        
        if let summary = report.summary {
            if let duration = summary.projectSummary?.duration, !duration.isEmpty {
                assertValidTimecode(duration, format: format, file: file, line: line)
            }
            for row in summary.roleDurations {
                assertValidTimecode(row.estimatedTotal, format: format, file: file, line: line)
            }
        }
        
        if let roleInventory = report.roleInventory {
            for row in roleInventory.selectedRoles {
                assertValidTimecode(row.timelineIn, format: format, file: file, line: line)
                assertValidTimecode(row.timelineOut, format: format, file: file, line: line)
                assertValidTimecode(row.clipDuration, format: format, file: file, line: line)
                if !row.sourceIn.isEmpty {
                    assertValidTimecode(row.sourceIn, format: format, file: file, line: line)
                }
                if !row.sourceOut.isEmpty {
                    assertValidTimecode(row.sourceOut, format: format, file: file, line: line)
                }
                if !row.sourceDuration.isEmpty {
                    assertValidTimecode(row.sourceDuration, format: format, file: file, line: line)
                }
            }
            assertSortedTimelinePositions(
                roleInventory.selectedRoles.map(\.timelineIn),
                format: format,
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts workbook column headers for each populated section match ``report/timecodeFormat``.
    static func assertReportColumnHeadersMatchTimecodeFormat(
        _ report: FinalCutPro.FCPXML.Report,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let format = report.timecodeFormat
        
        if report.markers != nil {
            let headers = FinalCutPro.FCPXML.MarkerReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[3], baseName: "Position", format: format, file: file, line: line)
            assertTimecodeHeader(
                headers[8],
                baseName: "Source Position",
                format: format,
                file: file,
                line: line
            )
        }
        
        if report.keywords != nil {
            let headers = FinalCutPro.FCPXML.KeywordReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[2], baseName: "Timeline In", format: format, file: file, line: line)
            assertTimecodeHeader(headers[3], baseName: "Timeline Out", format: format, file: file, line: line)
            assertTimecodeHeader(headers[4], baseName: "Duration", format: format, file: file, line: line)
        }
        
        if report.titlesAndGenerators != nil {
            let headers = FinalCutPro.FCPXML.TitleReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[4], baseName: "Timeline In", format: format, file: file, line: line)
            assertTimecodeHeader(headers[5], baseName: "Timeline Out", format: format, file: file, line: line)
            assertTimecodeHeader(headers[6], baseName: "Duration", format: format, file: file, line: line)
        }
        
        if report.transitions != nil {
            let headers = FinalCutPro.FCPXML.TransitionReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[3], baseName: "Timeline In", format: format, file: file, line: line)
            assertTimecodeHeader(headers[4], baseName: "Timeline Out", format: format, file: file, line: line)
            assertTimecodeHeader(headers[5], baseName: "Duration", format: format, file: file, line: line)
        }
        
        if report.effects != nil {
            let headers = FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[6], baseName: "Timeline In", format: format, file: file, line: line)
            assertTimecodeHeader(headers[7], baseName: "Timeline Out", format: format, file: file, line: line)
        }
        
        if report.speedChangeEffects != nil {
            let headers = FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[6], baseName: "Timeline In", format: format, file: file, line: line)
            assertTimecodeHeader(headers[7], baseName: "Timeline Out", format: format, file: file, line: line)
        }
        
        if let summary = report.summary, !summary.roleDurations.isEmpty {
            let headers = FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders(
                timecodeFormat: format
            )
            assertTimecodeHeader(
                headers[1],
                baseName: "Estimated Total",
                format: format,
                file: file,
                line: line
            )
        }
        
        if report.roleInventory != nil {
            let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
                metadataColumnKeys: report.roleInventory?.metadataColumnKeys ?? [],
                timecodeFormat: format
            )
            XCTAssertTrue(
                headers.contains(format.formattedColumnHeader("Timeline In")),
                file: file,
                line: line
            )
            XCTAssertTrue(
                headers.contains(format.formattedColumnHeader("Clip Duration")),
                file: file,
                line: line
            )
        }
    }
    
    private static func assertTimecodeHeader(
        _ header: String,
        baseName: String,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            header,
            format.formattedColumnHeader(baseName),
            file: file,
            line: line
        )
    }
    
    static func assertSortedTimelinePositions(
        _ positions: [String],
        format: FinalCutPro.FCPXML.ReportTimecodeFormat = .smpteFrames,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sorted = positions.sorted {
            FinalCutPro.FCPXML.ReportFormatting.compareTimelinePositions(
                $0,
                $1,
                format: format
            ) == .orderedAscending
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
