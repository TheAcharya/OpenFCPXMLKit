//
//  FCPXMLKeyframeAnimationTests.swift
//  OpenFCPXMLKitTests
//  © 2026 • Licensed under MIT License
//

import XCTest
import CoreMedia
@testable import OpenFCPXMLKit

final class FCPXMLKeyframeAnimationTests: XCTestCase {
    
    // MARK: - FadeType Tests
    
    func testFadeTypeCases() {
        XCTAssertEqual(FinalCutPro.FCPXML.FadeType.linear.rawValue, "linear")
        XCTAssertEqual(FinalCutPro.FCPXML.FadeType.easeIn.rawValue, "easeIn")
        XCTAssertEqual(FinalCutPro.FCPXML.FadeType.easeOut.rawValue, "easeOut")
        XCTAssertEqual(FinalCutPro.FCPXML.FadeType.easeInOut.rawValue, "easeInOut")
    }
    
    // MARK: - FadeIn Tests
    
    func testFadeInInitialization() {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(type: .easeIn, duration: duration)
        
        XCTAssertEqual(fadeIn.type, .easeIn)
        XCTAssertEqual(fadeIn.duration, duration)
    }
    
    func testFadeInDefaultType() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(duration: duration)
        
        XCTAssertEqual(fadeIn.type, .easeIn)
    }
    
    func testFadeInCodable() throws {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(type: .linear, duration: duration)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(fadeIn)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FadeIn.self, from: data)
        
        XCTAssertEqual(decoded.type, fadeIn.type)
        XCTAssertEqual(decoded.duration.value, fadeIn.duration.value)
        XCTAssertEqual(decoded.duration.timescale, fadeIn.duration.timescale)
    }
    
    // MARK: - FadeOut Tests
    
    func testFadeOutInitialization() {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(type: .easeOut, duration: duration)
        
        XCTAssertEqual(fadeOut.type, .easeOut)
        XCTAssertEqual(fadeOut.duration, duration)
    }
    
    func testFadeOutDefaultType() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(duration: duration)
        
        XCTAssertEqual(fadeOut.type, .easeOut)
    }
    
    func testFadeOutCodable() throws {
        let duration = CMTime(seconds: 2.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(type: .easeInOut, duration: duration)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(fadeOut)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FadeOut.self, from: data)
        
        XCTAssertEqual(decoded.type, fadeOut.type)
        XCTAssertEqual(decoded.duration.value, fadeOut.duration.value)
        XCTAssertEqual(decoded.duration.timescale, fadeOut.duration.timescale)
    }
    
    // MARK: - Keyframe Tests
    
    func testKeyframeInitialization() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(
            time: time,
            value: "0.5",
            interpolation: .linear,
            curve: .smooth
        )
        
        XCTAssertEqual(keyframe.time, time)
        XCTAssertEqual(keyframe.value, "0.5")
        XCTAssertEqual(keyframe.interpolation, .linear)
        XCTAssertEqual(keyframe.curve, .smooth)
    }
    
    func testKeyframeDefaultValues() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(time: time, value: "1.0")
        
        XCTAssertEqual(keyframe.interpolation, .linear)
        XCTAssertEqual(keyframe.curve, .smooth)
    }
    
    func testKeyframeWithAuxValue() {
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe = FinalCutPro.FCPXML.Keyframe(
            time: time,
            value: "0.5",
            auxValue: "0.3"
        )
        
        XCTAssertEqual(keyframe.auxValue, "0.3")
    }
    
    func testKeyframeInterpolationCases() {
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeInterpolation.linear.rawValue, "linear")
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeInterpolation.ease.rawValue, "ease")
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeInterpolation.easeIn.rawValue, "easeIn")
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeInterpolation.easeOut.rawValue, "easeOut")
    }
    
    func testKeyframeCurveCases() {
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeCurve.linear.rawValue, "linear")
        XCTAssertEqual(FinalCutPro.FCPXML.KeyframeCurve.smooth.rawValue, "smooth")
    }
    
    func testKeyframeCodable() throws {
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
        
        XCTAssertEqual(decoded.value, keyframe.value)
        XCTAssertEqual(decoded.auxValue, keyframe.auxValue)
        XCTAssertEqual(decoded.interpolation, keyframe.interpolation)
        XCTAssertEqual(decoded.curve, keyframe.curve)
    }
    
    // MARK: - KeyframeAnimation Tests
    
    func testKeyframeAnimationInitialization() {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")
        
        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])
        
        XCTAssertEqual(animation.keyframes.count, 2)
        XCTAssertEqual(animation.keyframes[0].value, "0.0")
        XCTAssertEqual(animation.keyframes[1].value, "1.0")
    }
    
    func testKeyframeAnimationEmpty() {
        let animation = FinalCutPro.FCPXML.KeyframeAnimation()
        
        XCTAssertEqual(animation.keyframes.count, 0)
    }
    
    func testKeyframeAnimationCodable() throws {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")
        
        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(animation)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeyframeAnimation.self, from: data)
        
        XCTAssertEqual(decoded.keyframes.count, animation.keyframes.count)
        XCTAssertEqual(decoded.keyframes[0].value, animation.keyframes[0].value)
        XCTAssertEqual(decoded.keyframes[1].value, animation.keyframes[1].value)
    }
    
    // MARK: - FilterParameter Integration Tests
    
    func testFilterParameterWithFadeIn() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeIn = FinalCutPro.FCPXML.FadeIn(duration: duration)
        
        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            value: "1.0",
            fadeIn: fadeIn
        )
        
        XCTAssertNotNil(parameter.fadeIn)
        XCTAssertEqual(parameter.fadeIn?.type, .easeIn)
    }
    
    func testFilterParameterWithFadeOut() {
        let duration = CMTime(seconds: 1.0, preferredTimescale: 600)
        let fadeOut = FinalCutPro.FCPXML.FadeOut(duration: duration)
        
        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            value: "1.0",
            fadeOut: fadeOut
        )
        
        XCTAssertNotNil(parameter.fadeOut)
        XCTAssertEqual(parameter.fadeOut?.type, .easeOut)
    }
    
    func testFilterParameterWithKeyframeAnimation() {
        let time1 = CMTime(seconds: 0.0, preferredTimescale: 600)
        let time2 = CMTime(seconds: 1.0, preferredTimescale: 600)
        let keyframe1 = FinalCutPro.FCPXML.Keyframe(time: time1, value: "0.0")
        let keyframe2 = FinalCutPro.FCPXML.Keyframe(time: time2, value: "1.0")
        let animation = FinalCutPro.FCPXML.KeyframeAnimation(keyframes: [keyframe1, keyframe2])
        
        let parameter = FinalCutPro.FCPXML.FilterParameter(
            name: "Opacity",
            keyframeAnimation: animation
        )
        
        XCTAssertNotNil(parameter.keyframeAnimation)
        XCTAssertEqual(parameter.keyframeAnimation?.keyframes.count, 2)
    }
}
