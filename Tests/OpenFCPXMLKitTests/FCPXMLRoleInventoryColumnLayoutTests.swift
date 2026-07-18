//
//  FCPXMLRoleInventoryColumnLayoutTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Selected Roles Inventory column layout and metadata discovery.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory column layout")
struct FCPXMLRoleInventoryColumnLayoutTests {
    private typealias Layout = FinalCutPro.FCPXML.RoleInventoryColumnLayout
    private typealias RoleRow = FinalCutPro.FCPXML.RoleClipReportRow

    @Test("Column headers include Row and fixed columns")
    func columnHeadersIncludeRowAndFixedColumns() {
        let headers = Layout.columnHeaders(metadataColumnKeys: [])

        #expect(headers.first == "Row")
        #expect(
            Array(headers.dropFirst()) == RoleRow.fixedColumnHeaders
        )
    }

    @Test("Metadata column keys exclude dedicated fixed columns")
    func metadataColumnKeysExcludesDedicatedFixedColumns() {
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

        #expect(keys == [
            FinalCutPro.FCPXML.Metadata.Key.ingestDate.rawValue,
            FinalCutPro.FCPXML.Metadata.Key.cameraAngle.rawValue
        ])
    }

    @Test("Column values include row index and dynamic metadata")
    func columnValuesIncludeRowIndexAndDynamicMetadata() {
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

        #expect(values.first == "5")
        #expect(values[1] == "Video")
        #expect(values[values.count - 1] == "2024-01-01")
    }

    @Test("Inventory audio rate display uses kilohertz label")
    func inventoryAudioRateDisplayUsesKilohertzLabel() {
        #expect(
            FinalCutPro.FCPXML.ReportFormatting.inventoryAudioRateDisplay(.rate48kHz)
                == "48 kHz"
        )
        #expect(
            FinalCutPro.FCPXML.ReportFormatting.inventoryAudioRateDisplay(.rate44_1kHz)
                == "44.1 kHz"
        )
    }
}
