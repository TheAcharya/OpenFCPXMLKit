//
//  FCPXMLRoleInventoryColumnLayoutTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Selected Roles Inventory column layout and metadata discovery.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLRoleInventoryColumnLayoutTests: XCTestCase {
    private typealias Layout = FinalCutPro.FCPXML.RoleInventoryColumnLayout
    private typealias RoleRow = FinalCutPro.FCPXML.RoleClipReportRow
    
    func testColumnHeadersIncludeRowAndFixedColumns() {
        let headers = Layout.columnHeaders(metadataColumnKeys: [])
        
        XCTAssertEqual(headers.first, "Row")
        XCTAssertEqual(
            Array(headers.dropFirst()),
            RoleRow.fixedColumnHeaders
        )
    }
    
    func testMetadataColumnKeysExcludesDedicatedFixedColumns() {
        let row = RoleRow(
            roleSubrole: "Video",
            clipName: "Clip",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "",
            metadataValues: [
                FinalCutPro.FCPXML.Metadata.Key.reel.rawValue: "A001",
                FinalCutPro.FCPXML.Metadata.Key.scene.rawValue: "1",
                FinalCutPro.FCPXML.Metadata.Key.take.rawValue: "3",
                FinalCutPro.FCPXML.Metadata.Key.cameraName.rawValue: "Cam A",
                FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue: "2024-01-01",
                FinalCutPro.FCPXML.Metadata.Key.cameraAngle.rawValue: "A"
            ]
        )
        
        let keys = Layout.metadataColumnKeys(from: [row])
        
        XCTAssertEqual(keys, [
            FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue,
            FinalCutPro.FCPXML.Metadata.Key.cameraAngle.rawValue
        ])
    }
    
    func testColumnValuesIncludeRowIndexAndDynamicMetadata() {
        let ingestKey = FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue
        let row = RoleRow(
            roleSubrole: "Video",
            clipName: "Clip",
            category: "Primary video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:01:00",
            clipDuration: "00:00:01:00",
            sourceIn: "",
            sourceOut: "",
            sourceDuration: "",
            frameRateSampleRate: "24 fps",
            frameSize: "1920 × 1080",
            metadataValues: [ingestKey: "2024-01-01"]
        )
        
        let values = Layout.columnValues(
            for: row,
            rowIndex: 5,
            metadataColumnKeys: [ingestKey]
        )
        
        XCTAssertEqual(values.first, "5")
        XCTAssertEqual(values[1], "Video")
        XCTAssertEqual(values[values.count - 1], "2024-01-01")
    }
    
    func testInventoryAudioRateDisplayUsesKilohertzLabel() {
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportFormatting.inventoryAudioRateDisplay(.rate48kHz),
            "48 kHz"
        )
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportFormatting.inventoryAudioRateDisplay(.rate44_1kHz),
            "44.1 kHz"
        )
    }
}
