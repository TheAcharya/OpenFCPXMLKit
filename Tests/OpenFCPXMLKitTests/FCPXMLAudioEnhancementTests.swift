//
//  FCPXMLAudioEnhancementTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for audio enhancement adjustments and clip integration.
//

import Foundation
import Testing
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("Audio enhancement adjustments")
struct FCPXMLAudioEnhancementTests {
    
    // MARK: - NoiseReductionAdjustment Tests
    
    @Test("Noise reduction initialization")
    func noiseReductionInitialization() {
        let adjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.5)
        
        #expect(adjustment.amount == 0.5)
    }
    
    @Test("Noise reduction Codable")
    func noiseReductionCodable() throws {
        let adjustment = FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0.75)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.NoiseReductionAdjustment.self, from: data)
        
        #expect(decoded.amount == adjustment.amount)
    }
    
    // MARK: - HumReductionAdjustment Tests
    
    @Test("Hum reduction initialization")
    func humReductionInitialization() {
        let adjustment = FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz50)
        
        #expect(adjustment.frequency == .hz50)
    }
    
    @Test("Hum reduction frequency cases")
    func humReductionFrequencyCases() {
        #expect(FinalCutPro.FCPXML.HumReductionFrequency.hz50.rawValue == "50")
        #expect(FinalCutPro.FCPXML.HumReductionFrequency.hz60.rawValue == "60")
    }
    
    @Test("Hum reduction Codable")
    func humReductionCodable() throws {
        let adjustment = FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz60)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.HumReductionAdjustment.self, from: data)
        
        #expect(decoded.frequency == adjustment.frequency)
    }
    
    // MARK: - EqualizationAdjustment Tests
    
    @Test("Equalization initialization")
    func equalizationInitialization() {
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(mode: .voiceEnhance)
        
        #expect(adjustment.mode == .voiceEnhance)
    }
    
    @Test("Equalization modes")
    func equalizationModes() {
        #expect(FinalCutPro.FCPXML.EqualizationMode.flat.rawValue == "flat")
        #expect(FinalCutPro.FCPXML.EqualizationMode.voiceEnhance.rawValue == "voice_enhance")
        #expect(FinalCutPro.FCPXML.EqualizationMode.musicEnhance.rawValue == "music_enhance")
        #expect(FinalCutPro.FCPXML.EqualizationMode.loudness.rawValue == "loudness")
        #expect(FinalCutPro.FCPXML.EqualizationMode.humReduction.rawValue == "hum_reduction")
        #expect(FinalCutPro.FCPXML.EqualizationMode.bassBoost.rawValue == "bass_boost")
        #expect(FinalCutPro.FCPXML.EqualizationMode.bassReduce.rawValue == "bass_reduce")
        #expect(FinalCutPro.FCPXML.EqualizationMode.trebleBoost.rawValue == "treble_boost")
        #expect(FinalCutPro.FCPXML.EqualizationMode.trebleReduce.rawValue == "treble_reduce")
    }
    
    @Test("Equalization with parameters")
    func equalizationWithParameters() {
        let param = FinalCutPro.FCPXML.FilterParameter(name: "Frequency", value: "1000")
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(
            mode: .flat,
            parameters: [param]
        )
        
        #expect(adjustment.parameters.count == 1)
        #expect(adjustment.parameters[0].name == "Frequency")
    }
    
    @Test("Equalization Codable")
    func equalizationCodable() throws {
        let adjustment = FinalCutPro.FCPXML.EqualizationAdjustment(mode: .musicEnhance)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.EqualizationAdjustment.self, from: data)
        
        #expect(decoded.mode == adjustment.mode)
    }
    
    // MARK: - MatchEqualizationAdjustment Tests
    
    @Test("Match equalization initialization")
    func matchEqualizationInitialization() {
        let data = FinalCutPro.FCPXML.KeyedData(key: "matchEQ", value: "data value")
        let adjustment = FinalCutPro.FCPXML.MatchEqualizationAdjustment(data: data)
        
        #expect(adjustment.data.key == "matchEQ")
        #expect(adjustment.data.value == "data value")
    }
    
    @Test("Match equalization Codable")
    func matchEqualizationCodable() throws {
        let data = FinalCutPro.FCPXML.KeyedData(key: "matchEQ", value: "data")
        let adjustment = FinalCutPro.FCPXML.MatchEqualizationAdjustment(data: data)
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.MatchEqualizationAdjustment.self, from: encoded)
        
        #expect(decoded.data.key == adjustment.data.key)
        #expect(decoded.data.value == adjustment.data.value)
    }
    
    // MARK: - Clip Integration Tests
    
    @Test("Clip noise reduction adjustment")
    func clipNoiseReductionAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-noiseReduction amount="0.5"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.noiseReductionAdjustment
        #expect(adjustment != nil)
        #expect(adjustment?.amount == 0.5)
    }
    
    @Test("Clip hum reduction adjustment")
    func clipHumReductionAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-humReduction frequency="60"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.humReductionAdjustment
        #expect(adjustment != nil)
        #expect(adjustment?.frequency == .hz60)
    }
    
    @Test("Clip equalization adjustment")
    func clipEqualizationAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-EQ mode="voice_enhance">
                <param name="Frequency" value="1000"/>
            </adjust-EQ>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.equalizationAdjustment
        #expect(adjustment != nil)
        #expect(adjustment?.mode == .voiceEnhance)
        #expect(adjustment?.parameters.count == 1)
    }
    
    @Test("Clip match equalization adjustment")
    func clipMatchEqualizationAdjustment() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-matchEQ>
                <data key="matchEQ">match data</data>
            </adjust-matchEQ>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.matchEqualizationAdjustment
        #expect(adjustment != nil)
        #expect(adjustment?.data.key == "matchEQ")
        #expect(adjustment?.data.value == "match data")
    }
    
    @Test("Clip audio enhancements round-trip")
    func clipAudioEnhancementsRoundTrip() {
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
        
        #expect(clip.noiseReductionAdjustment?.amount == 0.5)
        #expect(clip.humReductionAdjustment?.frequency == .hz60)
        #expect(clip.equalizationAdjustment?.mode == .voiceEnhance)
        #expect(clip.matchEqualizationAdjustment?.data.key == "matchEQ")
        
        // Verify XML structure
        let noiseElement = clip.element.firstChildElement(named: "adjust-noiseReduction")
        let humElement = clip.element.firstChildElement(named: "adjust-humReduction")
        let eqElement = clip.element.firstChildElement(named: "adjust-EQ")
        let matchEQElement = clip.element.firstChildElement(named: "adjust-matchEQ")
        
        #expect(noiseElement != nil)
        #expect(humElement != nil)
        #expect(eqElement != nil)
        #expect(matchEQElement != nil)
    }
}

