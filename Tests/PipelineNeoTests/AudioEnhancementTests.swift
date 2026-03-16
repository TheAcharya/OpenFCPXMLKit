//
//  AudioEnhancementTests.swift
//  PipelineNeoTests
//  © 2026 • Licensed under MIT License
//

import XCTest
import SwiftTimecode
@testable import PipelineNeo

final class AudioEnhancementTests: XCTestCase {
    
    // MARK: - NoiseReductionAdjustment Tests
    
    func testNoiseReductionInitialization() {
        let adjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.5)
        
        XCTAssertEqual(adjustment.amount, 0.5)
    }
    
    func testNoiseReductionCodable() throws {
        let adjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.75)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.NoiseReductionAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.amount, adjustment.amount)
    }
    
    // MARK: - HumReductionAdjustment Tests
    
    func testHumReductionInitialization() {
        let adjustment = FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz50)
        
        XCTAssertEqual(adjustment.frequency, .hz50)
    }
    
    func testHumReductionFrequencyCases() {
        XCTAssertEqual(FinalCutPro.FCPXML.HumReductionFrequency.hz50.rawValue, "50")
        XCTAssertEqual(FinalCutPro.FCPXML.HumReductionFrequency.hz60.rawValue, "60")
    }
    
    func testHumReductionCodable() throws {
        let adjustment = FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz60)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.HumReductionAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.frequency, adjustment.frequency)
    }
    
    // MARK: - EqualizationAdjustment Tests
    
    func testEqualizationInitialization() {
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(mode: .voiceEnhance)
        
        XCTAssertEqual(adjustment.mode, .voiceEnhance)
    }
    
    func testEqualizationModes() {
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.flat.rawValue, "flat")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.voiceEnhance.rawValue, "voice_enhance")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.musicEnhance.rawValue, "music_enhance")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.loudness.rawValue, "loudness")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.humReduction.rawValue, "hum_reduction")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.bassBoost.rawValue, "bass_boost")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.bassReduce.rawValue, "bass_reduce")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.trebleBoost.rawValue, "treble_boost")
        XCTAssertEqual(FinalCutPro.FCPXML.EqualizationMode.trebleReduce.rawValue, "treble_reduce")
    }
    
    func testEqualizationWithParameters() {
        let param = FinalCutPro.FCPXML.FilterParameter(name: "Frequency", value: "1000")
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(
            mode: .flat,
            parameters: [param]
        )
        
        XCTAssertEqual(adjustment.parameters.count, 1)
        XCTAssertEqual(adjustment.parameters[0].name, "Frequency")
    }
    
    func testEqualizationCodable() throws {
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(mode: .musicEnhance)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.EqualizationAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.mode, adjustment.mode)
    }
    
    // MARK: - MatchEqualizationAdjustment Tests
    
    func testMatchEqualizationInitialization() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "matchEQ", value: "data value")
        let adjustment = FinalCutPro.FCPXML.MatchEqualizationAdjustment(data: data)
        
        XCTAssertEqual(adjustment.data.key, "matchEQ")
        XCTAssertEqual(adjustment.data.value, "data value")
    }
    
    func testMatchEqualizationCodable() throws {
        let data = FinalCutPro.FCPXML.KeyedData(key: "matchEQ", value: "data")
        let adjustment = FinalCutPro.FCPXML.MatchEqualizationAdjustment(data: data)
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchEqualizationAdjustment.self, from: encoded)
        
        XCTAssertEqual(decoded.data.key, adjustment.data.key)
        XCTAssertEqual(decoded.data.value, adjustment.data.value)
    }
    
    // MARK: - Clip Integration Tests
    
    func testClipNoiseReductionAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-noiseReduction amount="0.5"/>
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
        
        let adjustment = clip.noiseReductionAdjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.amount, 0.5)
    }
    
    func testClipHumReductionAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-humReduction frequency="60"/>
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
        
        let adjustment = clip.humReductionAdjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.frequency, .hz60)
    }
    
    func testClipEqualizationAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-EQ mode="voice_enhance">
                <param name="Frequency" value="1000"/>
            </adjust-EQ>
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
        
        let adjustment = clip.equalizationAdjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.mode, .voiceEnhance)
        XCTAssertEqual(adjustment?.parameters.count, 1)
    }
    
    func testClipMatchEqualizationAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-matchEQ>
                <data key="matchEQ">match data</data>
            </adjust-matchEQ>
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
        
        let adjustment = clip.matchEqualizationAdjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.data.key, "matchEQ")
        XCTAssertEqual(adjustment?.data.value, "match data")
    }
    
    func testClipAudioEnhancementsRoundTrip() {
        let clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
        
        let noiseReduction = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.5)
        let humReduction = FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz60)
        let equalization = FinalCutPro.FCPXML.EqualizationAdjustment(mode: .voiceEnhance)
        let matchEQ = FinalCutPro.FCPXML.MatchEqualizationAdjustment(
            data: FinalCutPro.FCPXML.KeyedData(key: "matchEQ", value: "data")
        )
        
        clip.noiseReductionAdjustment = noiseReduction
        clip.humReductionAdjustment = humReduction
        clip.equalizationAdjustment = equalization
        clip.matchEqualizationAdjustment = matchEQ
        
        XCTAssertEqual(clip.noiseReductionAdjustment?.amount, 0.5)
        XCTAssertEqual(clip.humReductionAdjustment?.frequency, .hz60)
        XCTAssertEqual(clip.equalizationAdjustment?.mode, .voiceEnhance)
        XCTAssertEqual(clip.matchEqualizationAdjustment?.data.key, "matchEQ")
        
        // Verify XML structure
        let noiseElement = clip.element.firstChildElement(named: "adjust-noiseReduction")
        let humElement = clip.element.firstChildElement(named: "adjust-humReduction")
        let eqElement = clip.element.firstChildElement(named: "adjust-EQ")
        let matchEQElement = clip.element.firstChildElement(named: "adjust-matchEQ")
        
        XCTAssertNotNil(noiseElement)
        XCTAssertNotNil(humElement)
        XCTAssertNotNil(eqElement)
        XCTAssertNotNil(matchEQElement)
    }
}
