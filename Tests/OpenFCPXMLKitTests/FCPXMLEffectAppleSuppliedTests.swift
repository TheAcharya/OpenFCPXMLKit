//
//  FCPXMLEffectAppleSuppliedTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Apple-supplied effect UID classification.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Effect Apple-supplied classification")
struct FCPXMLEffectAppleSuppliedTests {
    private typealias Effect = FinalCutPro.FCPXML.Effect

    @Test("isAppleSupplied FxPlug UID returns true")
    func isAppleSuppliedFxPlugUIDReturnsTrue() {
        #expect(
            Effect.isAppleSupplied(uid: "FxPlug:4731E73A-8DAC-4113-9A30-AE85B1761265")
        )
    }

    @Test("isAppleSupplied localized Motion template returns true")
    func isAppleSuppliedLocalizedMotionTemplateReturnsTrue() {
        #expect(
            Effect.isAppleSupplied(
                uid: ".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"
            )
        )
    }

    @Test("isAppleSupplied ellipsis-prefixed returns true")
    func isAppleSuppliedEllipsisPrefixedReturnsTrue() {
        #expect(Effect.isAppleSupplied(uid: ".../Effects.localized/Custom.moti"))
    }

    @Test("isAppleSupplied tilde-prefixed returns false")
    func isAppleSuppliedTildePrefixedReturnsFalse() {
        let isApple = Effect.isAppleSupplied(uid: "~/Effects/Custom.moti")
        #expect(!isApple)
    }

    @Test("isAppleSupplied empty UID returns false")
    func isAppleSuppliedEmptyUIDReturnsFalse() {
        let isApple = Effect.isAppleSupplied(uid: "")
        #expect(!isApple)
    }

    @Test("isAppleSupplied third-party UID returns false")
    func isAppleSuppliedThirdPartyUIDReturnsFalse() {
        let isApple = Effect.isAppleSupplied(uid: "com.vendor.custom-effect")
        #expect(!isApple)
    }

    @Test("Effect instance reflects UID classification")
    func effectInstanceReflectsUIDClassification() {
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

        #expect(appleEffect.isAppleSupplied)
        let customIsApple = customEffect.isAppleSupplied
        #expect(!customIsApple)
    }

    @Test("Transition primary effect from sample is Apple-supplied")
    func transitionPrimaryEffectFromSampleIsAppleSupplied() throws {
        let fcpxml = try requireFCPXMLSample(named: "TransitionMarkers1")
        let resources = fcpxml.root.resources

        let transitionElement = try #require(
            firstDescendantElement(in: fcpxml.root.element, named: "transition")
        )
        let transition = try #require(transitionElement.fcpAsTransition)

        #expect(transition.isAppleSuppliedPrimaryEffect(in: resources))
    }
}
