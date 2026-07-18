//
// FCPXMLParsingCoverageTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Parsing/Model coverage: audio source playback, analysis markers, tracking-shape, collection folder.
//

import CoreMedia
import Foundation
import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Parsing coverage")
struct FCPXMLParsingCoverageTests {
    @Test("Audio channel source volume, mute, and filter round-trip")
    func audioChannelSourceVolumeMuteAndFilterRoundTrip() {
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

        let volumeMatch = abs((source.volumeAdjustment?.amount ?? 0) - (-3)) < 0.001
        #expect(volumeMatch)
        let loudnessMatch = abs((source.loudnessAdjustment?.amount ?? 0) - 0.5) < 0.001
        #expect(loudnessMatch)
        #expect(source.audioFilters.count == 1)
        #expect(source.audioFilters.first?.effectID == "rEQ")
        #expect(Array(source.mutes).count == 1)
        #expect(Array(source.mutes).first?.fadeIn != nil)
    }

    @Test("Audio role source voice isolation and enabled")
    func audioRoleSourceVoiceIsolationAndEnabled() {
        let source = FinalCutPro.FCPXML.AudioRoleSource(role: FinalCutPro.FCPXML.AudioRole(role: "Dialogue"))
        source.enabled = false
        source.voiceIsolationAdjustment = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "0.8")
        source.noiseReductionAdjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.4)

        let isEnabled = source.enabled
        #expect(!isEnabled)
        #expect(source.voiceIsolationAdjustment?.amount == "0.8")
        let noiseMatch = abs((source.noiseReductionAdjustment?.amount ?? 0) - 0.4) < 0.001
        #expect(noiseMatch)
    }

    @Test("Analysis marker parse, extract, and report type")
    func analysisMarkerParseExtractAndReportType() throws {
        let xml = """
        <asset-clip name="Clip" ref="r1" offset="0s" start="0s" duration="5s">
            <analysis-marker start="1s" duration="2s">
                <shot-type value="closeUp"/>
                <stabilization-type value="excessiveShake"/>
            </analysis-marker>
        </asset-clip>
        """
        let document = try OFKXMLDefaultFactory().makeDocument(xmlString: xml)
        let root = try #require(document.rootElement())
        let analysisElement = try #require(
            root.childElements.first(where: { $0.name == "analysis-marker" })
        )
        let analysis = try #require(analysisElement.fcpAsAnalysisMarker)
        #expect(
            analysis.shotTypes.map { $0.value }
                == [FinalCutPro.FCPXML.ShotType.Value.closeUp]
        )
        #expect(
            analysis.stabilizationTypes.map { $0.value }
                == [FinalCutPro.FCPXML.StabilizationType.Value.excessiveShake]
        )
        #expect(analysis.displayName == "closeUp, excessiveShake")

        let marker = try #require(analysisElement.fcpAsMarker)
        #expect(marker.element.fcpMarkerKind == FinalCutPro.FCPXML.Marker.MarkerKind.analysis)
        if case let .analysis(shots, stabs) = marker.configuration {
            #expect(
                shots.map { $0.value }
                    == [FinalCutPro.FCPXML.ShotType.Value.closeUp]
            )
            #expect(
                stabs.map { $0.value }
                    == [FinalCutPro.FCPXML.StabilizationType.Value.excessiveShake]
            )
        } else {
            Issue.record("Expected analysis configuration")
        }
        #expect(
            FinalCutPro.FCPXML.ReportFormatting.markerReportType(for: marker.configuration)
                == FinalCutPro.FCPXML.MarkerReportType.analysis
        )
    }

    @Test("Tracking shape attributes round-trip")
    func trackingShapeAttributesRoundTrip() {
        let shape = FinalCutPro.FCPXML.ObjectTracker.TrackingShape(
            id: "ts1",
            name: "Face",
            offsetEnabled: true,
            analysisMethod: .machineLearning,
            dataLocator: "rData"
        )
        #expect(shape.id == "ts1")
        #expect(shape.name == "Face")
        #expect(shape.offsetEnabled)
        #expect(shape.analysisMethod == .machineLearning)
        #expect(shape.dataLocator == "rData")

        shape.analysisMethod = .automatic
        shape.offsetEnabled = false
        shape.dataLocator = nil
        #expect(shape.analysisMethod == .automatic)
        let offsetEnabled = shape.offsetEnabled
        #expect(!offsetEnabled)
        #expect(shape.dataLocator == nil)
    }

    @Test("Collection folder smart collections Codable")
    func collectionFolderSmartCollectionsCodable() throws {
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
        #expect(folder.smartCollections.count == 1)
        #expect(folder.smartCollections.first?.name == "People")

        let data = try JSONEncoder().encode(folder)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.CollectionFolder.self, from: data)
        #expect(decoded.smartCollections.first?.match == .any)
        #expect(decoded.smartCollections.first?.matchShots.first?.shotTypes.first?.value == .closeUp)
    }

    @Test("Text style parse round-trip DTD attributes")
    func textStyleParseRoundTripDTDAttributes() throws {
        var style = FinalCutPro.FCPXML.TextStyle(value: "Hello")
        style.font = "Helvetica"
        style.fontSize = 24
        style.isBold = true
        style.alignment = .center
        style.isUnderlined = true
        style.backgroundColor = "0 0 0 1"

        let element = FinalCutPro.FCPXML.TextStyle.makeElement(from: style)
        let parsed = try #require(FinalCutPro.FCPXML.TextStyle.parse(from: element))
        #expect(parsed.value == "Hello")
        #expect(parsed.font == "Helvetica")
        #expect(parsed.fontSize == 24)
        #expect(parsed.isBold == true)
        #expect(parsed.alignment == .center)
        #expect(parsed.isUnderlined == true)
        #expect(parsed.backgroundColor == "0 0 0 1")
    }
}
