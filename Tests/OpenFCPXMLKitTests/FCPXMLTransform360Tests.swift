//
//  FCPXMLTransform360Tests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Transform360 adjustment models and clip integration.
//

import Foundation
import Testing
import SwiftTimecode
@testable import OpenFCPXMLKit

@Suite("Transform360 adjustments")
struct FCPXMLTransform360Tests {
    
    // MARK: - Transform360CoordinateType Tests
    
    @Test("Transform360 coordinate type cases")
    func transform360CoordinateTypeCases() {
        #expect(FinalCutPro.FCPXML.Transform360CoordinateType.spherical.rawValue == "spherical")
        #expect(FinalCutPro.FCPXML.Transform360CoordinateType.cartesian.rawValue == "cartesian")
    }
    
    // MARK: - Transform360Adjustment Tests
    
    @Test("Transform360 initialization")
    func transform360Initialization() {
        let adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical,
            isEnabled: true,
            autoOrient: true
        )
        
        #expect(adjustment.coordinateType == .spherical)
        #expect(adjustment.isEnabled)
        #expect(adjustment.autoOrient)
    }
    
    @Test("Transform360 with spherical coordinates")
    func transform360WithSphericalCoordinates() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.latitude = 45.0
        adjustment.longitude = 90.0
        adjustment.distance = 10.0
        
        #expect(adjustment.latitude == 45.0)
        #expect(adjustment.longitude == 90.0)
        #expect(adjustment.distance == 10.0)
    }
    
    @Test("Transform360 with cartesian coordinates")
    func transform360WithCartesianCoordinates() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .cartesian
        )
        
        adjustment.xPosition = 1.0
        adjustment.yPosition = 2.0
        adjustment.zPosition = 3.0
        
        #expect(adjustment.xPosition == 1.0)
        #expect(adjustment.yPosition == 2.0)
        #expect(adjustment.zPosition == 3.0)
    }
    
    @Test("Transform360 with orientation")
    func transform360WithOrientation() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.xOrientation = 10.0
        adjustment.yOrientation = 20.0
        adjustment.zOrientation = 30.0
        
        #expect(adjustment.xOrientation == 10.0)
        #expect(adjustment.yOrientation == 20.0)
        #expect(adjustment.zOrientation == 30.0)
    }
    
    @Test("Transform360 with convergence and interaxial")
    func transform360WithConvergenceAndInteraxial() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.convergence = 0.5
        adjustment.interaxial = 2.0
        
        #expect(adjustment.convergence == 0.5)
        #expect(adjustment.interaxial == 2.0)
    }
    
    @Test("Transform360 Codable")
    func transform360Codable() throws {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        adjustment.latitude = 45.0
        adjustment.longitude = 90.0
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Transform360Adjustment.self, from: data)
        
        #expect(decoded.coordinateType == adjustment.coordinateType)
        #expect(decoded.latitude == adjustment.latitude)
        #expect(decoded.longitude == adjustment.longitude)
    }
    
    // MARK: - Clip Integration Tests
    
    @Test("Clip Transform360 adjustment spherical")
    func clipTransform360AdjustmentSpherical() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-360-transform coordinates="spherical" latitude="45.0" longitude="90.0" distance="10.0"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.transform360Adjustment
        #expect(adjustment != nil)
        #expect(adjustment?.coordinateType == .spherical)
        #expect(adjustment?.latitude == 45.0)
        #expect(adjustment?.longitude == 90.0)
        #expect(adjustment?.distance == 10.0)
    }
    
    @Test("Clip Transform360 adjustment cartesian")
    func clipTransform360AdjustmentCartesian() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-360-transform coordinates="cartesian" xPosition="1.0" yPosition="2.0" zPosition="3.0"/>
        </clip>
        """
        
        let xmlDoc = try FoundationXMLFactory().makeDocument(xmlString: xmlString)
        let clipElement = try #require(xmlDoc.rootElement())
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipElement))
        
        let adjustment = clip.transform360Adjustment
        #expect(adjustment != nil)
        #expect(adjustment?.coordinateType == .cartesian)
        #expect(adjustment?.xPosition == 1.0)
        #expect(adjustment?.yPosition == 2.0)
        #expect(adjustment?.zPosition == 3.0)
    }
    
    @Test("Clip Transform360 round-trip")
    func clipTransform360RoundTrip() {
        let clip = FinalCutPro.FCPXML.Clip(duration: Fraction(5, 1))
        
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical,
            isEnabled: true,
            autoOrient: true
        )
        adjustment.latitude = 45.0
        adjustment.longitude = 90.0
        adjustment.xOrientation = 10.0
        adjustment.convergence = 0.5
        
        clip.transform360Adjustment = adjustment
        
        let retrieved = clip.transform360Adjustment
        #expect(retrieved != nil)
        #expect(retrieved?.coordinateType == .spherical)
        #expect(retrieved?.latitude == 45.0)
        #expect(retrieved?.longitude == 90.0)
        #expect(retrieved?.xOrientation == 10.0)
        #expect(retrieved?.convergence == 0.5)
        
        // Verify XML structure
        let transformElement = clip.element.firstChildElement(named: "adjust-360-transform")
        #expect(transformElement != nil)
        #expect(transformElement?.stringValue(forAttributeNamed: "coordinates") == "spherical")
    }
}

