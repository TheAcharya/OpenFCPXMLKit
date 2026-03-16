//
//  AdjustmentTests.swift
//  PipelineNeoTests
//  © 2026 • Licensed under MIT License
//

import XCTest
@testable import PipelineNeo

final class AdjustmentTests: XCTestCase {
    
    // MARK: - Point Tests
    
    func testPointInitialization() {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        
        XCTAssertEqual(point.x, 100)
        XCTAssertEqual(point.y, 200)
    }
    
    func testPointZero() {
        let zero = FinalCutPro.FCPXML.Point.zero
        XCTAssertEqual(zero.x, 0)
        XCTAssertEqual(zero.y, 0)
    }
    
    func testPointFromString() {
        let point = FinalCutPro.FCPXML.Point(fromString: "100 200")
        XCTAssertNotNil(point)
        XCTAssertEqual(point?.x, 100)
        XCTAssertEqual(point?.y, 200)
        
        let invalidPoint = FinalCutPro.FCPXML.Point(fromString: "invalid")
        XCTAssertNil(invalidPoint)
    }
    
    func testPointStringValue() {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        XCTAssertEqual(point.stringValue, "100 200")
    }
    
    func testPointEquality() {
        let point1 = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let point2 = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let point3 = FinalCutPro.FCPXML.Point(x: 200, y: 100)
        
        XCTAssertEqual(point1, point2)
        XCTAssertNotEqual(point1, point3)
    }
    
    func testPointCodable() throws {
        let point = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Point.self, from: data)
        
        XCTAssertEqual(decoded.x, point.x)
        XCTAssertEqual(decoded.y, point.y)
    }
    
    // MARK: - CropAdjustment Tests
    
    func testCropAdjustmentInitialization() {
        let crop = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        
        XCTAssertEqual(crop.mode, .crop)
        XCTAssertTrue(crop.isEnabled)
    }
    
    func testCropAdjustmentModes() {
        XCTAssertEqual(FinalCutPro.FCPXML.CropAdjustment.Mode.trim.rawValue, "trim")
        XCTAssertEqual(FinalCutPro.FCPXML.CropAdjustment.Mode.crop.rawValue, "crop")
        XCTAssertEqual(FinalCutPro.FCPXML.CropAdjustment.Mode.pan.rawValue, "pan")
    }
    
    func testCropRectInitialization() {
        let cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(
            left: 10,
            top: 20,
            right: 100,
            bottom: 200
        )
        
        XCTAssertEqual(cropRect.left, 10)
        XCTAssertEqual(cropRect.top, 20)
        XCTAssertEqual(cropRect.right, 100)
        XCTAssertEqual(cropRect.bottom, 200)
    }
    
    func testTrimRectInitialization() {
        let trimRect = FinalCutPro.FCPXML.CropAdjustment.TrimRect(
            left: 5,
            top: 10,
            right: 50,
            bottom: 100
        )
        
        XCTAssertEqual(trimRect.left, 5)
        XCTAssertEqual(trimRect.top, 10)
    }
    
    func testPanRectInitialization() {
        let panRect = FinalCutPro.FCPXML.CropAdjustment.PanRect(
            left: 0,
            top: 0,
            right: 100,
            bottom: 100
        )
        
        XCTAssertEqual(panRect.left, 0)
        XCTAssertEqual(panRect.right, 100)
    }
    
    func testCropAdjustmentWithRects() {
        var crop = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        crop.cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(
            left: 10,
            top: 20,
            right: 100,
            bottom: 200
        )
        
        XCTAssertNotNil(crop.cropRect)
        XCTAssertEqual(crop.cropRect?.left, 10)
    }
    
    func testCropAdjustmentCodable() throws {
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
        
        XCTAssertEqual(decoded.mode, crop.mode)
        XCTAssertEqual(decoded.cropRect?.left, crop.cropRect?.left)
    }
    
    // MARK: - TransformAdjustment Tests
    
    func testTransformAdjustmentInitialization() {
        let transform = FinalCutPro.FCPXML.TransformAdjustment()
        
        XCTAssertEqual(transform.position, .zero)
        XCTAssertEqual(transform.scale, FinalCutPro.FCPXML.Point(x: 1, y: 1))
        XCTAssertEqual(transform.rotation, 0)
        XCTAssertEqual(transform.anchor, .zero)
        XCTAssertTrue(transform.isEnabled)
    }
    
    func testTransformAdjustmentCustomValues() {
        let position = FinalCutPro.FCPXML.Point(x: 100, y: 200)
        let scale = FinalCutPro.FCPXML.Point(x: 1.5, y: 1.5)
        let anchor = FinalCutPro.FCPXML.Point(x: 50, y: 50)
        
        let transform = FinalCutPro.FCPXML.TransformAdjustment(
            position: position,
            scale: scale,
            rotation: 45,
            anchor: anchor
        )
        
        XCTAssertEqual(transform.position, position)
        XCTAssertEqual(transform.scale, scale)
        XCTAssertEqual(transform.rotation, 45)
        XCTAssertEqual(transform.anchor, anchor)
    }
    
    func testTransformAdjustmentCodable() throws {
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
        
        XCTAssertEqual(decoded.position.x, transform.position.x)
        XCTAssertEqual(decoded.rotation, transform.rotation)
    }
    
    // MARK: - BlendAdjustment Tests
    
    func testBlendAdjustmentInitialization() {
        let blend = FinalCutPro.FCPXML.BlendAdjustment()
        
        XCTAssertEqual(blend.amount, 1.0)
        XCTAssertNil(blend.mode)
    }
    
    func testBlendAdjustmentWithMode() {
        let blend = FinalCutPro.FCPXML.BlendAdjustment(mode: "multiply", amount: 0.5)
        
        XCTAssertEqual(blend.mode, "multiply")
        XCTAssertEqual(blend.amount, 0.5)
    }
    
    func testBlendAdjustmentCodable() throws {
        let blend = FinalCutPro.FCPXML.BlendAdjustment(mode: "overlay", amount: 0.75)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(blend)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.BlendAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.mode, blend.mode)
        XCTAssertEqual(decoded.amount, blend.amount)
    }
    
    // MARK: - StabilizationAdjustment Tests
    
    func testStabilizationAdjustmentInitialization() {
        let stabilization = FinalCutPro.FCPXML.StabilizationAdjustment()
        
        XCTAssertEqual(stabilization.type, .automatic)
    }
    
    func testStabilizationAdjustmentModes() {
        XCTAssertEqual(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.automatic.rawValue, "automatic")
        XCTAssertEqual(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.inertiaCam.rawValue, "inertiaCam")
        XCTAssertEqual(FinalCutPro.FCPXML.StabilizationAdjustment.Mode.smoothCam.rawValue, "smoothCam")
    }
    
    func testStabilizationAdjustmentCodable() throws {
        let stabilization = FinalCutPro.FCPXML.StabilizationAdjustment(type: .smoothCam)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(stabilization)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.StabilizationAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.type, stabilization.type)
    }

    // MARK: - RollingShutterAdjustment Tests

    func testRollingShutterAdjustmentInitialization() {
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment()
        XCTAssertTrue(rs.isEnabled)
        XCTAssertEqual(rs.amount, .none)
        let rs2 = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: false, amount: .high)
        XCTAssertFalse(rs2.isEnabled)
        XCTAssertEqual(rs2.amount, .high)
    }

    func testRollingShutterAdjustmentCodable() throws {
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: true, amount: .medium)
        let data = try JSONEncoder().encode(rs)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.RollingShutterAdjustment.self, from: data)
        XCTAssertEqual(decoded.isEnabled, rs.isEnabled)
        XCTAssertEqual(decoded.amount, rs.amount)
    }

    // MARK: - ConformAdjustment Tests

    func testConformAdjustmentInitialization() {
        let conform = FinalCutPro.FCPXML.ConformAdjustment()
        XCTAssertEqual(conform.type, .fit)
        let fill = FinalCutPro.FCPXML.ConformAdjustment(type: .fill)
        XCTAssertEqual(fill.type, .fill)
    }

    func testConformAdjustmentCodable() throws {
        let conform = FinalCutPro.FCPXML.ConformAdjustment(type: .none)
        let data = try JSONEncoder().encode(conform)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ConformAdjustment.self, from: data)
        XCTAssertEqual(decoded.type, .none)
    }
    
    // MARK: - VolumeAdjustment Tests
    
    func testVolumeAdjustmentInitialization() {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        
        XCTAssertEqual(volume.amount, 3.0)
    }
    
    func testVolumeAdjustmentFromDecibelString() {
        let volume1 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "3dB")
        XCTAssertNotNil(volume1)
        XCTAssertEqual(volume1?.amount, 3.0)
        
        let volume2 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "-6dB")
        XCTAssertNotNil(volume2)
        XCTAssertEqual(volume2?.amount, -6.0)
        
        let volume3 = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: "invalid")
        XCTAssertNil(volume3)
    }
    
    func testVolumeAdjustmentDecibelString() {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        XCTAssertEqual(volume.decibelString, "3.0dB")
        
        let negativeVolume = FinalCutPro.FCPXML.VolumeAdjustment(amount: -6.0)
        XCTAssertEqual(negativeVolume.decibelString, "-6.0dB")
    }
    
    func testVolumeAdjustmentCodable() throws {
        let volume = FinalCutPro.FCPXML.VolumeAdjustment(amount: 3.0)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(volume)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.VolumeAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.amount, volume.amount)
    }
    
    // MARK: - LoudnessAdjustment Tests
    
    func testLoudnessAdjustmentInitialization() {
        let loudness = FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0.5, uniformity: 0.8)
        
        XCTAssertEqual(loudness.amount, 0.5)
        XCTAssertEqual(loudness.uniformity, 0.8)
    }
    
    func testLoudnessAdjustmentCodable() throws {
        let loudness = FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0.5, uniformity: 0.8)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(loudness)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.LoudnessAdjustment.self, from: data)
        
        XCTAssertEqual(decoded.amount, loudness.amount)
        XCTAssertEqual(decoded.uniformity, loudness.uniformity)
    }

    // MARK: - ReorientAdjustment (FCPXML 1.7+)

    func testReorientAdjustmentInitialization() {
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(tilt: "1", pan: "2", roll: "0", convergence: "0.5")
        XCTAssertEqual(reorient.tilt, "1")
        XCTAssertEqual(reorient.pan, "2")
        XCTAssertTrue(reorient.isEnabled)
    }

    func testReorientAdjustmentCodable() throws {
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(convergence: "0.5")
        let data = try JSONEncoder().encode(reorient)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ReorientAdjustment.self, from: data)
        XCTAssertEqual(decoded.convergence, "0.5")
    }

    // MARK: - OrientationAdjustment (FCPXML 1.7+)

    func testOrientationAdjustmentInitialization() {
        let orientation = FinalCutPro.FCPXML.OrientationAdjustment(mapping: .tinyPlanet)
        XCTAssertEqual(orientation.mapping, .tinyPlanet)
    }

    func testOrientationAdjustmentCodable() throws {
        let orientation = FinalCutPro.FCPXML.OrientationAdjustment(fieldOfView: "90", mapping: .normal)
        let data = try JSONEncoder().encode(orientation)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.OrientationAdjustment.self, from: data)
        XCTAssertEqual(decoded.fieldOfView, "90")
    }

    // MARK: - CinematicAdjustment (FCPXML 1.10+)

    func testCinematicAdjustmentInitialization() {
        let cinematic = FinalCutPro.FCPXML.CinematicAdjustment(aperture: "2.8")
        XCTAssertEqual(cinematic.aperture, "2.8")
    }

    // MARK: - ColorConformAdjustment (FCPXML 1.11+)

    func testColorConformAdjustmentInitialization() {
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            conformType: .conformHLGtoSDR,
            peakNitsOfPQSource: "1000",
            peakNitsOfSDRToPQSource: "100"
        )
        XCTAssertEqual(colorConform.conformType, .conformHLGtoSDR)
        XCTAssertEqual(colorConform.peakNitsOfPQSource, "1000")
    }

    func testColorConformAdjustmentCodable() throws {
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            peakNitsOfPQSource: "2000",
            peakNitsOfSDRToPQSource: "200"
        )
        let data = try JSONEncoder().encode(colorConform)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.ColorConformAdjustment.self, from: data)
        XCTAssertEqual(decoded.peakNitsOfSDRToPQSource, "200")
    }

    // MARK: - Stereo3DAdjustment (FCPXML 1.13+)

    func testStereo3DAdjustmentInitialization() {
        let stereo = FinalCutPro.FCPXML.Stereo3DAdjustment(swapEyes: true, depth: "0.5")
        XCTAssertTrue(stereo.swapEyes)
        XCTAssertEqual(stereo.depth, "0.5")
    }

    // MARK: - VoiceIsolationAdjustment (FCPXML 1.14)

    func testVoiceIsolationAdjustmentInitialization() {
        let voice = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "0.8")
        XCTAssertEqual(voice.amount, "0.8")
    }

    func testVoiceIsolationAdjustmentCodable() throws {
        let voice = FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: "1.0")
        let data = try JSONEncoder().encode(voice)
        let decoded = try JSONDecoder().decode(FinalCutPro.FCPXML.VoiceIsolationAdjustment.self, from: data)
        XCTAssertEqual(decoded.amount, "1.0")
    }

    // MARK: - Clip adjustment round-trip (new adjustments)

    func testClipReorientAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipEl) else { XCTFail("Clip init"); return }
        let reorient = FinalCutPro.FCPXML.ReorientAdjustment(pan: "10", roll: "5")
        clip.reorientAdjustment = reorient
        XCTAssertNotNil(clip.reorientAdjustment)
        XCTAssertEqual(clip.reorientAdjustment?.pan, "10")
        let adjustEl = clip.element.firstChildElement(named: "adjust-reorient")
        XCTAssertNotNil(adjustEl)
        XCTAssertEqual(adjustEl?.stringValue(forAttributeNamed: "pan"), "10")
    }

    func testClipColorConformAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipEl) else { XCTFail("Clip init"); return }
        let colorConform = FinalCutPro.FCPXML.ColorConformAdjustment(
            peakNitsOfPQSource: "1000",
            peakNitsOfSDRToPQSource: "100"
        )
        clip.colorConformAdjustment = colorConform
        XCTAssertEqual(clip.colorConformAdjustment?.conformType, .conformNone)
        clip.colorConformAdjustment = nil
        XCTAssertNil(clip.colorConformAdjustment)
    }

    func testClipStereo3DAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipEl) else { XCTFail("Clip init"); return }
        let stereo = FinalCutPro.FCPXML.Stereo3DAdjustment(convergence: "0.2", autoScale: false)
        clip.stereo3DAdjustment = stereo
        XCTAssertEqual(clip.stereo3DAdjustment?.convergence, "0.2")
        XCTAssertFalse(clip.stereo3DAdjustment?.autoScale ?? true)
    }

    func testClipRollingShutterAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipEl) else { XCTFail("Clip init"); return }
        let rs = FinalCutPro.FCPXML.RollingShutterAdjustment(isEnabled: true, amount: .high)
        clip.rollingShutterAdjustment = rs
        XCTAssertNotNil(clip.rollingShutterAdjustment)
        XCTAssertEqual(clip.rollingShutterAdjustment?.amount, .high)
        let adjustEl = clip.element.firstChildElement(named: "adjust-rollingShutter")
        XCTAssertEqual(adjustEl?.stringValue(forAttributeNamed: "amount"), "high")
    }

    func testClipConformAdjustmentRoundTrip() throws {
        let clipEl = FoundationXMLFactory().makeElement(name: "clip")
        clipEl.addAttribute(name: "ref", value: "r1")
        let videoEl = FoundationXMLFactory().makeElement(name: "video")
        clipEl.addChild(videoEl)
        guard let clip = FinalCutPro.FCPXML.Clip(element: clipEl) else { XCTFail("Clip init"); return }
        let conform = FinalCutPro.FCPXML.ConformAdjustment(type: .fill)
        clip.conformAdjustment = conform
        XCTAssertEqual(clip.conformAdjustment?.type, .fill)
        let adjustEl = clip.element.firstChildElement(named: "adjust-conform")
        XCTAssertEqual(adjustEl?.stringValue(forAttributeNamed: "type"), "fill")
    }

    // MARK: - Equatable Tests
    
    func testAdjustmentEquality() {
        let crop1 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop2 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop3 = FinalCutPro.FCPXML.CropAdjustment(mode: .trim)
        
        XCTAssertEqual(crop1, crop2)
        XCTAssertNotEqual(crop1, crop3)
        
        let transform1 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform2 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform3 = FinalCutPro.FCPXML.TransformAdjustment(rotation: 45)
        
        XCTAssertEqual(transform1, transform2)
        XCTAssertNotEqual(transform1, transform3)
    }
    
    // MARK: - Hashable Tests
    
    func testAdjustmentHashable() {
        let crop1 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        let crop2 = FinalCutPro.FCPXML.CropAdjustment(mode: .crop)
        
        XCTAssertEqual(crop1.hashValue, crop2.hashValue)
        
        let transform1 = FinalCutPro.FCPXML.TransformAdjustment()
        let transform2 = FinalCutPro.FCPXML.TransformAdjustment()
        
        XCTAssertEqual(transform1.hashValue, transform2.hashValue)
    }
}
