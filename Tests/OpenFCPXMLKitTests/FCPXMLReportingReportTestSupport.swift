//
//  FCPXMLReportingReportTestSupport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared structural assertions for reporting tests (Swift Testing).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

enum FCPXMLReportingReportTestSupport {
    /// Non-drop: `HH:MM:SS:FF`; drop-frame: `HH:MM:SS;FF` (SMPTE delimiter before frames).
    private static let smpteTimecodePattern = #"^\d{2}:\d{2}:\d{2}[:;]\d{2}$"#
    private static let smpteNoFramesPattern = #"^\d{2}:\d{2}:\d{2}$"#
    private static let feetAndFramesPattern = #"^\d+\+\d{2}$"#

    static func assertValidTimecode(
        _ value: String,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat = .smpteFrames,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(!value.isEmpty, "Expected non-empty timecode", sourceLocation: sourceLocation)

        switch format {
        case .smpteFrames:
            #expect(
                value.range(of: smpteTimecodePattern, options: .regularExpression) != nil,
                "Expected HH:MM:SS:FF or HH:MM:SS;FF timecode, got \(value)",
                sourceLocation: sourceLocation
            )
        case .frames:
            #expect(
                Int(value) != nil,
                "Expected integer frame count, got \(value)",
                sourceLocation: sourceLocation
            )
        case .feetAndFrames:
            #expect(
                value.range(of: feetAndFramesPattern, options: .regularExpression) != nil,
                "Expected feet+frames timecode, got \(value)",
                sourceLocation: sourceLocation
            )
        case .smpteNoFrames:
            #expect(
                value.range(of: smpteNoFramesPattern, options: .regularExpression) != nil,
                "Expected HH:MM:SS timecode, got \(value)",
                sourceLocation: sourceLocation
            )
        }
    }

    static func assertAllValidTimecodes(
        _ values: [String],
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for value in values where !value.isEmpty {
            assertValidTimecode(value, format: format, sourceLocation: sourceLocation)
        }
    }

    static func assertDropFrameTimecode(
        _ value: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertValidTimecode(value, format: .smpteFrames, sourceLocation: sourceLocation)
        #expect(
            value.contains(";"),
            "Expected drop-frame semicolon before frames, got \(value)",
            sourceLocation: sourceLocation
        )
    }

    static func assertNonDropFrameTimecode(
        _ value: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertValidTimecode(value, format: .smpteFrames, sourceLocation: sourceLocation)
        #expect(
            !value.contains(";"),
            "Expected non-drop-frame colons only, got \(value)",
            sourceLocation: sourceLocation
        )
    }

    /// Asserts every non-empty timecode cell in a built report matches ``format``.
    static func assertReportTimecodeValues(
        _ report: FinalCutPro.FCPXML.Report,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        if let markers = report.markers {
            for row in markers.rows {
                assertValidTimecode(row.position, format: format, sourceLocation: sourceLocation)
                if !row.sourcePosition.isEmpty {
                    assertValidTimecode(row.sourcePosition, format: format, sourceLocation: sourceLocation)
                }
            }
            assertSortedTimelinePositions(
                markers.rows.map(\.position),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let keywords = report.keywords {
            for row in keywords.rows {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.duration, format: format, sourceLocation: sourceLocation)
            }
            assertSortedTimelinePositions(
                keywords.rows.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let titles = report.titlesAndGenerators {
            for row in titles.rows {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.duration, format: format, sourceLocation: sourceLocation)
            }
            assertSortedTimelinePositions(
                titles.rows.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let transitions = report.transitions {
            for row in transitions.rows {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.duration, format: format, sourceLocation: sourceLocation)
            }
            assertSortedTimelinePositions(
                transitions.rows.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let effects = report.effects {
            for row in effects.rows {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
            }
            assertSortedTimelinePositions(
                effects.rows.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let speedChangeEffects = report.speedChangeEffects {
            for row in speedChangeEffects.rows {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
            }
            assertSortedTimelinePositions(
                speedChangeEffects.rows.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if let summary = report.summary {
            if let duration = summary.projectSummary?.duration, !duration.isEmpty {
                assertValidTimecode(duration, format: format, sourceLocation: sourceLocation)
            }
            for row in summary.roleDurations {
                assertValidTimecode(row.estimatedTotal, format: format, sourceLocation: sourceLocation)
            }
        }

        if let roleInventory = report.roleInventory {
            for row in roleInventory.selectedRoles {
                assertValidTimecode(row.timelineIn, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.timelineOut, format: format, sourceLocation: sourceLocation)
                assertValidTimecode(row.clipDuration, format: format, sourceLocation: sourceLocation)
                if !row.sourceIn.isEmpty {
                    assertValidTimecode(row.sourceIn, format: format, sourceLocation: sourceLocation)
                }
                if !row.sourceOut.isEmpty {
                    assertValidTimecode(row.sourceOut, format: format, sourceLocation: sourceLocation)
                }
                if !row.sourceDuration.isEmpty {
                    assertValidTimecode(row.sourceDuration, format: format, sourceLocation: sourceLocation)
                }
            }
            assertSortedTimelinePositions(
                roleInventory.selectedRoles.map(\.timelineIn),
                format: format,
                sourceLocation: sourceLocation
            )
        }
    }

    /// Asserts workbook column headers for each populated section match ``report/timecodeFormat``.
    static func assertReportColumnHeadersMatchTimecodeFormat(
        _ report: FinalCutPro.FCPXML.Report,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let format = report.timecodeFormat

        if report.markers != nil {
            let headers = FinalCutPro.FCPXML.MarkerReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[3], baseName: "Position", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(
                headers[8],
                baseName: "Source Position",
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if report.keywords != nil {
            let headers = FinalCutPro.FCPXML.KeywordReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[2], baseName: "Timeline In", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[3], baseName: "Timeline Out", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[4], baseName: "Duration", format: format, sourceLocation: sourceLocation)
        }

        if report.titlesAndGenerators != nil {
            let headers = FinalCutPro.FCPXML.TitleReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[4], baseName: "Timeline In", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[5], baseName: "Timeline Out", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[6], baseName: "Duration", format: format, sourceLocation: sourceLocation)
        }

        if report.transitions != nil {
            let headers = FinalCutPro.FCPXML.TransitionReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[3], baseName: "Timeline In", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[4], baseName: "Timeline Out", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[5], baseName: "Duration", format: format, sourceLocation: sourceLocation)
        }

        if report.effects != nil {
            let headers = FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[6], baseName: "Timeline In", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[7], baseName: "Timeline Out", format: format, sourceLocation: sourceLocation)
        }

        if report.speedChangeEffects != nil {
            let headers = FinalCutPro.FCPXML.EffectReportRow.columnHeaders(timecodeFormat: format)
            assertTimecodeHeader(headers[6], baseName: "Timeline In", format: format, sourceLocation: sourceLocation)
            assertTimecodeHeader(headers[7], baseName: "Timeline Out", format: format, sourceLocation: sourceLocation)
        }

        if let summary = report.summary, !summary.roleDurations.isEmpty {
            let headers = FinalCutPro.FCPXML.SummaryRoleDurationRow.columnHeaders(
                timecodeFormat: format
            )
            assertTimecodeHeader(
                headers[1],
                baseName: "Estimated Total",
                format: format,
                sourceLocation: sourceLocation
            )
        }

        if report.roleInventory != nil {
            let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
                metadataColumnKeys: report.roleInventory?.metadataColumnKeys ?? [],
                timecodeFormat: format
            )
            #expect(
                headers.contains(format.formattedColumnHeader("Timeline In")),
                sourceLocation: sourceLocation
            )
            #expect(
                headers.contains(format.formattedColumnHeader("Clip Duration")),
                sourceLocation: sourceLocation
            )
        }
    }

    private static func assertTimecodeHeader(
        _ header: String,
        baseName: String,
        format: FinalCutPro.FCPXML.ReportTimecodeFormat,
        sourceLocation: SourceLocation
    ) {
        #expect(
            header == format.formattedColumnHeader(baseName),
            sourceLocation: sourceLocation
        )
    }

    static func assertSortedTimelinePositions(
        _ positions: [String],
        format: FinalCutPro.FCPXML.ReportTimecodeFormat = .smpteFrames,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let sorted = positions.sorted {
            FinalCutPro.FCPXML.ReportFormatting.compareTimelinePositions(
                $0,
                $1,
                format: format
            ) == .orderedAscending
        }
        #expect(positions == sorted, sourceLocation: sourceLocation)
    }

    static func assertCheckmarkOrCross(
        _ value: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(value == "✓" || value == "✗", sourceLocation: sourceLocation)
    }
}

