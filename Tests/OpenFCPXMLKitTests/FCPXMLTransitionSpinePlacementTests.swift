//
//  FCPXMLTransitionSpinePlacementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for transition spine placement classification.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLTransitionSpinePlacementTests: XCTestCase {
    private typealias Transition = FinalCutPro.FCPXML.Transition
    
    func testSpinePlacementPrimaryForMainStorylineTransition() throws {
        let fcpxml = try loadFCPXMLSample(named: "TransitionMarkers1")
        let transitionElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "transition")
        )
        let transition = try XCTUnwrap(transitionElement.fcpAsTransition)
        
        XCTAssertEqual(
            transition.spinePlacement(breadcrumbs: []),
            .primary
        )
    }
    
    func testSpinePlacementSecondaryForLaneSpineTransition() async throws {
        let timeline = try timelineElement(fromSampleNamed: "TimelineSample")
        let transitions = await timeline.fcpExtract(types: [.transition], scope: .mainTimeline)
        
        let secondaryTransition = try XCTUnwrap(
            transitions.first { extracted in
                extracted.element.parentElement?.fcpLane != nil
                    && extracted.element.parentElement?.fcpLane != 0
            }
        )
        
        guard let transition = secondaryTransition.element.fcpAsTransition else {
            XCTFail("Expected transition model")
            return
        }
        
        XCTAssertEqual(
            transition.spinePlacement(breadcrumbs: secondaryTransition.breadcrumbs),
            .secondary
        )
    }
    
    func testSpinePlacementStaticHelperDetectsParentLaneSpine() {
        let parentSpine = OFKXMLDefaultFactory().makeElement(name: "spine")
        parentSpine.fcpLane = 1
        
        let placement = Transition.spinePlacement(
            parentElement: parentSpine,
            breadcrumbs: []
        )
        
        XCTAssertEqual(placement, .secondary)
    }
    
    func testSpinePlacementStaticHelperDetectsAncestorLaneSpine() {
        let laneSpine = OFKXMLDefaultFactory().makeElement(name: "spine")
        laneSpine.fcpLane = 2
        
        let placement = Transition.spinePlacement(
            parentElement: nil,
            breadcrumbs: [laneSpine]
        )
        
        XCTAssertEqual(placement, .secondary)
    }
    
    func testIsAppleSuppliedPrimaryEffectTrueForFxPlugCrossDissolve() throws {
        let fcpxml = try loadFCPXMLSample(named: "TransitionMarkers1")
        let transitionElement = try XCTUnwrap(
            firstDescendantElement(in: fcpxml.root.element, named: "transition")
        )
        let transition = try XCTUnwrap(transitionElement.fcpAsTransition)
        
        XCTAssertTrue(transition.isAppleSuppliedPrimaryEffect(in: fcpxml.root.resources))
    }
}
