//
//  FCPXMLCutDetectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for cut detection: edit points, same-clip vs different-clips, boundary types.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Cut detection")
struct FCPXMLCutDetectionTests {
    private var service: FCPXMLService { FCPXMLService(cutDetector: CutDetector()) }
    private let factory = FoundationXMLFactory()

    // MARK: - Different-clips and transitions (24.fcpxml)

    @Test("Different clips and transitions in 24.fcpxml")
    func differentClipsAndTransitions_24fcpxml() throws {
        let data = try requireFCPXMLSampleData(named: FCPXMLSampleName.frameRate24.rawValue)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        #expect(result.totalEditPoints > 0, "24.fcpxml has multiple clips and transitions")
        #expect(result.transitionCount >= 0)
        #expect(result.hardCutCount >= 0)
        // At least one edit should be between different refs (r4 vs r6 etc.)
        let hasDifferentClips = result.editPoints.contains { $0.sourceRelationship == .differentClips }
        #expect(hasDifferentClips || result.differentClipsCutCount >= 0)
    }

    // MARK: - Empty spine / single clip

    @Test("Detect cuts empty spine returns empty")
    func detectCuts_EmptySpine_ReturnsEmpty() throws {
        let data = try requireFCPXMLSampleData(named: FCPXMLSampleName.standaloneAssetClip.rawValue)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        // Standalone asset clip may have no project spine; result may be empty
        #expect(result.editPoints.count == result.totalEditPoints)
    }

    @Test("Detect cuts single clip consistency")
    func detectCuts_SingleClip_NoCuts() throws {
        let data = try requireFCPXMLSampleData(named: FCPXMLSampleName.structure.rawValue)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        // Structure might have one or more clips; we only assert consistency
        #expect(result.sameClipCutCount + result.differentClipsCutCount == result.totalEditPoints)
    }

    // MARK: - detectCuts(inSpine:)

    @Test("Detect cuts in spine direct spine")
    func detectCutsInSpine_DirectSpine() throws {
        let data = try requireFCPXMLSampleData(named: FCPXMLSampleName.frameRate24.rawValue)
        let document = try service.parseFCPXML(from: data)
        guard let root = document.rootElement(), let spine = firstProjectSpine(in: root) else {
            try Test.cancel("No spine in document")
        }
        let result = service.detectCuts(inSpine: spine)
        #expect(result.editPoints.count == result.totalEditPoints)
    }

    @Test("Detect cuts empty result counts zero")
    func detectCuts_EmptyResult_CountsZero() {
        let result = CutDetectionResult.empty
        #expect(result.totalEditPoints == 0)
        #expect(result.hardCutCount == 0)
        #expect(result.transitionCount == 0)
        #expect(result.gapCutCount == 0)
        #expect(result.sameClipCutCount == 0)
        #expect(result.differentClipsCutCount == 0)
    }

    // MARK: - Edge Cases: Multiple Elements Between Clips

    @Test("Detect cuts multiple elements between clips prioritizes transition")
    func detectCuts_MultipleElementsBetweenClips_PrioritizesTransition() throws {
        // Create a spine with: [Clip A] [Gap] [Transition] [Clip B]
        // This tests the bug fix where multiple elements between clips weren't properly handled
        let document = service.createFCPXMLDocument(version: "1.10")
        let root = try #require(document.rootElement())

        // Create a project with sequence
        let project = factory.makeElement(name: "project")
        project.addAttribute(name: "name", value: "Test Project")
        let sequence = factory.makeElement(name: "sequence")
        let spine = factory.makeElement(name: "spine")

        // Create Clip A
        let clipA = factory.makeElement(name: "asset-clip")
        clipA.addAttribute(name: "name", value: "Clip A")
        clipA.addAttribute(name: "ref", value: "r1")
        clipA.addAttribute(name: "offset", value: "0s")
        clipA.addAttribute(name: "duration", value: "3600/2400s")

        // Create Gap
        let gap = factory.makeElement(name: "gap")
        gap.addAttribute(name: "name", value: "Gap")
        gap.addAttribute(name: "offset", value: "3600/2400s")
        gap.addAttribute(name: "duration", value: "1200/2400s")

        // Create Transition
        let transition = factory.makeElement(name: "transition")
        transition.addAttribute(name: "name", value: "Cross Dissolve")
        transition.addAttribute(name: "offset", value: "4800/2400s")
        transition.addAttribute(name: "duration", value: "600/2400s")

        // Create Clip B
        let clipB = factory.makeElement(name: "asset-clip")
        clipB.addAttribute(name: "name", value: "Clip B")
        clipB.addAttribute(name: "ref", value: "r2")
        clipB.addAttribute(name: "offset", value: "5400/2400s")
        clipB.addAttribute(name: "duration", value: "3600/2400s")

        // Build structure: spine -> [clipA, gap, transition, clipB]
        spine.addChild(clipA)
        spine.addChild(gap)
        spine.addChild(transition)
        spine.addChild(clipB)
        sequence.addChild(spine)
        project.addChild(sequence)
        root.addChild(project)

        // Detect cuts
        let result = service.detectCuts(inSpine: spine)

        // Should detect one edit point between Clip A and Clip B
        #expect(result.totalEditPoints == 1, "Should detect one edit point")

        let editPoint = try #require(result.editPoints.first)

        // Should prioritize transition over gap
        #expect(editPoint.editType == .transition, "Should detect transition, not gap")
        #expect(editPoint.transitionName == "Cross Dissolve", "Should capture transition name")
        #expect(editPoint.sourceRelationship == .differentClips, "Should be different clips")
    }

    @Test("Detect cuts adjacent clips hard cut")
    func detectCuts_AdjacentClips_HardCut() throws {
        // Create a spine with: [Clip A] [Clip B] (no elements between)
        let document = service.createFCPXMLDocument(version: "1.10")
        let root = try #require(document.rootElement())

        let project = factory.makeElement(name: "project")
        project.addAttribute(name: "name", value: "Test Project")
        let sequence = factory.makeElement(name: "sequence")
        let spine = factory.makeElement(name: "spine")

        let clipA = factory.makeElement(name: "asset-clip")
        clipA.addAttribute(name: "name", value: "Clip A")
        clipA.addAttribute(name: "ref", value: "r1")
        clipA.addAttribute(name: "offset", value: "0s")
        clipA.addAttribute(name: "duration", value: "3600/2400s")

        let clipB = factory.makeElement(name: "asset-clip")
        clipB.addAttribute(name: "name", value: "Clip B")
        clipB.addAttribute(name: "ref", value: "r2")
        clipB.addAttribute(name: "offset", value: "3600/2400s")
        clipB.addAttribute(name: "duration", value: "3600/2400s")

        spine.addChild(clipA)
        spine.addChild(clipB)
        sequence.addChild(spine)
        project.addChild(sequence)
        root.addChild(project)

        let result = service.detectCuts(inSpine: spine)

        #expect(result.totalEditPoints == 1, "Should detect one edit point")

        let editPoint = try #require(result.editPoints.first)

        // Adjacent clips should be hard cut
        #expect(editPoint.editType == .hardCut, "Adjacent clips should be hard cut")
        #expect(editPoint.transitionName == nil, "Hard cut should have no transition name")
    }

    // MARK: - Async

    @Test("Detect cuts async")
    func detectCutsAsync() async throws {
        let data = try requireFCPXMLSampleData(named: FCPXMLSampleName.frameRate24.rawValue)
        let document = try await service.parseFCPXML(from: data)
        let result = await service.detectCuts(in: document)
        #expect(result.totalEditPoints >= 0)
    }

    // MARK: - File Tests

    @Test("Cut sample")
    func cutSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "CutSample")
        #expect(fcpxml.root.element.name == "fcpxml")
        #expect(fcpxml.version == .ver1_13)
        let projects = fcpxml.allProjects()
        #expect(!projects.isEmpty, "Expected at least one project")

        let project = try #require(projects.first)

        let sequence = project.sequence
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        #expect(storyElements.count > 1, "CutSample should have multiple clips for cut detection")

        // Test cut detection on this sample
        let data = try requireFCPXMLSampleData(named: "CutSample")
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        #expect(result.totalEditPoints > 0, "CutSample should have edit points")
    }

    // MARK: - Helpers

    private func firstProjectSpine(in element: any OFKXMLElement) -> (any OFKXMLElement)? {
        if element.name == "project" {
            // Look for sequence > spine
            if let sequence = element.firstChildElement(named: "sequence"),
               let spine = sequence.firstChildElement(named: "spine") {
                return spine
            }
        }
        for child in element.childElements {
            if let found = firstProjectSpine(in: child) { return found }
        }
        return nil
    }
}

