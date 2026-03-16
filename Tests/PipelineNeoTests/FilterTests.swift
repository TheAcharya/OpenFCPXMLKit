//
//  FilterTests.swift
//  PipelineNeoTests
//  © 2026 • Licensed under MIT License
//

import Foundation
import XCTest
import SwiftTimecode
@testable import PipelineNeo

final class FilterTests: XCTestCase {
    
    // MARK: - FilterParameter Tests
    
    func testFilterParameterInitialization() {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Intensity",
            key: "intensity",
            value: "0.5",
            isEnabled: true
        )
        
        XCTAssertEqual(param.name, "Intensity")
        XCTAssertEqual(param.key, "intensity")
        XCTAssertEqual(param.value, "0.5")
        XCTAssertTrue(param.isEnabled)
    }
    
    func testFilterParameterWithNestedParameters() {
        let nestedParam = FinalCutPro.FCPXML.FilterParameter(name: "Nested", value: "value")
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Parent",
            parameters: [nestedParam]
        )
        
        XCTAssertEqual(param.parameters.count, 1)
        XCTAssertEqual(param.parameters[0].name, "Nested")
    }
    
    func testFilterParameterCodable() throws {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Test",
            key: "test",
            value: "value"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(param)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FilterParameter.self, from: data)
        
        XCTAssertEqual(decoded.name, param.name)
        XCTAssertEqual(decoded.key, param.key)
        XCTAssertEqual(decoded.value, param.value)
    }
    
    func testFilterParameterAuxValueInitialization() {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Gain",
            key: "gain",
            value: "1.0",
            auxValue: "dB",
            isEnabled: true
        )
        XCTAssertEqual(param.name, "Gain")
        XCTAssertEqual(param.auxValue, "dB")
    }
    
    func testFilterParameterAuxValueCodable() throws {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Test",
            key: "k",
            value: "v",
            auxValue: "aux"
        )
        let data = try JSONEncoder().encode(param)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.FilterParameter.self, from: data)
        XCTAssertEqual(decoded.auxValue, "aux")
    }
    
    func testFilterParameterFromParamElementWithAuxValue() {
        let paramElement = FoundationXMLFactory().makeElement(name: "param")
        paramElement.addAttribute(name: "name", value: "Gain")
        paramElement.addAttribute(name: "key", value: "gain")
        paramElement.addAttribute(name: "value", value: "0.8")
        paramElement.addAttribute(name: "auxValue", value: "linear")
        paramElement.addAttribute(name: "enabled", value: "1")
        let param = FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
        XCTAssertNotNil(param)
        XCTAssertEqual(param?.name, "Gain")
        XCTAssertEqual(param?.auxValue, "linear")
    }
    
    // MARK: - KeyedData Tests
    
    func testKeyedDataInitialization() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "effectData", value: "data value")
        
        XCTAssertEqual(data.key, "effectData")
        XCTAssertEqual(data.value, "data value")
    }
    
    func testKeyedDataCodable() throws {
        let data = FinalCutPro.FCPXML.KeyedData(key: "key", value: "value")
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(data)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeyedData.self, from: encoded)
        
        XCTAssertEqual(decoded.key, data.key)
        XCTAssertEqual(decoded.value, data.value)
    }
    
    // MARK: - VideoFilter Tests
    
    func testVideoFilterInitialization() {
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            name: "Color Correction",
            isEnabled: true
        )
        
        XCTAssertEqual(filter.effectID, "r1")
        XCTAssertEqual(filter.name, "Color Correction")
        XCTAssertTrue(filter.isEnabled)
    }
    
    func testVideoFilterWithParameters() {
        let param = FinalCutPro.FCPXML.FilterParameter(name: "Intensity", value: "0.5")
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            parameters: [param]
        )
        
        XCTAssertEqual(filter.parameters.count, 1)
        XCTAssertEqual(filter.parameters[0].name, "Intensity")
    }
    
    func testVideoFilterWithData() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "effectData", value: "data")
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            data: [data]
        )
        
        XCTAssertEqual(filter.data.count, 1)
        XCTAssertEqual(filter.data[0].key, "effectData")
    }
    
    func testVideoFilterCodable() throws {
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            name: "Test Filter",
            parameters: [
                FinalCutPro.FCPXML.FilterParameter(name: "Param1", value: "value1")
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(filter)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.VideoFilter.self, from: data)
        
        XCTAssertEqual(decoded.effectID, filter.effectID)
        XCTAssertEqual(decoded.name, filter.name)
        XCTAssertEqual(decoded.parameters.count, 1)
    }
    
    // MARK: - AudioFilter Tests
    
    func testAudioFilterInitialization() {
        let filter = FinalCutPro.FCPXML.AudioFilter(
            effectID: "r2",
            name: "EQ",
            presetID: "preset1"
        )
        
        XCTAssertEqual(filter.effectID, "r2")
        XCTAssertEqual(filter.name, "EQ")
        XCTAssertEqual(filter.presetID, "preset1")
    }
    
    func testAudioFilterCodable() throws {
        let filter = FinalCutPro.FCPXML.AudioFilter(
            effectID: "r2",
            name: "Audio Filter",
            presetID: "preset1"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(filter)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.AudioFilter.self, from: data)
        
        XCTAssertEqual(decoded.effectID, filter.effectID)
        XCTAssertEqual(decoded.presetID, filter.presetID)
    }
    
    // MARK: - MaskShape Tests
    
    func testMaskShapeInitialization() {
        let shape = FinalCutPro.FCPXML.MaskShape(
            name: "Circle",
            blendMode: .add,
            isEnabled: true
        )
        
        XCTAssertEqual(shape.name, "Circle")
        XCTAssertEqual(shape.blendMode, .add)
        XCTAssertTrue(shape.isEnabled)
    }
    
    func testMaskBlendModes() {
        XCTAssertEqual(FinalCutPro.FCPXML.MaskBlendMode.add.rawValue, "add")
        XCTAssertEqual(FinalCutPro.FCPXML.MaskBlendMode.subtract.rawValue, "subtract")
        XCTAssertEqual(FinalCutPro.FCPXML.MaskBlendMode.multiply.rawValue, "multiply")
    }
    
    // MARK: - MaskIsolation Tests
    
    func testMaskIsolationInitialization() {
        let isolation = FinalCutPro.FCPXML.MaskIsolation(
            name: "Color Isolation",
            blendMode: .multiply
        )
        
        XCTAssertEqual(isolation.name, "Color Isolation")
        XCTAssertEqual(isolation.blendMode, .multiply)
    }
    
    // MARK: - VideoFilterMask Tests
    
    func testVideoFilterMaskInitialization() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            maskShapes: [],
            maskIsolations: []
        )
        
        XCTAssertEqual(mask.videoFilters.count, 1)
        XCTAssertEqual(mask.videoFilters[0].effectID, "r1")
    }
    
    func testVideoFilterMaskWithSecondaryFilter() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let secondaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r2")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            secondaryVideoFilter: secondaryFilter
        )
        
        XCTAssertEqual(mask.videoFilters.count, 2)
    }
    
    func testVideoFilterMaskInverted() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            isInverted: true
        )
        
        XCTAssertTrue(mask.isInverted)
    }
    
    // MARK: - Clip Integration Tests
    
    func testClipVideoFilters() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-video ref="r1" name="Color Correction" enabled="1">
                <param name="Intensity" value="0.5"/>
            </filter-video>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let clipElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipElement) else {
            XCTFail("Failed to create Clip")
            return
        }
        
        let filters = clip.videoFilters
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters[0].effectID, "r1")
        XCTAssertEqual(filters[0].name, "Color Correction")
        XCTAssertEqual(filters[0].parameters.count, 1)
    }
    
    func testClipVideoFiltersRoundTrip() {
        let clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
        
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            name: "Test Filter",
            parameters: [
                FinalCutPro.FCPXML.FilterParameter(name: "Intensity", value: "0.5")
            ]
        )
        
        clip.videoFilters = [filter]
        
        XCTAssertEqual(clip.videoFilters.count, 1)
        XCTAssertEqual(clip.videoFilters[0].effectID, "r1")
        
        // Verify XML structure
        let filterElements = clip.element.childElements.filter { $0.name == "filter-video" }
        XCTAssertEqual(filterElements.count, 1)
    }
    
    func testClipAudioFilters() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-audio ref="r2" name="EQ" presetID="preset1"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let clipElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipElement) else {
            XCTFail("Failed to create Clip")
            return
        }
        
        let filters = clip.audioFilters
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters[0].effectID, "r2")
        XCTAssertEqual(filters[0].presetID, "preset1")
    }
    
    func testClipVideoFilterMasks() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-video-mask enabled="1" inverted="0">
                <filter-video ref="r1"/>
                <mask-shape name="Circle" blendMode="add"/>
            </filter-video-mask>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let clipElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipElement) else {
            XCTFail("Failed to create Clip")
            return
        }
        
        let masks = clip.videoFilterMasks
        XCTAssertEqual(masks.count, 1)
        XCTAssertEqual(masks[0].videoFilters.count, 1)
        XCTAssertEqual(masks[0].maskShapes.count, 1)
        XCTAssertEqual(masks[0].maskShapes[0].name, "Circle")
    }
    
    // MARK: - Transition Integration Tests
    
    func testTransitionVideoFilters() throws {
        let xmlString = """
        <transition duration="1s" name="Cross Dissolve">
            <filter-video ref="r1" name="Transition Effect"/>
        </transition>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let rootElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let transition = FinalCutPro.FCPXML.Transition(element: rootElement) else {
            XCTFail("Failed to create Transition")
            return
        }
        
        let filters = transition.videoFilters
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters[0].effectID, "r1")
        XCTAssertEqual(filters[0].name, "Transition Effect")
    }
    
    func testTransitionAudioFilters() throws {
        let xmlString = """
        <transition duration="1s">
            <filter-audio ref="r2" name="Audio Transition"/>
        </transition>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        guard let rootElement = xmlDoc.rootElement() else {
            XCTFail("Failed to parse XML")
            return
        }
        
        guard let transition = FinalCutPro.FCPXML.Transition(element: rootElement) else {
            XCTFail("Failed to create Transition")
            return
        }
        
        let filters = transition.audioFilters
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters[0].effectID, "r2")
    }
    
    func testTransitionFiltersRoundTrip() {
        let transition = FinalCutPro.FCPXML.Transition(duration: Fraction(1, 1))
        
        let videoFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1", name: "Video Effect")
        let audioFilter = FinalCutPro.FCPXML.AudioFilter(effectID: "r2", name: "Audio Effect")
        
        transition.videoFilters = [videoFilter]
        transition.audioFilters = [audioFilter]
        
        XCTAssertEqual(transition.videoFilters.count, 1)
        XCTAssertEqual(transition.audioFilters.count, 1)
        
        // Verify XML structure
        let videoFilterElements = transition.element.childElements.filter { $0.name == "filter-video" }
        let audioFilterElements = transition.element.childElements.filter { $0.name == "filter-audio" }
        XCTAssertEqual(videoFilterElements.count, 1)
        XCTAssertEqual(audioFilterElements.count, 1)
    }
    
    // MARK: - Effect Resource Tests
    
    func testEffectResourceInitialization() {
        let effect = FinalCutPro.FCPXML.Effect(
            id: "r1",
            name: "Color Correction",
            uid: "com.apple.color",
            src: "file:///path/to/effect.motiontemplate"
        )
        
        XCTAssertEqual(effect.id, "r1")
        XCTAssertEqual(effect.name, "Color Correction")
        XCTAssertEqual(effect.uid, "com.apple.color")
        XCTAssertEqual(effect.src, "file:///path/to/effect.motiontemplate")
    }
    
    func testEffectResourceCodable() throws {
        let effect = FinalCutPro.FCPXML.Effect(
            id: "r1",
            name: "Test Effect",
            uid: "com.test.effect"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(effect)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Effect.self, from: data)
        
        XCTAssertEqual(decoded.id, effect.id)
        XCTAssertEqual(decoded.name, effect.name)
        XCTAssertEqual(decoded.uid, effect.uid)
    }
    
    func testEffectEquatable() {
        let effect1 = FinalCutPro.FCPXML.Effect(id: "r1", name: "Effect", uid: "uid1")
        let effect2 = FinalCutPro.FCPXML.Effect(id: "r1", name: "Effect", uid: "uid1")
        let effect3 = FinalCutPro.FCPXML.Effect(id: "r2", name: "Effect", uid: "uid1")
        
        XCTAssertEqual(effect1, effect2)
        XCTAssertNotEqual(effect1, effect3)
    }
}
