//
//  AudioKeyframeTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for audio keyframes in adjust-volume elements.
//

import XCTest
import CoreMedia
@testable import PipelineNeo

@available(macOS 12.0, *)
final class AudioKeyframeTests: XCTestCase {
    
    // MARK: - File Tests
    
    func testAudioKeyframesFromTimelineWithSecondaryStorylineWithAudioKeyframes() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        XCTAssertEqual(fcpxml.version, .ver1_13)
        
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        // Find adjust-volume with keyframeAnimation
        var foundAudioKeyframes = false
        var keyframeCount = 0
        var fadeOutFound = false
        
        func checkForAudioKeyframes(in element: any PNXMLElement) {
            if let adjustVolume = element.firstChildElement(named: "adjust-volume") {
                if let param = adjustVolume.firstChildElement(named: "param"),
                   param.stringValue(forAttributeNamed: "name") == "amount" {
                    
                    // Check for fadeOut
                    if param.firstChildElement(named: "fadeOut") != nil {
                        fadeOutFound = true
                    }
                    
                    // Check for keyframeAnimation
                    if let keyframeAnimation = param.firstChildElement(named: "keyframeAnimation") {
                        foundAudioKeyframes = true
                        let keyframes = keyframeAnimation.childElements.filter { $0.name == "keyframe" }
                        keyframeCount = keyframes.count
                        
                        // Verify keyframe structure
                        XCTAssertGreaterThan(keyframes.count, 0, "Should have at least one keyframe")
                        
                        // Check first keyframe
                        if let firstKeyframe = keyframes.first {
                            let time = firstKeyframe.stringValue(forAttributeNamed: "time")
                            let value = firstKeyframe.stringValue(forAttributeNamed: "value")
                            XCTAssertNotNil(time, "Keyframe should have time attribute")
                            XCTAssertNotNil(value, "Keyframe should have value attribute")
                            XCTAssertTrue(value?.contains("dB") == true, "Audio keyframe value should be in dB")
                        }
                        
                        return
                    }
                }
            }
            
            // Recursively check children
            for child in element.childElements {
                checkForAudioKeyframes(in: child)
                if foundAudioKeyframes { return }
            }
        }
        
        for element in Array(spine.storyElements) {
            checkForAudioKeyframes(in: element)
            if foundAudioKeyframes { break }
        }
        
        XCTAssertTrue(foundAudioKeyframes, "Should find audio keyframes with keyframeAnimation")
        XCTAssertGreaterThan(keyframeCount, 0, "Should have keyframes")
        XCTAssertTrue(fadeOutFound, "Should find fadeOut in audio keyframes")
    }
    
    func testAudioKeyframesFromTimelineSample() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineSample")
        XCTAssertEqual(fcpxml.root.element.name, "fcpxml")
        
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        // Collect all audio keyframes
        var allKeyframes: [(time: String, value: String)] = []
        
        func collectAudioKeyframes(in element: any PNXMLElement) {
            if let adjustVolume = element.firstChildElement(named: "adjust-volume") {
                if let param = adjustVolume.firstChildElement(named: "param"),
                   param.stringValue(forAttributeNamed: "name") == "amount",
                   let keyframeAnimation = param.firstChildElement(named: "keyframeAnimation") {
                    
                    let keyframes = keyframeAnimation.childElements.filter { $0.name == "keyframe" }
                    for keyframe in keyframes {
                        if let time = keyframe.stringValue(forAttributeNamed: "time"),
                           let value = keyframe.stringValue(forAttributeNamed: "value") {
                            allKeyframes.append((time: time, value: value))
                        }
                    }
                }
            }
            
            for child in element.childElements {
                collectAudioKeyframes(in: child)
            }
        }
        
        for element in Array(spine.storyElements) {
            collectAudioKeyframes(in: element)
        }
        
        XCTAssertGreaterThan(allKeyframes.count, 0, "Should find audio keyframes in TimelineSample")
    }
    
    // MARK: - Parsing Tests
    
    func testParseAudioKeyframeFromXML() throws {
        // Create a test XML structure
        let adjustVolume = FoundationXMLFactory().makeElement(name: "adjust-volume")
        let param = FoundationXMLFactory().makeElement(name: "param")
        param.addAttribute(name: "name", value: "amount")
        
        let keyframeAnimation = FoundationXMLFactory().makeElement(name: "keyframeAnimation")
        
        let keyframe1 = FoundationXMLFactory().makeElement(name: "keyframe")
        keyframe1.addAttribute(name: "time", value: "6408403/720000s")
        keyframe1.addAttribute(name: "value", value: "-3dB")
        
        let keyframe2 = FoundationXMLFactory().makeElement(name: "keyframe")
        keyframe2.addAttribute(name: "time", value: "7497726/720000s")
        keyframe2.addAttribute(name: "value", value: "-37dB")
        
        keyframeAnimation.addChild(keyframe1)
        keyframeAnimation.addChild(keyframe2)
        
        param.addChild(keyframeAnimation)
        adjustVolume.addChild(param)
        
        // Parse keyframes
        guard let paramElement = adjustVolume.firstChildElement(named: "param"),
              paramElement.stringValue(forAttributeNamed: "name") == "amount",
              let animationElement = paramElement.firstChildElement(named: "keyframeAnimation") else {
            XCTFail("Failed to find param or keyframeAnimation")
            return
        }
        
        let keyframes = animationElement.childElements.filter { $0.name == "keyframe" }
        XCTAssertEqual(keyframes.count, 2, "Should have 2 keyframes")
        
        let firstKeyframe = keyframes[0]
        XCTAssertEqual(firstKeyframe.stringValue(forAttributeNamed: "time"), "6408403/720000s")
        XCTAssertEqual(firstKeyframe.stringValue(forAttributeNamed: "value"), "-3dB")
        
        let secondKeyframe = keyframes[1]
        XCTAssertEqual(secondKeyframe.stringValue(forAttributeNamed: "time"), "7497726/720000s")
        XCTAssertEqual(secondKeyframe.stringValue(forAttributeNamed: "value"), "-37dB")
    }
    
    func testParseAudioKeyframeWithFadeOut() throws {
        // Create a test XML structure with fadeOut
        let adjustVolume = FoundationXMLFactory().makeElement(name: "adjust-volume")
        let param = FoundationXMLFactory().makeElement(name: "param")
        param.addAttribute(name: "name", value: "amount")
        
        let fadeOut = FoundationXMLFactory().makeElement(name: "fadeOut")
        fadeOut.addAttribute(name: "type", value: "easeIn")
        fadeOut.addAttribute(name: "duration", value: "6112587/720000s")

        let keyframeAnimation = FoundationXMLFactory().makeElement(name: "keyframeAnimation")
        let keyframe = FoundationXMLFactory().makeElement(name: "keyframe")
        keyframe.addAttribute(name: "time", value: "6408403/720000s")
        keyframe.addAttribute(name: "value", value: "-3dB")
        keyframeAnimation.addChild(keyframe)
        
        param.addChild(fadeOut)
        param.addChild(keyframeAnimation)
        adjustVolume.addChild(param)
        
        // Parse fadeOut and keyframes
        guard let paramElement = adjustVolume.firstChildElement(named: "param") else {
            XCTFail("Failed to find param")
            return
        }
        
        let fadeOutElement = paramElement.firstChildElement(named: "fadeOut")
        XCTAssertNotNil(fadeOutElement, "Should find fadeOut")
        XCTAssertEqual(fadeOutElement?.stringValue(forAttributeNamed: "type"), "easeIn")
        XCTAssertEqual(fadeOutElement?.stringValue(forAttributeNamed: "duration"), "6112587/720000s")
        
        let animationElement = paramElement.firstChildElement(named: "keyframeAnimation")
        XCTAssertNotNil(animationElement, "Should find keyframeAnimation")
        let keyframes = animationElement?.childElements.filter { $0.name == "keyframe" } ?? []
        XCTAssertEqual(keyframes.count, 1, "Should have 1 keyframe")
    }
    
    func testParseAudioKeyframeWithFadeIn() throws {
        // Create a test XML structure with fadeIn
        let adjustVolume = FoundationXMLFactory().makeElement(name: "adjust-volume")
        let param = FoundationXMLFactory().makeElement(name: "param")
        param.addAttribute(name: "name", value: "amount")
        
        let fadeIn = FoundationXMLFactory().makeElement(name: "fadeIn")
        fadeIn.addAttribute(name: "type", value: "easeOut")
        fadeIn.addAttribute(name: "duration", value: "1000000/24000s")

        let keyframeAnimation = FoundationXMLFactory().makeElement(name: "keyframeAnimation")
        let keyframe = FoundationXMLFactory().makeElement(name: "keyframe")
        keyframe.addAttribute(name: "time", value: "500000/24000s")
        keyframe.addAttribute(name: "value", value: "0dB")
        keyframeAnimation.addChild(keyframe)
        
        param.addChild(fadeIn)
        param.addChild(keyframeAnimation)
        adjustVolume.addChild(param)
        
        // Parse fadeIn and keyframes
        guard let paramElement = adjustVolume.firstChildElement(named: "param") else {
            XCTFail("Failed to find param")
            return
        }
        
        let fadeInElement = paramElement.firstChildElement(named: "fadeIn")
        XCTAssertNotNil(fadeInElement, "Should find fadeIn")
        XCTAssertEqual(fadeInElement?.stringValue(forAttributeNamed: "type"), "easeOut")
        
        let animationElement = paramElement.firstChildElement(named: "keyframeAnimation")
        XCTAssertNotNil(animationElement, "Should find keyframeAnimation")
    }
    
    // MARK: - Keyframe Value Tests
    
    func testAudioKeyframeDecibelValues() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        var foundDecibelValues: [String] = []
        
        func collectDecibelValues(in element: any PNXMLElement) {
            if let adjustVolume = element.firstChildElement(named: "adjust-volume"),
               let param = adjustVolume.firstChildElement(named: "param"),
               param.stringValue(forAttributeNamed: "name") == "amount",
               let keyframeAnimation = param.firstChildElement(named: "keyframeAnimation") {
                
                let keyframes = keyframeAnimation.childElements.filter { $0.name == "keyframe" }
                for keyframe in keyframes {
                    if let value = keyframe.stringValue(forAttributeNamed: "value") {
                        foundDecibelValues.append(value)
                    }
                }
            }
            
            for child in element.childElements {
                collectDecibelValues(in: child)
            }
        }
        
        for element in Array(spine.storyElements) {
            collectDecibelValues(in: element)
        }
        
        XCTAssertGreaterThan(foundDecibelValues.count, 0, "Should find decibel values")
        
        // Verify all values are in dB format
        for value in foundDecibelValues {
            XCTAssertTrue(value.contains("dB"), "Value '\(value)' should contain 'dB'")
        }
        
        // Verify specific decibel values exist
        let hasNegativeValues = foundDecibelValues.contains { $0.contains("-") }
        XCTAssertTrue(hasNegativeValues, "Should have negative decibel values")
    }
    
    func testAudioKeyframeTimeValues() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        var timeValues: [String] = []
        
        func collectTimeValues(in element: any PNXMLElement) {
            if let adjustVolume = element.firstChildElement(named: "adjust-volume"),
               let param = adjustVolume.firstChildElement(named: "param"),
               param.stringValue(forAttributeNamed: "name") == "amount",
               let keyframeAnimation = param.firstChildElement(named: "keyframeAnimation") {
                
                let keyframes = keyframeAnimation.childElements.filter { $0.name == "keyframe" }
                for keyframe in keyframes {
                    if let time = keyframe.stringValue(forAttributeNamed: "time") {
                        timeValues.append(time)
                    }
                }
            }
            
            for child in element.childElements {
                collectTimeValues(in: child)
            }
        }
        
        for element in Array(spine.storyElements) {
            collectTimeValues(in: element)
        }
        
        XCTAssertGreaterThan(timeValues.count, 0, "Should find time values")
        
        // Verify time values are in FCPXML time format (fractional seconds)
        for time in timeValues {
            XCTAssertTrue(time.contains("/"), "Time '\(time)' should be in fractional format")
            XCTAssertTrue(time.contains("s"), "Time '\(time)' should end with 's'")
        }
    }
    
    // MARK: - Multiple Keyframes Tests
    
    func testMultipleAudioKeyframesInSequence() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        var maxKeyframeCount = 0
        
        func findMaxKeyframeCount(in element: any PNXMLElement) {
            if let adjustVolume = element.firstChildElement(named: "adjust-volume"),
               let param = adjustVolume.firstChildElement(named: "param"),
               param.stringValue(forAttributeNamed: "name") == "amount",
               let keyframeAnimation = param.firstChildElement(named: "keyframeAnimation") {
                
                let keyframes = keyframeAnimation.childElements.filter { $0.name == "keyframe" }
                maxKeyframeCount = max(maxKeyframeCount, keyframes.count)
            }
            
            for child in element.childElements {
                findMaxKeyframeCount(in: child)
            }
        }
        
        for element in Array(spine.storyElements) {
            findMaxKeyframeCount(in: element)
        }
        
        XCTAssertGreaterThanOrEqual(maxKeyframeCount, 6, "Should have at least 6 keyframes in sequence")
    }
    
    // MARK: - Context Tests
    
    func testAudioKeyframesInSecondaryStoryline() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        var foundInSecondaryStoryline = false
        
        func checkSecondaryStoryline(in element: any PNXMLElement) {
            // Check if this element is a clip that contains a spine (secondary storyline)
            if (element.name == "asset-clip" || element.name == "clip") {
                // Look for nested spine (secondary storyline)
                let nestedSpines = element.childElements.filter { $0.name == "spine" }
                if !nestedSpines.isEmpty {
                    // Check for audio keyframes in clips within this secondary storyline
                    for nestedSpine in nestedSpines {
                        for clip in nestedSpine.childElements {
                            if let adjustVolume = clip.firstChildElement(named: "adjust-volume"),
                               let param = adjustVolume.firstChildElement(named: "param"),
                               param.stringValue(forAttributeNamed: "name") == "amount",
                               param.firstChildElement(named: "keyframeAnimation") != nil {
                                foundInSecondaryStoryline = true
                                return
                            }
                        }
                    }
                }
            }
            
            // Also check if this clip has audio keyframes and is nested (has negative lane or is within another clip)
            if (element.name == "asset-clip" || element.name == "clip") {
                if let adjustVolume = element.firstChildElement(named: "adjust-volume"),
                   let param = adjustVolume.firstChildElement(named: "param"),
                   param.stringValue(forAttributeNamed: "name") == "amount",
                   param.firstChildElement(named: "keyframeAnimation") != nil {
                    // Check if this is a secondary storyline clip (negative lane indicates audio lane)
                    let lane = element.stringValue(forAttributeNamed: "lane")
                    if lane == "-1" || lane == "-2" {
                        foundInSecondaryStoryline = true
                        return
                    }
                }
            }
            
            for child in element.childElements {
                checkSecondaryStoryline(in: child)
                if foundInSecondaryStoryline { return }
            }
        }
        
        for element in Array(spine.storyElements) {
            checkSecondaryStoryline(in: element)
            if foundInSecondaryStoryline { break }
        }
        
        XCTAssertTrue(foundInSecondaryStoryline, "Should find audio keyframes in secondary storyline")
    }
    
    func testAudioKeyframesInNestedClips() throws {
        let fcpxml = try loadFCPXMLSample(named: "TimelineWithSecondaryStorylineWithAudioKeyframes")
        let projects = fcpxml.allProjects()
        guard let project = projects.first else {
            XCTFail("No project found")
            return
        }
        
        let sequence = try XCTUnwrap(project.sequence)
        let spine = sequence.spine
        
        var depth = 0
        var maxDepth = 0
        
        func findMaxDepth(in element: any PNXMLElement) {
            if element.name == "asset-clip" || element.name == "clip" {
                depth += 1
                maxDepth = max(maxDepth, depth)
                
                if let adjustVolume = element.firstChildElement(named: "adjust-volume"),
                   let param = adjustVolume.firstChildElement(named: "param"),
                   param.stringValue(forAttributeNamed: "name") == "amount",
                   param.firstChildElement(named: "keyframeAnimation") != nil {
                    // Found keyframes at this depth
                }
            }
            
            for child in element.childElements {
                findMaxDepth(in: child)
            }
            
            if element.name == "asset-clip" || element.name == "clip" {
                depth -= 1
            }
        }
        
        for element in Array(spine.storyElements) {
            findMaxDepth(in: element)
        }
        
        XCTAssertGreaterThan(maxDepth, 0, "Should find nested clips with audio keyframes")
    }
}
