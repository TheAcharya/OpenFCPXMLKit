//
//  FCPXMLKeyframeAnimationTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FadeIn/FadeOut, Keyframe, KeyframeAnimation, and FilterParameter integration.
//

import CoreMedia
import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Keyframe animation")
struct FCPXMLKeyframeAnimationTests {

    // MARK: - FadeType Tests

    @Test("FadeType raw values")
    func fadeTypeCases() {
        #expect(FinalCutPro.FCPXML.FadeType.linear.rawValue == "linear")
        #expect(FinalCutPro.FCPXML.FadeType.easeIn.rawValue == "easeIn")
        #expect(FinalCutPro.FCPXML.FadeType.easeOut.rawValue == "easeOut")
        #expect(FinalCutPro.FCPXML.FadeType.easeInOut.rawValue == "easeInOut")
    }

    // MARK: - FadeIn Tests

    @Test("FadeIn initialization")
    func fadeInInitialization() {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(type: .easeIn, duration: duration)

        #expect(fadeIn.type == .easeIn)
        #expect(fadeIn.duration == duration)
    }

    @Test("FadeIn default type is easeIn")
    func fadeInDefaultType() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(duration: duration)

        #expect(fadeIn.type == .easeIn)
    }

    @Test("FadeIn Codable round-trip")
    func fadeInCodable() throws {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(type: .linear, duration: duration)

        let encoder = JSONEncoder()
        let data = try encoder.encode(fadeIn)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FadeIn.self, from: data)

        #expect(decoded.type == fadeIn.type)
        #expect(decoded.duration.value == fadeIn.duration.value)
        #expect(decoded.duration.timescale == fadeIn.duration.timescale)
    }

    // MARK: - FadeOut Tests

    @Test("FadeOut initialization")
    func fadeOutInitialization() {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(type: .easeOut, duration: duration)

        #expect(fadeOut.type == .easeOut)
        #expect(fadeOut.duration == duration)
    }

    @Test("FadeOut default type is easeOut")
    func fadeOutDefaultType() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(duration: duration)

        #expect(fadeOut.type == .easeOut)
    }

    @Test("FadeOut Codable round-trip")
    func fadeOutCodable() throws {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(type: .easeInOut, duration: duration)

        let encoder = JSONEncoder()
        let data = try encoder.encode(fadeOut)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FadeOut.self, from: data)

        #expect(decoded.type == fadeOut.type)
        #expect(decoded.duration.value == fadeOut.duration.value)
        #expect(decoded.duration.timescale == fadeOut.duration.timescale)
    }

    // MARK: - Keyframe Tests

    @Test("Keyframe initialization")
    func keyframeInitialization() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(
            time: time,
            value: "0.5",
            interpolation: .linear,
            curve: .smooth
        )

        #expect(keyframe.time == time)
        #expect(keyframe.value == "0.5")
        #expect(keyframe.interpolation == .linear)
        #expect(keyframe.curve == .smooth)
    }

    @Test("Keyframe default interpolation and curve")
    func keyframeDefaultValues() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(time: time, value: "1.0")

        #expect(keyframe.interpolation == .linear)
        #expect(keyframe.curve == .smooth)
    }

    @Test("Keyframe with auxValue")
    func keyframeWithAuxValue() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(
            time: time,
            value: "0.5",
            auxValue: "0.3"
        )

        #expect(keyframe.auxValue == "0.3")
    }

    @Test("KeyframeInterpolation raw values")
    func keyframeInterpolationCases() {
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.linear.rawValue == "linear")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.ease.rawValue == "ease")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.easeIn.rawValue == "easeIn")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.easeOut.rawValue == "easeOut")
    }

    @Test("KeyframeCurve raw values")
    func keyframeCurveCases() {
        #expect(FinalCutPro.FCPXML.KeyframeCurve.linear.rawValue == "linear")
        #expect(FinalCutPro.FCPXML.KeyframeCurve.smooth.rawValue == "smooth")
    }

    @Test("Keyframe Codable round-trip")
    func keyframeCodable() throws {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(
            time: time,
            value: "0.5",
            auxValue: "0.3",
            interpolation: .ease,
            curve: .linear
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(keyframe)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Keyframe.self, from: data)

        #expect(decoded.value == keyframe.value)
        #expect(decoded.auxValue == keyframe.auxValue)
        #expect(decoded.interpolation == keyframe.interpolation)
        #expect(decoded.curve == keyframe.curve)
    }

    // MARK: - KeyframeAnimation Tests

    @Test("KeyframeAnimation initialization")
    func keyframeAnimationInitialization() {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")

        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])

        #expect(animation.keyframes.count == 2)
        #expect(animation.keyframes[0].value == "0.0")
        #expect(animation.keyframes[1].value == "1.0")
    }

    @Test("KeyframeAnimation empty")
    func keyframeAnimationEmpty() {
        let animation = FinalCutPro.FCPXML.KeyframeAnimation()

        #expect(animation.keyframes.count == 0)
    }

    @Test("KeyframeAnimation Codable round-trip")
    func keyframeAnimationCodable() throws {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")

        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])

        let encoder = JSONEncoder()
        let data = try encoder.encode(animation)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeyframeAnimation.self, from: data)

        #expect(decoded.keyframes.count == animation.keyframes.count)
        #expect(decoded.keyframes[0].value == animation.keyframes[0].value)
        #expect(decoded.keyframes[1].value == animation.keyframes[1].value)
    }

    // MARK: - FilterParameter Integration Tests

    @Test("FilterParameter with FadeIn")
    func filterParameterWithFadeIn() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(duration: duration)

        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            value: "1.0",
            fadeIn: fadeIn
        )

        #expect(parameter.fadeIn != nil)
        #expect(parameter.fadeIn?.type == .easeIn)
    }

    @Test("FilterParameter with FadeOut")
    func filterParameterWithFadeOut() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(duration: duration)

        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            value: "1.0",
            fadeOut: fadeOut
        )

        #expect(parameter.fadeOut != nil)
        #expect(parameter.fadeOut?.type == .easeOut)
    }

    @Test("FilterParameter with KeyframeAnimation")
    func filterParameterWithKeyframeAnimation() {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")
        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])

        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            keyframeAnimation: animation
        )

        #expect(parameter.keyframeAnimation != nil)
        #expect(parameter.keyframeAnimation?.keyframes.count == 2)
    }
}
