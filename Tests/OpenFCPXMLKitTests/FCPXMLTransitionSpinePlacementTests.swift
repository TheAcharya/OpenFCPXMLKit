//
//  FCPXMLTransitionSpinePlacementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for transition spine placement classification.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Transition spine placement")
struct FCPXMLTransitionSpinePlacementTests {
    private typealias Transition = FinalCutPro.FCPXML.Transition

    @Test("Spine placement primary for main storyline transition")
    func spinePlacementPrimaryForMainStorylineTransition() throws {
        let fcpxml = try requireFCPXMLSample(named: "TransitionMarkers1")
        let transitionElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "transition")
        )
        let transition = try #require(transitionElement.fcpAsTransition)

        #expect(
            transition.spinePlacement(breadcrumbs: [])
                == .primary
        )
    }

    @Test("Spine placement secondary for lane spine transition")
    func spinePlacementSecondaryForLaneSpineTransition() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "TimelineSample")
        let transitions = await timeline.fcpExtract(types: [.transition], scope: .mainTimeline)

        let secondaryTransition = try #require(
            transitions.first { extracted in
                extracted.element.parentElement?.fcpLane != nil
                    && extracted.element.parentElement?.fcpLane != 0
            }
        )

        let transition = try #require(secondaryTransition.element.fcpAsTransition)

        #expect(
            transition.spinePlacement(breadcrumbs: secondaryTransition.breadcrumbs)
                == .secondary
        )
    }

    @Test("Spine placement static helper detects parent lane spine")
    func spinePlacementStaticHelperDetectsParentLaneSpine() {
        let parentSpine = OFKXMLDefaultFactory().makeElement(name: "spine")
        parentSpine.fcpLane = 1

        let placement = Transition.spinePlacement(
            parentElement: parentSpine,
            breadcrumbs: []
        )

        #expect(placement == .secondary)
    }

    @Test("Spine placement static helper detects ancestor lane spine")
    func spinePlacementStaticHelperDetectsAncestorLaneSpine() {
        let laneSpine = OFKXMLDefaultFactory().makeElement(name: "spine")
        laneSpine.fcpLane = 2

        let placement = Transition.spinePlacement(
            parentElement: nil,
            breadcrumbs: [laneSpine]
        )

        #expect(placement == .secondary)
    }

    @Test("isAppleSuppliedPrimaryEffect true for FxPlug Cross Dissolve")
    func isAppleSuppliedPrimaryEffectTrueForFxPlugCrossDissolve() throws {
        let fcpxml = try requireFCPXMLSample(named: "TransitionMarkers1")
        let transitionElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "transition")
        )
        let transition = try #require(transitionElement.fcpAsTransition)

        #expect(transition.isAppleSuppliedPrimaryEffect(in: fcpxml.root.resources))
    }
}

