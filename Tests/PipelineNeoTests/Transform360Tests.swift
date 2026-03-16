//
//  Transform360Tests.swift
//  PipelineNeoTests
//  © 2026 • Licensed under MIT License
//

import XCTest
import SwiftTimecode
@testable import PipelineNeo

final class Transform360Tests: XCTestCase {
    
    // MARK: - Transform360CoordinateType Tests
    
    func testTransform360CoordinateTypeCases() {
        XCTAssertEqual(FinalCutPro.FCPXML.Transform360CoordinateType.spherical.rawValue, "spherical")
        XCTAssertEqual(FinalCutPro.FCPXML.Transform360CoordinateType.cartesian.rawValue, "cartesian")
    }
    
    // MARK: - Transform360Adjustment Tests
    
    func testTransform360Initialization() {
        let adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical,
            isEnabled: true,
            autoOrient: true
        )
        
        XCTAssertEqual(adjustment.coordinateType, .spherical)
        XCTAssertTrue(adjustment.isEnabled)
        XCTAssertTrue(adjustment.autoOrient)
    }
    
    func testTransform360WithSphericalCoordinates() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.latitude = 45.0
        adjustment.longitude = 90.0
        adjustment.distance = 10.0
        
        XCTAssertEqual(adjustment.latitude, 45.0)
        XCTAssertEqual(adjustment.longitude, 90.0)
        XCTAssertEqual(adjustment.distance, 10.0)
    }
    
    func testTransform360WithCartesianCoordinates() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .cartesian
        )
        
        adjustment.xPosition = 1.0
        adjustment.yPosition = 2.0
        adjustment.zPosition = 3.0
        
        XCTAssertEqual(adjustment.xPosition, 1.0)
        XCTAssertEqual(adjustment.yPosition, 2.0)
        XCTAssertEqual(adjustment.zPosition, 3.0)
    }
    
    func testTransform360WithOrientation() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.xOrientation = 10.0
        adjustment.yOrientation = 20.0
        adjustment.zOrientation = 30.0
        
        XCTAssertEqual(adjustment.xOrientation, 10.0)
        XCTAssertEqual(adjustment.yOrientation, 20.0)
        XCTAssertEqual(adjustment.zOrientation, 30.0)
    }
    
    func testTransform360WithConvergenceAndInteraxial() {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        
        adjustment.convergence = 0.5
        adjustment.interaxial = 2.0
        
        XCTAssertEqual(adjustment.convergence, 0.5)
        XCTAssertEqual(adjustment.interaxial, 2.0)
    }
    
    func testTransform360Codable() throws {
        var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
            coordinateType: .spherical
        )
        adjustment.latitude = 45.0
        adjustment.longitude = 90.0
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(adjustment)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Transform360Adjustment.self, from: data)
        
        XCTAssertEqual(decoded.coordinateType, adjustment.coordinateType)
        XCTAssertEqual(decoded.latitude, adjustment.latitude)
        XCTAssertEqual(decoded.longitude, adjustment.longitude)
    }
    
    // MARK: - Clip Integration Tests
    
    func testClipTransform360AdjustmentSpherical() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-360-transform coordinates="spherical" latitude="45.0" longitude="90.0" distance="10.0"/>
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
        
        let adjustment = clip.transform360Adjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.coordinateType, .spherical)
        XCTAssertEqual(adjustment?.latitude, 45.0)
        XCTAssertEqual(adjustment?.longitude, 90.0)
        XCTAssertEqual(adjustment?.distance, 10.0)
    }
    
    func testClipTransform360AdjustmentCartesian() throws {
        let xmlString = """
        <clip duration="5s">
            <adjust-360-transform coordinates="cartesian" xPosition="1.0" yPosition="2.0" zPosition="3.0"/>
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
        
        let adjustment = clip.transform360Adjustment
        XCTAssertNotNil(adjustment)
        XCTAssertEqual(adjustment?.coordinateType, .cartesian)
        XCTAssertEqual(adjustment?.xPosition, 1.0)
        XCTAssertEqual(adjustment?.yPosition, 2.0)
        XCTAssertEqual(adjustment?.zPosition, 3.0)
    }
    
    func testClipTransform360RoundTrip() {
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
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.coordinateType, .spherical)
        XCTAssertEqual(retrieved?.latitude, 45.0)
        XCTAssertEqual(retrieved?.longitude, 90.0)
        XCTAssertEqual(retrieved?.xOrientation, 10.0)
        XCTAssertEqual(retrieved?.convergence, 0.5)
        
        // Verify XML structure
        let transformElement = clip.element.firstChildElement(named: "adjust-360-transform")
        XCTAssertNotNil(transformElement)
        XCTAssertEqual(transformElement?.stringValue(forAttributeNamed: "coordinates"), "spherical")
    }
}
