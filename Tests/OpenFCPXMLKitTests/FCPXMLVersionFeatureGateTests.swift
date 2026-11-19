//
//  FCPXMLVersionFeatureGateTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	VersionFeatureGate registry: omit sets and Authoring/converter alignment.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Version feature gate")
struct FCPXMLVersionFeatureGateTests {
    @Test("Element omit set for 1.5 includes post-1.5 features")
    func elementOmitSetFor1_5() {
        let omitted = FinalCutPro.FCPXML.VersionFeatureGate.elementNamesToOmit(at: .v1_5)
        #expect(omitted.contains("adjust-cinematic"))
        #expect(omitted.contains("match-usage"))
        #expect(omitted.contains("live-drawing"))
        #expect(omitted.contains("hidden-clip-marker"))
        #expect(omitted.contains("match-analysis-type"))
        #expect(!omitted.contains("asset-clip"))
    }

    @Test("Element omit set for 1.15 is empty and 1.14 omits 1.15 elements")
    func elementOmitSetFor1_15Empty() {
        let omitted = FinalCutPro.FCPXML.VersionFeatureGate.elementNamesToOmit(at: .v1_15)
        #expect(omitted.isEmpty)
        let at114 = FinalCutPro.FCPXML.VersionFeatureGate.elementNamesToOmit(at: .v1_14)
        #expect(at114.contains("adjust-natural-motion-blur"))
        #expect(at114.contains("mask-semantic"))
        #expect(!at114.contains("match-analysis-type"))
    }

    @Test("Attribute omit set for heroEye before 1.13")
    func attributeOmitHeroEyeBefore1_13() {
        let at112 = FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
            onElement: "format",
            at: .v1_12
        )
        #expect(at112.contains("heroEye"))
        let at113 = FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
            onElement: "format",
            at: .v1_13
        )
        #expect(at113.isEmpty)
    }

    @Test("Cinematic availability matches feature gate")
    func cinematicAvailabilityMatchesGate() {
        let gate = FinalCutPro.FCPXML.VersionFeatureGate.availability(forElement: "adjust-cinematic")
        #expect(gate.contains(.v1_10))
        #expect(!gate.contains(.v1_9))
        #expect(
            FinalCutPro.FCPXML.Authoring.CinematicAdjustment().availability == gate
        )
    }
}
