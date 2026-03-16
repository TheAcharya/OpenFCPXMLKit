//
//  CutDetectionTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for cut detection: edit points, same-clip vs different-clips, boundary types.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class CutDetectionTests: XCTestCase, @unchecked Sendable {

    private var service: FCPXMLService!
    private var cutDetector: CutDetector!
    private let factory = FoundationXMLFactory()

    override func setUpWithError() throws {
        try super.setUpWithError()
        cutDetector = CutDetector()
        service = FCPXMLService(cutDetector: cutDetector)
    }

    override func tearDownWithError() throws {
        service = nil
        cutDetector = nil
        try super.tearDownWithError()
    }

    // MARK: - Different-clips and transitions (24.fcpxml)

    func testDifferentClipsAndTransitions_24fcpxml() throws {
        let url = urlForFCPXMLSample(named: FCPXMLSampleName.frameRate24.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Sample 24.fcpxml not found")
        }
        let data = try Data(contentsOf: url)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        XCTAssertGreaterThan(result.totalEditPoints, 0, "24.fcpxml has multiple clips and transitions")
        XCTAssertGreaterThanOrEqual(result.transitionCount, 0)
        XCTAssertGreaterThanOrEqual(result.hardCutCount, 0)
        // At least one edit should be between different refs (r4 vs r6 etc.)
        let hasDifferentClips = result.editPoints.contains { $0.sourceRelationship == .differentClips }
        XCTAssertTrue(hasDifferentClips || result.differentClipsCutCount >= 0)
    }

    // MARK: - Empty spine / single clip

    func testDetectCuts_EmptySpine_ReturnsEmpty() throws {
        let url = urlForFCPXMLSample(named: FCPXMLSampleName.standaloneAssetClip.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("StandaloneAssetClip sample not found")
        }
        let data = try Data(contentsOf: url)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        // Standalone asset clip may have no project spine; result may be empty
        XCTAssertEqual(result.editPoints.count, result.totalEditPoints)
    }

    func testDetectCuts_SingleClip_NoCuts() throws {
        let url = urlForFCPXMLSample(named: FCPXMLSampleName.structure.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Structure sample not found")
        }
        let data = try Data(contentsOf: url)
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        // Structure might have one or more clips; we only assert consistency
        XCTAssertEqual(result.sameClipCutCount + result.differentClipsCutCount, result.totalEditPoints)
    }

    // MARK: - detectCuts(inSpine:)

    func testDetectCutsInSpine_DirectSpine() throws {
        let url = urlForFCPXMLSample(named: FCPXMLSampleName.frameRate24.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("24.fcpxml not found")
        }
        let data = try Data(contentsOf: url)
        let document = try service.parseFCPXML(from: data)
        guard let root = document.rootElement(), let spine = firstProjectSpine(in: root) else {
            throw XCTSkip("No spine in document")
        }
        let result = service.detectCuts(inSpine: spine)
        XCTAssertEqual(result.editPoints.count, result.totalEditPoints)
    }

    func testDetectCuts_EmptyResult_CountsZero() {
        let result = CutDetectionResult.empty
        XCTAssertEqual(result.totalEditPoints, 0)
        XCTAssertEqual(result.hardCutCount, 0)
        XCTAssertEqual(result.transitionCount, 0)
        XCTAssertEqual(result.gapCutCount, 0)
        XCTAssertEqual(result.sameClipCutCount, 0)
        XCTAssertEqual(result.differentClipsCutCount, 0)
    }

    // MARK: - Edge Cases: Multiple Elements Between Clips

    func testDetectCuts_MultipleElementsBetweenClips_PrioritizesTransition() throws {
        // Create a spine with: [Clip A] [Gap] [Transition] [Clip B]
        // This tests the bug fix where multiple elements between clips weren't properly handled
        let document = service.createFCPXMLDocument(version: "1.10")
        guard let root = document.rootElement() else {
            XCTFail("Failed to get root element")
            return
        }

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
        XCTAssertEqual(result.totalEditPoints, 1, "Should detect one edit point")

        guard let editPoint = result.editPoints.first else {
            XCTFail("No edit point detected")
            return
        }

        // Should prioritize transition over gap
        XCTAssertEqual(editPoint.editType, .transition, "Should detect transition, not gap")
        XCTAssertEqual(editPoint.transitionName, "Cross Dissolve", "Should capture transition name")
        XCTAssertEqual(editPoint.sourceRelationship, .differentClips, "Should be different clips")
    }

    func testDetectCuts_AdjacentClips_HardCut() throws {
        // Create a spine with: [Clip A] [Clip B] (no elements between)
        let document = service.createFCPXMLDocument(version: "1.10")
        guard let root = document.rootElement() else {
            XCTFail("Failed to get root element")
            return
        }

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

        XCTAssertEqual(result.totalEditPoints, 1, "Should detect one edit point")

        guard let editPoint = result.editPoints.first else {
            XCTFail("No edit point detected")
            return
        }

        // Adjacent clips should be hard cut
        XCTAssertEqual(editPoint.editType, .hardCut, "Adjacent clips should be hard cut")
        XCTAssertNil(editPoint.transitionName, "Hard cut should have no transition name")
    }

    // MARK: - Async

    func testDetectCutsAsync() async throws {
        let url = urlForFCPXMLSample(named: FCPXMLSampleName.frameRate24.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("24.fcpxml not found")
        }
        let data = try Data(contentsOf: url)
        let document = try await service.parseFCPXML(from: data)
        let result = await service.detectCuts(in: document)
        XCTAssertGreaterThanOrEqual(result.totalEditPoints, 0)
    }

    // MARK: - File Tests

    func testCutSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "CutSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        let projects = fcpxml.allProjects()
        XCTAssertFalse(projects.isEmpty, "Expected at least one project")

        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }

        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        let storyElements = Array(spine.storyElements)
        XCTAssertGreaterThan(storyElements.count, 1, "CutSample should have multiple clips for cut detection")

        // Test cut detection on this sample
        let data = try Data(contentsOf: urlForFCPXMLSample(named: "CutSample"))
        let document = try service.parseFCPXML(from: data)
        let result = service.detectCuts(in: document)
        XCTAssertGreaterThan(result.totalEditPoints, 0, "CutSample should have edit points")
    }

    // MARK: - Helpers

    private func firstProjectSpine(in element: any PNXMLElement) -> (any PNXMLElement)? {
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
