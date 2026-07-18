//
//  FCPXMLFilterTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for video/audio filter models and clip/transition integration.
//

import Foundation
import Testing
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("Filter models")
struct FCPXMLFilterTests {
    
    // MARK: - FilterParameter Tests
    
    @Test("Filter parameter initialization")
    func filterParameterInitialization() {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Intensity",
            key: "intensity",
            value: "0.5",
            isEnabled: true
        )
        
        #expect(param.name == "Intensity")
        #expect(param.key == "intensity")
        #expect(param.value == "0.5")
        #expect(param.isEnabled)
    }
    
    @Test("Filter parameter with nested parameters")
    func filterParameterWithNestedParameters() {
        let nestedParam = FinalCutPro.FCPXML.FilterParameter(name: "Nested", value: "value")
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Parent",
            parameters: [nestedParam]
        )
        
        #expect(param.parameters.count == 1)
        #expect(param.parameters[0].name == "Nested")
    }
    
    @Test("Filter parameter Codable")
    func filterParameterCodable() throws {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Test",
            key: "test",
            value: "value"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(param)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.FilterParameter.self, from: data)
        
        #expect(decoded.name == param.name)
        #expect(decoded.key == param.key)
        #expect(decoded.value == param.value)
    }
    
    @Test("Filter parameter auxValue initialization")
    func filterParameterAuxValueInitialization() {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Gain",
            key: "gain",
            value: "1.0",
            auxValue: "dB",
            isEnabled: true
        )
        #expect(param.name == "Gain")
        #expect(param.auxValue == "dB")
    }
    
    @Test("Filter parameter auxValue Codable")
    func filterParameterAuxValueCodable() throws {
        let param = FinalCutPro.FCPXML.FilterParameter(
            name: "Test",
            key: "k",
            value: "v",
            auxValue: "aux"
        )
        let data = try JSONEncoder().encode(param)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.FilterParameter.self, from: data)
        #expect(decoded.auxValue == "aux")
    }
    
    @Test("Filter parameter from param element with auxValue")
    func filterParameterFromParamElementWithAuxValue() {
        let paramElement = FoundationXMLFactory().makeElement(name: "param")
        paramElement.addAttribute(name: "name", value: "Gain")
        paramElement.addAttribute(name: "key", value: "gain")
        paramElement.addAttribute(name: "value", value: "0.8")
        paramElement.addAttribute(name: "auxValue", value: "linear")
        paramElement.addAttribute(name: "enabled", value: "1")
        let param = FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
        #expect(param != nil)
        #expect(param?.name == "Gain")
        #expect(param?.auxValue == "linear")
    }
    
    // MARK: - KeyedData Tests
    
    @Test("Keyed data initialization")
    func keyedDataInitialization() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "effectData", value: "data value")
        
        #expect(data.key == "effectData")
        #expect(data.value == "data value")
    }
    
    @Test("Keyed data Codable")
    func keyedDataCodable() throws {
        let data = FinalCutPro.FCPXML.KeyedData(key: "key", value: "value")
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(data)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeyedData.self, from: encoded)
        
        #expect(decoded.key == data.key)
        #expect(decoded.value == data.value)
    }
    
    // MARK: - VideoFilter Tests
    
    @Test("Video filter initialization")
    func videoFilterInitialization() {
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            name: "Color Correction",
            isEnabled: true
        )
        
        #expect(filter.effectID == "r1")
        #expect(filter.name == "Color Correction")
        #expect(filter.isEnabled)
    }
    
    @Test("Video filter with parameters")
    func videoFilterWithParameters() {
        let param = FinalCutPro.FCPXML.FilterParameter(name: "Intensity", value: "0.5")
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            parameters: [param]
        )
        
        #expect(filter.parameters.count == 1)
        #expect(filter.parameters[0].name == "Intensity")
    }
    
    @Test("Video filter with data")
    func videoFilterWithData() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "effectData", value: "data")
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            data: [data]
        )
        
        #expect(filter.data.count == 1)
        #expect(filter.data[0].key == "effectData")
    }
    
    @Test("Video filter Codable")
    func videoFilterCodable() throws {
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
        
        #expect(decoded.effectID == filter.effectID)
        #expect(decoded.name == filter.name)
        #expect(decoded.parameters.count == 1)
    }
    
    // MARK: - AudioFilter Tests
    
    @Test("Audio filter initialization")
    func audioFilterInitialization() {
        let filter = FinalCutPro.FCPXML.AudioFilter(
            effectID: "r2",
            name: "EQ",
            presetID: "preset1"
        )
        
        #expect(filter.effectID == "r2")
        #expect(filter.name == "EQ")
        #expect(filter.presetID == "preset1")
    }
    
    @Test("Audio filter Codable")
    func audioFilterCodable() throws {
        let filter = FinalCutPro.FCPXML.AudioFilter(
            effectID: "r2",
            name: "Audio Filter",
            presetID: "preset1"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(filter)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.AudioFilter.self, from: data)
        
        #expect(decoded.effectID == filter.effectID)
        #expect(decoded.presetID == filter.presetID)
    }
    
    // MARK: - MaskShape Tests
    
    @Test("Mask shape initialization")
    func maskShapeInitialization() {
        let shape = FinalCutPro.FCPXML.MaskShape(
            name: "Circle",
            blendMode: .add,
            isEnabled: true
        )
        
        #expect(shape.name == "Circle")
        #expect(shape.blendMode == .add)
        #expect(shape.isEnabled)
    }
    
    @Test("Mask blend modes")
    func maskBlendModes() {
        #expect(FinalCutPro.FCPXML.MaskBlendMode.add.rawValue == "add")
        #expect(FinalCutPro.FCPXML.MaskBlendMode.subtract.rawValue == "subtract")
        #expect(FinalCutPro.FCPXML.MaskBlendMode.multiply.rawValue == "multiply")
    }
    
    // MARK: - MaskIsolation Tests
    
    @Test("Mask isolation initialization")
    func maskIsolationInitialization() {
        let isolation = FinalCutPro.FCPXML.MaskIsolation(
            name: "Color Isolation",
            blendMode: .multiply
        )
        
        #expect(isolation.name == "Color Isolation")
        #expect(isolation.blendMode == .multiply)
    }
    
    // MARK: - VideoFilterMask Tests
    
    @Test("Video filter mask initialization")
    func videoFilterMaskInitialization() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            maskShapes: [],
            maskIsolations: []
        )
        
        #expect(mask.videoFilters.count == 1)
        #expect(mask.videoFilters[0].effectID == "r1")
    }
    
    @Test("Video filter mask with secondary filter")
    func videoFilterMaskWithSecondaryFilter() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let secondaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r2")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            secondaryVideoFilter: secondaryFilter
        )
        
        #expect(mask.videoFilters.count == 2)
    }
    
    @Test("Video filter mask inverted")
    func videoFilterMaskInverted() {
        let primaryFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let mask = FinalCutPro.FCPXML.VideoFilterMask(
            primaryVideoFilter: primaryFilter,
            isInverted: true
        )
        
        #expect(mask.isInverted)
    }
    
    // MARK: - Clip Integration Tests
    
    @Test("Clip video filters")
    func clipVideoFilters() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-video ref="r1" name="Color Correction" enabled="1">
                <param name="Intensity" value="0.5"/>
            </filter-video>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let filters = clip.videoFilters
        #expect(filters.count == 1)
        #expect(filters[0].effectID == "r1")
        #expect(filters[0].name == "Color Correction")
        #expect(filters[0].parameters.count == 1)
    }
    
    @Test("Clip video filters round-trip")
    func clipVideoFiltersRoundTrip() {
        let clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
        
        let filter = FinalCutPro.FCPXML.VideoFilter(
            effectID: "r1",
            name: "Test Filter",
            parameters: [
                FinalCutPro.FCPXML.FilterParameter(name: "Intensity", value: "0.5")
            ]
        )
        
        clip.videoFilters = [filter]
        
        #expect(clip.videoFilters.count == 1)
        #expect(clip.videoFilters[0].effectID == "r1")
        
        // Verify XML structure
        let filterElements = clip.element.childElements.filter { $0.name == "filter-video" }
        #expect(filterElements.count == 1)
    }
    
    @Test("Clip audio filters")
    func clipAudioFilters() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-audio ref="r2" name="EQ" presetID="preset1"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let filters = clip.audioFilters
        #expect(filters.count == 1)
        #expect(filters[0].effectID == "r2")
        #expect(filters[0].presetID == "preset1")
    }
    
    @Test("Clip video filter masks")
    func clipVideoFilterMasks() throws {
        let xmlString = """
        <clip duration="5s">
            <filter-video-mask enabled="1" inverted="0">
                <filter-video ref="r1"/>
                <mask-shape name="Circle" blendMode="add"/>
            </filter-video-mask>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let masks = clip.videoFilterMasks
        #expect(masks.count == 1)
        #expect(masks[0].videoFilters.count == 1)
        #expect(masks[0].maskShapes.count == 1)
        #expect(masks[0].maskShapes[0].name == "Circle")
    }
    
    // MARK: - Transition Integration Tests
    
    @Test("Transition video filters")
    func transitionVideoFilters() throws {
        let xmlString = """
        <transition duration="1s" name="Cross Dissolve">
            <filter-video ref="r1" name="Transition Effect"/>
        </transition>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let rootElement = try #require(xmlDoc.rootElement())
        let transition = try #require(FinalCutPro.FCPXML.Transition(element: rootElement))
        
        let filters = transition.videoFilters
        #expect(filters.count == 1)
        #expect(filters[0].effectID == "r1")
        #expect(filters[0].name == "Transition Effect")
    }
    
    @Test("Transition audio filters")
    func transitionAudioFilters() throws {
        let xmlString = """
        <transition duration="1s">
            <filter-audio ref="r2" name="Audio Transition"/>
        </transition>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let rootElement = try #require(xmlDoc.rootElement())
        let transition = try #require(FinalCutPro.FCPXML.Transition(element: rootElement))
        
        let filters = transition.audioFilters
        #expect(filters.count == 1)
        #expect(filters[0].effectID == "r2")
    }
    
    @Test("Transition filters round-trip")
    func transitionFiltersRoundTrip() {
        let transition = FinalCutPro.FCPXML.Transition(duration: Fraction(1, 1))
        
        let videoFilter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1", name: "Video Effect")
        let audioFilter = FinalCutPro.FCPXML.AudioFilter(effectID: "r2", name: "Audio Effect")
        
        transition.videoFilters = [videoFilter]
        transition.audioFilters = [audioFilter]
        
        #expect(transition.videoFilters.count == 1)
        #expect(transition.audioFilters.count == 1)
        
        // Verify XML structure
        let videoFilterElements = transition.element.childElements.filter { $0.name == "filter-video" }
        let audioFilterElements = transition.element.childElements.filter { $0.name == "filter-audio" }
        #expect(videoFilterElements.count == 1)
        #expect(audioFilterElements.count == 1)
    }
    
    // MARK: - Effect Resource Tests
    
    @Test("Effect resource initialization")
    func effectResourceInitialization() {
        let effect = FinalCutPro.FCPXML.Effect(
            id: "r1",
            name: "Color Correction",
            uid: "com.apple.color",
            src: "file:///path/to/effect.motiontemplate"
        )
        
        #expect(effect.id == "r1")
        #expect(effect.name == "Color Correction")
        #expect(effect.uid == "com.apple.color")
        #expect(effect.src == "file:///path/to/effect.motiontemplate")
    }
    
    @Test("Effect resource Codable")
    func effectResourceCodable() throws {
        let effect = FinalCutPro.FCPXML.Effect(
            id: "r1",
            name: "Test Effect",
            uid: "com.test.effect"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(effect)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Effect.self, from: data)
        
        #expect(decoded.id == effect.id)
        #expect(decoded.name == effect.name)
        #expect(decoded.uid == effect.uid)
    }
    
    @Test("Effect equatable")
    func effectEquatable() {
        let effect1 = FinalCutPro.FCPXML.Effect(id: "r1", name: "Effect", uid: "uid1")
        let effect2 = FinalCutPro.FCPXML.Effect(id: "r1", name: "Effect", uid: "uid1")
        let effect3 = FinalCutPro.FCPXML.Effect(id: "r2", name: "Effect", uid: "uid1")
        
        #expect(effect1 == effect2)
        #expect(effect1 != effect3)
    }
}

