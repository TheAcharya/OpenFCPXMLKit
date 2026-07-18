//
//  FCPXMLAdjustmentTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for typed adjustment models and clip integration.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Adjustment models")
struct FCPXMLAdjustmentTests {
    
    // MARK: - Point Tests
    
    @Test("Point initialization")
    func pointInitialization() {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        
        #expect(point.x == 100)
        #expect(point.y == 200)
    }
    
    @Test("Point zero")
    func pointZero() {
        let zero = FinalCutPro.FCPXML.Point.zero
        #expect(zero.x == 0)
        #expect(zero.y == 0)
    }
    
    @Test("Point from string")
    func pointFromString() {
        let point = FinalCutPro.FCPXML.Point(fromString: "100 200")
        #expect(point != nil)
        #expect(point?.x == 100)
        #expect(point?.y == 200)
        
        let invalidPoint = FinalCutPro.FCPXML.Point(fromString: "invalid")
        #expect(invalidPoint == nil)
    }
    
    @Test("Point string value")
    func pointStringValue() {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        #expect(point.stringValue == "100 200")
    }
    
    @Test("Point equality")
    func pointEquality() {
        let point1 = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let point2 = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let point3 = FinalCutPro.FCPXML.Point(x: 200, y: 100)
        
        #expect(point1 == point2)
        #expect(point1 != point3)
    }
    
    @Test("Point Codable")
    func pointCodable() throws {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Point.self, from: data)
        
        #expect(decoded.x == point.x)
        #expect(decoded.y == point.y)
    }
    
    // MARK: - CropAdjustment Tests
    
    @Test("Crop adjustment initialization")
    func cropAdjustmentInitialization() {
        let crop = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        
        #expect(crop.mode == .crop)
        #expect(crop.isEnabled)
    }
    
    @Test("Crop adjustment modes")
    func cropAdjustmentModes() {
        #expect(FinalCutPro.FCPXML.CropAdjustment.Mode.trim.rawValue == "trim")
        #expect(FinalCutPro.FCPXML.CropAdjustment.Mode.crop.rawValue == "crop")
        #expect(FinalCutPro.FCPXML.CropAdjustment.Mode.pan.rawValue == "pan")
    }
    
    @Test("Crop rect initialization")
    func cropRectInitialization() {
        let cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(
            left: 10,
            top: 20,
            right: 100,
            bottom: 200
        )
        
        #expect(cropRect.left == 10)
        #expect(cropRect.top == 20)
        #expect(cropRect.right == 100)
        #expect(cropRect.bottom == 200)
    }
    
    @Test("Trim rect initialization")
    func trimRectInitialization() {
        let trimRect = FinalCutPro.FCPXML.CropAdjustment.TrimRect(
            left: 5,
            top: 10,
            right: 50,
            bottom: 100
        )
        
        #expect(trimRect.left == 5)
        #expect(trimRect.top == 10)
    }
    
    @Test("Pan rect initialization")
    func panRectInitialization() {
        let panRect = FinalCutPro.FCPXML.CropAdjustment.PanRect(
            left: 0,
            top: 0,
            right: 100,
            bottom: 100
        )
        
        #expect(panRect.left == 0)
        #expect(panRect.right == 100)
    }
    
    @Test("Crop adjustment with rects")
    func cropAdjustmentWithRects() {
        var crop = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        crop.cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(
            left: 10,
            top: 20,
            right: 100,
            bottom: 200
        )
        
        #expect(crop.cropRect != nil)
        #expect(crop.cropRect?.left == 10)
    }
    
    @Test("Crop adjustment Codable")
    func cropAdjustmentCodable() throws {
        var crop = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        crop.cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(
            left: 10,
            top: 20,
            right: 100,
            bottom: 200
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(crop)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.CropAdjustment.self, from: data)
        
        #expect(decoded.mode == crop.mode)
        #expect(decoded.cropRect?.left == crop.cropRect?.left)
    }
    
    // MARK: - TransformAdjustment Tests
    
    @Test("Transform adjustment initialization")
    func transformAdjustmentInitialization() {
        let transform = FinalCutPro.FCPXML.TransformAdjustment()
        
        #expect(transform.position == .zero)
        #expect(transform.scale == FinalCutPro.FCPXML.Point(x: 1, y: 1))
        #expect(transform.rotation == 0)
        #expect(transform.anchor == .zero)
        #expect(transform.isEnabled)
    }
    
    @Test("Transform adjustment custom values")
    func transformAdjustmentCustomValues() {
        let position = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let scale = FinalCutPro.FCPXML.Point(x: 1.5, y: 1.5)
        let anchor = FinalCutPro.FCPXML.Point(x: 50, y: 50)
        
        let transform = FinalCutPro.FCPXML.TransformAdjustment(
            position: position,
            scale: scale,
            rotation: 45,
            anchor: anchor
        )
        
        #expect(transform.position == position)
        #expect(transform.scale == scale)
        #expect(transform.rotation == 45)
        #expect(transform.anchor == anchor)
    }
    
    @Test("Transform adjustment Codable")
    func transformAdjustmentCodable() throws {
        let transform = FinalCutPro.FCPXML.TransformAdjustment(
            position: FinalCutPro.FCPXML.Point(x: 100, y: 200),
            scale: FinalCutPro.FCPXML.Point(x: 1.5, y: 1.5),
            rotation: 45,
            anchor: FinalCutPro.FCPXML.Point(x: 50, y: 50)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(transform)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.TransformAdjustment.self, from: data)
        
        #expect(decoded.position.x == transform.position.x)
        #expect(decoded.rotation == transform.rotation)
    }
    
    // MARK: - BlendAdjustment Tests
    
    @Test("Blend adjustment initialization")
    func blendAdjustmentInitialization() {
        let blend = FinalCutPro.FCPXML.BlendAdjustment()
        
        #expect(blend.amount == 1.0)
        #expect(blend.mode == nil)
    }
    
    @Test("Blend adjustment with mode")
    func blendAdjustmentWithMode() {
        let blend = FinalCutPro.FCPXML.BlendAdjustment(mode: "multiply", amount: 0.5)
        
        #expect(blend.mode == "multiply")
        #expect(blend.amount == 0.5)
    }
    
    @Test("Blend adjustment Codable")
    func blendAdjustmentCodable() throws {
        let blend = FinalCutPro.FCPXML.BlendAdjustment(mode: "overlay", amount: 0.75)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(blend)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.BlendAdjustment.self, from: data)
        
        #expect(decoded.mode == blend.mode)
        #expect(decoded.amount == blend.amount)
    }
    
    // MARK: - StabilizationAdjustment Tests
    
    @Test("Stabilization adjustment initialization")
    func stabilizationAdjustmentInitialization() {
        let stabilization = FinalCutPro.FCPXML.StabilizationAdjustment()
        
        #expect(stabilization.type == .automatic)
    }
    
    @Test("Stabilization adjustment modes")
    func stabilizationAdjustmentModes() {
        #expect(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.automatic.rawValue == "automatic")
        #expect(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.inertiaCam.rawValue == "inertiaCam")
        #expect(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.smoothCam.rawValue == "smoothCam")
    }
    
    @Test("Stabilization adjustment Codable")
    func stabilizationAdjustmentCodable() throws {
        let stabilization = FinalCutPro.FCPXML.StabilizationAdjustment(type: .smoothCam)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(stabilization)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.StabilizationAdjustment.self, from: data)
        
        #expect(decoded.type == stabilization.type)
    }

    // MARK: - RollingShutterAdjustment Tests

    @Test("Rolling shutter adjustment initialization")
    func rollingShutterAdjustmentInitialization() {
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment()
        #expect(rs.isEnabled)
        #expect(rs.amount == .none)
        let rs2 = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: false, amount: .high)
        #expect(!rs2.isEnabled)
        #expect(rs2.amount == .high)
    }

    @Test("Rolling shutter adjustment Codable")
    func rollingShutterAdjustmentCodable() throws {
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: true, amount: .medium)
        let data = try JSONEncoder().encode(rs)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.RollingShutterAdjustment.self, from: data)
        #expect(decoded.isEnabled == rs.isEnabled)
        #expect(decoded.amount == rs.amount)
    }

    // MARK: - ConformAdjustment Tests

    @Test("Conform adjustment initialization")
    func conformAdjustmentInitialization() {
        let conform = FinalCutPro.FCPXML.ConformAdjustment()
        #expect(conform.type == .fit)
        let fill = FinalCutPro.FCPXML.ConformAdjustment(type: .fill)
        #expect(fill.type == .fill)
    }

    @Test("Conform adjustment Codable")
    func conformAdjustmentCodable() throws {
        let conform = FinalCutPro.FCPXML.ConformAdjustment(type: .none)
        let data = try JSONEncoder().encode(conform)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ConformAdjustment.self, from: data)
        #expect(decoded.type == .none)
    }
    
    // MARK: - VolumeAdjustment Tests
    
    @Test("Volume adjustment initialization")
    func volumeAdjustmentInitialization() {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        
        #expect(volume.amount == 3.0)
    }
    
    @Test("Volume adjustment from decibel string")
    func volumeAdjustmentFromDecibelString() {
        let volume1 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "3dB")
        #expect(volume1 != nil)
        #expect(volume1?.amount == 3.0)
        
        let volume2 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "-6dB")
        #expect(volume2 != nil)
        #expect(volume2?.amount == -6.0)
        
        let volume3 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "invalid")
        #expect(volume3 == nil)
    }
    
    @Test("Volume adjustment decibel string")
    func volumeAdjustmentDecibelString() {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        #expect(volume.decibelString == "3.0dB")
        
        let negativeVolume = FinalCutPro.FCPXML.VolumeAdjustment(amount: -6.0)
        #expect(negativeVolume.decibelString == "-6.0dB")
    }
    
    @Test("Volume adjustment Codable")
    func volumeAdjustmentCodable() throws {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(volume)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.VolumeAdjustment.self, from: data)
        
        #expect(decoded.amount == volume.amount)
    }
    
    // MARK: - LoudnessAdjustment Tests
    
    @Test("Loudness adjustment initialization")
    func loudnessAdjustmentInitialization() {
        let loudness = FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0.5, uniformity: 0.8)
        
        #expect(loudness.amount == 0.5)
        #expect(loudness.uniformity == 0.8)
    }
    
    @Test("Loudness adjustment Codable")
    func loudnessAdjustmentCodable() throws {
        let loudness = FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0.5, uniformity: 0.8)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(loudness)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.LoudnessAdjustment.self, from: data)
        
        #expect(decoded.amount == loudness.amount)
        #expect(decoded.uniformity == loudness.uniformity)
    }

    // MARK: - ReorientAdjustment (FCPXML 1.7+)

    @Test("Reorient adjustment initialization")
    func reorientAdjustmentInitialization() {
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(tilt: "1", pan: "2", roll: "0", convergence: "0.5")
        #expect(reorient.tilt == "1")
        #expect(reorient.pan == "2")
        #expect(reorient.isEnabled)
    }

    @Test("Reorient adjustment Codable")
    func reorientAdjustmentCodable() throws {
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(convergence: "0.5")
        let data = try JSONEncoder().encode(reorient)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ReorientAdjustment.self, from: data)
        #expect(decoded.convergence == "0.5")
    }

    // MARK: - OrientationAdjustment (FCPXML 1.7+)

    @Test("Orientation adjustment initialization")
    func orientationAdjustmentInitialization() {
        let orientation = FinalCutPro.FCPXML.OrientationAdjustment(mapping: .tinyPlanet)
        #expect(orientation.mapping == .tinyPlanet)
    }

    @Test("Orientation adjustment Codable")
    func orientationAdjustmentCodable() throws {
        let orientation = FinalCutPro.FCPXML.OrientationAdjustment(fieldOfView: "90", mapping: .normal)
        let data = try JSONEncoder().encode(orientation)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.OrientationAdjustment.self, from: data)
        #expect(decoded.fieldOfView == "90")
    }

    // MARK: - CinematicAdjustment (FCPXML 1.10+)

    @Test("Cinematic adjustment initialization")
    func cinematicAdjustmentInitialization() {
        let cinematic = FinalCutPro.FCPXML.CinematicAdjustment(aperture: "2.8")
        #expect(cinematic.aperture == "2.8")
    }

    // MARK: - ColorConformAdjustment (FCPXML 1.11+)

    @Test("Color conform adjustment initialization")
    func colorConformAdjustmentInitialization() {
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            conformType: .conformHLGtoSDR,
            peakNitsOfPQSource: "1000",
            peakNitsOfSDRToPQSource: "100"
        )
        #expect(colorConform.conformType == .conformHLGtoSDR)
        #expect(colorConform.peakNitsOfPQSource == "1000")
    }

    @Test("Color conform adjustment Codable")
    func colorConformAdjustmentCodable() throws {
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            peakNitsOfPQSource: "2000",
            peakNitsOfSDRToPQSource: "200"
        )
        let data = try JSONEncoder().encode(colorConform)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ColorConformAdjustment.self, from: data)
        #expect(decoded.peakNitsOfSDRToPQSource == "200")
    }

    // MARK: - Stereo3DAdjustment (FCPXML 1.13+)

    @Test("Stereo 3D adjustment initialization")
    func stereo3DAdjustmentInitialization() {
        let stereo = FinalCutPro.FCPXML.Stereo3DAdjustment(swapEyes: true, depth: "0.5")
        #expect(stereo.swapEyes)
        #expect(stereo.depth == "0.5")
    }

    // MARK: - VoiceIsolationAdjustment (FCPXML 1.14)

    @Test("Voice isolation adjustment initialization")
    func voiceIsolationAdjustmentInitialization() {
        let voice = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "0.8")
        #expect(voice.amount == "0.8")
    }

    @Test("Voice isolation adjustment Codable")
    func voiceIsolationAdjustmentCodable() throws {
        let voice = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "1.0")
        let data = try JSONEncoder().encode(voice)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.VoiceIsolationAdjustment.self, from: data)
        #expect(decoded.amount == "1.0")
    }

    // MARK: - Clip adjustment round-trip (new adjustments)

    @Test("Clip reorient adjustment round-trip")
    func clipReorientAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipEl))
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(pan: "10", roll: "5")
        clip.reorientAdjustment = reorient
        #expect(clip.reorientAdjustment != nil)
        #expect(clip.reorientAdjustment?.pan == "10")
        let adjustEl = clip.element.firstChildElement(named: "adjust-reorient")
        #expect(adjustEl != nil)
        #expect(adjustEl?.stringValue(forAttributeNamed: "pan") == "10")
    }

    @Test("Clip color conform adjustment round-trip")
    func clipColorConformAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipEl))
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            peakNitsOfPQSource: "1000",
            peakNitsOfSDRToPQSource: "100"
        )
        clip.colorConformAdjustment = colorConform
        #expect(clip.colorConformAdjustment?.conformType == .conformNone)
        clip.colorConformAdjustment = nil
        #expect(clip.colorConformAdjustment == nil)
    }

    @Test("Clip stereo 3D adjustment round-trip")
    func clipStereo3DAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipEl))
        let stereo = FinalCutPro.FCPXML.Stereo3DAdjustment(convergence: "0.2", autoScale: false)
        clip.stereo3DAdjustment = stereo
        #expect(clip.stereo3DAdjustment?.convergence == "0.2")
        let autoScale = clip.stereo3DAdjustment?.autoScale ?? true
        #expect(!autoScale)
    }

    @Test("Clip rolling shutter adjustment round-trip")
    func clipRollingShutterAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipEl))
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: true, amount: .high)
        clip.rollingShutterAdjustment = rs
        #expect(clip.rollingShutterAdjustment != nil)
        #expect(clip.rollingShutterAdjustment?.amount == .high)
        let adjustEl = clip.element.firstChildElement(named: "adjust-rollingShutter")
        #expect(adjustEl?.stringValue(forAttributeNamed: "amount") == "high")
    }

    @Test("Clip conform adjustment round-trip")
    func clipConformAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: clipEl))
        let conform = FinalCutPro.FCPXML.ConformAdjustment(type: .fill)
        clip.conformAdjustment = conform
        #expect(clip.conformAdjustment?.type == .fill)
        let adjustEl = clip.element.firstChildElement(named: "adjust-conform")
        #expect(adjustEl?.stringValue(forAttributeNamed: "type") == "fill")
    }

    // MARK: - Equatable Tests
    
    @Test("Adjustment equality")
    func adjustmentEquality() {
        let crop1 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop2 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop3 = FinalCutPro.FCPXML.CropAdjustment(mode: .trim)
        
        #expect(crop1 == crop2)
        #expect(crop1 != crop3)
        
        let transform1 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform2 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform3 = FinalCutPro.FCPXML.TransformAdjustment(rotation: 45)
        
        #expect(transform1 == transform2)
        #expect(transform1 != transform3)
    }
    
    // MARK: - Hashable Tests
    
    @Test("Adjustment hashable")
    func adjustmentHashable() {
        let crop1 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop2 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        
        #expect(crop1.hashValue == crop2.hashValue)
        
        let transform1 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform2 = FinalCutPro.FCPXML.TransformAdjustment()
        
        #expect(transform1.hashValue == transform2.hashValue)
    }
}

