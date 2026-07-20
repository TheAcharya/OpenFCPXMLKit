//
//  FCPXMLRoleInventorySheetTotalTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Per-role inventory sheet Total footer summation and column placement.
//

import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory sheet total")
struct FCPXMLRoleInventorySheetTotalTests {
    private typealias Total = FinalCutPro.FCPXML.RoleInventorySheetTotal
    private typealias Row = FinalCutPro.FCPXML.RoleClipReportRow
    
    private func sampleRow(clipDuration: String, frameRate: String = "24 fps") -> Row {
        Row(
            roleSubrole: "Video",
            clipName: "Clip",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:10:00",
            clipDuration: clipDuration,
            sourceIn: "",
            sourceOut: "",
            sourceDuration: clipDuration,
            frameRateSampleRate: frameRate
        )
    }
    
    @Test("Optimistic SMPTE total sums clip durations")
    func optimisticSmpteTotalSumsClipDurations() {
        let rows = [
            sampleRow(clipDuration: "00:00:10:00"),
            sampleRow(clipDuration: "00:00:05:00")
        ]
        #expect(Total.optimisticClipDurationTotal(from: rows, timecodeFormat: .smpteFrames) == "00:00:15:00")
    }
    
    @Test("Optimistic frames total sums integer clip durations")
    func optimisticFramesTotalSumsIntegerClipDurations() {
        let rows = [
            sampleRow(clipDuration: "240"),
            sampleRow(clipDuration: "120")
        ]
        #expect(Total.optimisticClipDurationTotal(from: rows, timecodeFormat: .frames) == "360")
    }
    
    @Test("Footer column indices align Timeline Out and Clip Duration headers")
    func footerColumnIndicesAlignTimelineOutAndClipDuration() {
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: [],
            excludedColumns: [],
            timecodeFormat: .smpteFrames
        )
        let indices = Total.footerColumnIndices(
            in: headers,
            excludedColumns: [],
            timecodeFormat: .smpteFrames
        )
        #expect(indices?.label == headers.firstIndex(of: "Timeline Out"))
        #expect(indices?.value == headers.firstIndex(of: "Clip Duration"))
    }
    
    @Test("Footer column indices are nil when Clip Duration is excluded")
    func footerColumnIndicesNilWhenClipDurationExcluded() {
        let headers = FinalCutPro.FCPXML.RoleInventoryColumnLayout.columnHeaders(
            metadataColumnKeys: [],
            excludedColumns: [.clipDuration],
            timecodeFormat: .smpteFrames
        )
        let indices = Total.footerColumnIndices(
            in: headers,
            excludedColumns: [.clipDuration],
            timecodeFormat: .smpteFrames
        )
        #expect(indices == nil)
    }
}

