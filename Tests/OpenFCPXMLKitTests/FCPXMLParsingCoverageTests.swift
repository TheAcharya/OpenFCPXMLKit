//
// FCPXMLParsingCoverageTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Parsing/Model coverage: audio source playback, analysis markers, tracking-shape, collection folder.
//

import XCTest
@testable import OpenFCPXMLKit
import SwiftTimecode
import CoreMedia

@available(macOS 26.0, *)
final class FCPXMLParsingCoverageTests: XCTestCase {
    func testAudioChannelSourceVolumeMuteAndFilterRoundTrip() {
        let source = FinalCutPro.FCPXML.AudioChannelSource(
            sourceChannels: "1, 2",
            role: FinalCutPro.FCPXML.AudioRole(role: "Dialogue")
        )
        source.volumeAdjustment = FinalCutPro.FCPXML.VolumeAdjustment(amount: -3)
        source.loudnessAdjustment = FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0.5, uniformity: 0.2)
        source.audioFilters = [
            FinalCutPro.FCPXML.AudioFilter(effectID: "rEQ", name: "EQ", isEnabled: true)
        ]
        let mute = FinalCutPro.FCPXML.Mute(
            start: Fraction(0, 1),
            duration: Fraction(1, 24),
            fadeIn: FinalCutPro.FCPXML.FadeIn(duration: CMTime(value: 1001, timescale: 24000))
        )
        source.element.addChild(mute.element)

        XCTAssertEqual(source.volumeAdjustment?.amount ?? 0, -3, accuracy: 0.001)
        XCTAssertEqual(source.loudnessAdjustment?.amount ?? 0, 0.5, accuracy: 0.001)
        XCTAssertEqual(source.audioFilters.count, 1)
        XCTAssertEqual(source.audioFilters.first?.effectID, "rEQ")
        XCTAssertEqual(Array(source.mutes).count, 1)
        XCTAssertNotNil(Array(source.mutes).first?.fadeIn)
    }

    func testAudioRoleSourceVoiceIsolationAndEnabled() {
        let source = FinalCutPro.FCPXML.AudioRoleSource(role: FinalCutPro.FCPXML.AudioRole(role: "Dialogue"))
        source.enabled = false
        source.voiceIsolationAdjustment = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "0.8")
        source.noiseReductionAdjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.4)

        XCTAssertFalse(source.enabled)
        XCTAssertEqual(source.voiceIsolationAdjustment?.amount, "0.8")
        XCTAssertEqual(source.noiseReductionAdjustment?.amount ?? 0, 0.4, accuracy: 0.001)
    }

    func testAnalysisMarkerParseExtractAndReportType() throws {
        let xml = """
        <asset-clip name="Clip" ref="r1" offset="0s" start="0s" duration="5s">
            <analysis-marker start="1s" duration="2s">
                <shot-type value="closeUp"/>
                <stabilization-type value="excessiveShake"/>
            </analysis-marker>
        </asset-clip>
        """
        let document = try OFKXMLDefaultFactory().makeDocument(xmlString: xml)
        guard let root = document.rootElement() else {
            XCTFail("Missing root element")
            return
        }
        guard let analysisElement = root.childElements.first(where: { $0.name == "analysis-marker" }),
              let analysis = analysisElement.fcpAsAnalysisMarker
        else {
            XCTFail("Missing analysis-marker")
            return
        }
        XCTAssertEqual(
            analysis.shotTypes.map { $0.value },
            [FinalCutPro.FCPXML.ShotType.Value.closeUp]
        )
        XCTAssertEqual(
            analysis.stabilizationTypes.map { $0.value },
            [FinalCutPro.FCPXML.StabilizationType.Value.excessiveShake]
        )
        XCTAssertEqual(analysis.displayName, "closeUp, excessiveShake")

        guard let marker = analysisElement.fcpAsMarker else {
            XCTFail("Marker wrap failed")
            return
        }
        XCTAssertEqual(marker.element.fcpMarkerKind, FinalCutPro.FCPXML.Marker.MarkerKind.analysis)
        switch marker.configuration {
        case let .analysis(shots, stabs):
            XCTAssertEqual(
                shots.map { $0.value },
                [FinalCutPro.FCPXML.ShotType.Value.closeUp]
            )
            XCTAssertEqual(
                stabs.map { $0.value },
                [FinalCutPro.FCPXML.StabilizationType.Value.excessiveShake]
            )
        default:
            XCTFail("Expected analysis configuration")
        }
        XCTAssertEqual(
            FinalCutPro.FCPXML.ReportFormatting.markerReportType(for: marker.configuration),
            FinalCutPro.FCPXML.MarkerReportType.analysis
        )
    }

    func testTrackingShapeAttributesRoundTrip() {
        let shape = FinalCutPro.FCPXML.ObjectTracker.TrackingShape(
            id: "ts1",
            name: "Face",
            offsetEnabled: true,
            analysisMethod: .machineLearning,
            dataLocator: "rData"
        )
        XCTAssertEqual(shape.id, "ts1")
        XCTAssertEqual(shape.name, "Face")
        XCTAssertTrue(shape.offsetEnabled)
        XCTAssertEqual(shape.analysisMethod, .machineLearning)
        XCTAssertEqual(shape.dataLocator, "rData")

        shape.analysisMethod = .automatic
        shape.offsetEnabled = false
        shape.dataLocator = nil
        XCTAssertEqual(shape.analysisMethod, .automatic)
        XCTAssertFalse(shape.offsetEnabled)
        XCTAssertNil(shape.dataLocator)
    }

    func testCollectionFolderSmartCollectionsCodable() throws {
        let smart = FinalCutPro.FCPXML.SmartCollectionValue(
            name: "People",
            match: .any,
            matchShots: [
                FinalCutPro.FCPXML.MatchShot(
                    shotTypes: [FinalCutPro.FCPXML.ShotType(value: .closeUp)]
                )
            ]
        )
        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Library",
            smartCollections: [smart]
        )
        XCTAssertEqual(folder.smartCollections.count, 1)
        XCTAssertEqual(folder.smartCollections.first?.name, "People")

        let data = try JSONEncoder().encode(folder)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.CollectionFolder.self, from: data)
        XCTAssertEqual(decoded.smartCollections.first?.match, .any)
        XCTAssertEqual(decoded.smartCollections.first?.matchShots.first?.shotTypes.first?.value, .closeUp)
    }

    func testTextStyleParseRoundTripDTDAttributes() throws {
        var style = FinalCutPro.FCPXML.TextStyle(value: "Hello")
        style.font = "Helvetica"
        style.fontSize = 24
        style.isBold = true
        style.alignment = .center
        style.isUnderlined = true
        style.backgroundColor = "0 0 0 1"

        let element = FinalCutPro.FCPXML.TextStyle.makeElement(from: style)
        let parsed = try XCTUnwrap(FinalCutPro.FCPXML.TextStyle.parse(from: element))
        XCTAssertEqual(parsed.value, "Hello")
        XCTAssertEqual(parsed.font, "Helvetica")
        XCTAssertEqual(parsed.fontSize, 24)
        XCTAssertEqual(parsed.isBold, true)
        XCTAssertEqual(parsed.alignment, .center)
        XCTAssertEqual(parsed.isUnderlined, true)
        XCTAssertEqual(parsed.backgroundColor, "0 0 0 1")
    }
}
