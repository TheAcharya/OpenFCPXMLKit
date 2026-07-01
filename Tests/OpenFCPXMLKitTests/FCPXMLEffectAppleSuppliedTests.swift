//
//  FCPXMLEffectAppleSuppliedTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Apple-supplied effect UID classification.
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLEffectAppleSuppliedTests: XCTestCase {
    private typealias Effect = FinalCutPro.FCPXML.Effect
    
    func testIsAppleSuppliedFxPlugUIDReturnsTrue() {
        XCTAssertTrue(
            Effect.isAppleSupplied(uid: "FxPlug:4731E73A-8DAC-4113-9A30-AE85B1761265")
        )
    }
    
    func testIsAppleSuppliedLocalizedMotionTemplateReturnsTrue() {
        XCTAssertTrue(
            Effect.isAppleSupplied(
                uid: ".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"
            )
        )
    }
    
    func testIsAppleSuppliedEllipsisPrefixedReturnsTrue() {
        XCTAssertTrue(Effect.isAppleSupplied(uid: ".../Effects.localized/Custom.moti"))
    }
    
    func testIsAppleSuppliedTildePrefixedReturnsFalse() {
        XCTAssertFalse(Effect.isAppleSupplied(uid: "~/Effects/Custom.moti"))
    }
    
    func testIsAppleSuppliedEmptyUIDReturnsFalse() {
        XCTAssertFalse(Effect.isAppleSupplied(uid: ""))
    }
    
    func testIsAppleSuppliedThirdPartyUIDReturnsFalse() {
        XCTAssertFalse(Effect.isAppleSupplied(uid: "com.vendor.custom-effect"))
    }
    
    func testEffectInstanceReflectsUIDClassification() {
        let appleEffect = Effect(
            id: "r1",
            name: "Cross Dissolve",
            uid: "FxPlug:4731E73A-8DAC-4113-9A30-AE85B1761265"
        )
        let customEffect = Effect(
            id: "r2",
            name: "Vendor Effect",
            uid: "com.vendor.effect"
        )
        
        XCTAssertTrue(appleEffect.isAppleSupplied)
        XCTAssertFalse(customEffect.isAppleSupplied)
    }
    
    func testTransitionPrimaryEffectFromSampleIsAppleSupplied() throws {
        let fcpxml = try loadFCPXMLSample(named: "TransitionMarkers1")
        let resources = fcpxml.root.resources
        
        guard let transitionElement = firstDescendantElement(
            in: fcpxml.root.element,
            named: "transition"
        ) else {
            XCTFail("Expected transition in TransitionMarkers1")
            return
        }
        
        guard let transition = transitionElement.fcpAsTransition else {
            XCTFail("Could not wrap transition element")
            return
        }
        
        XCTAssertTrue(transition.isAppleSuppliedPrimaryEffect(in: resources))
    }
}
