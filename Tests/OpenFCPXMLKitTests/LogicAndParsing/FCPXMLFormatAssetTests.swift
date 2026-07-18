//
//  FCPXMLFormatAssetTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for Format and Asset resource models (FCPXML 1.13+ heroEye / heroEyeOverride, Asset mediaReps).
//	Backward compatible with 1.5: heroEye and heroEyeOverride are optional; mediaReps supports single or multiple media-rep.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Format and Asset resources")
struct FCPXMLFormatAssetTests {

    private let factory = FoundationXMLFactory()

    // MARK: - Format heroEye (1.13+)

    @Test("Format heroEye round trip")
    func formatHeroEyeRoundTrip() {
        let format = FinalCutPro.FCPXML.Format(id: "f1")
        #expect(format.heroEye == nil)

        format.heroEye = "left"
        #expect(format.heroEye == "left")
        #expect(format.element.stringValue(forAttributeNamed: "heroEye") == "left")

        format.heroEye = "right"
        #expect(format.heroEye == "right")

        format.heroEye = nil
        #expect(format.heroEye == nil)
        #expect(format.element.stringValue(forAttributeNamed: "heroEye") == nil)
    }

    @Test("Format init with heroEye")
    func formatInitWithHeroEye() {
        let format = FinalCutPro.FCPXML.Format(
            id: "f1",
            name: "Stereo",
            heroEye: "right"
        )
        #expect(format.heroEye == "right")
    }

    @Test("Format from element with heroEye")
    func formatFromElementWithHeroEye() throws {
        let formatEl = factory.makeElement(name: "format")
        formatEl.addAttribute(name: "id", value: "f1")
        formatEl.addAttribute(name: "heroEye", value: "left")
        let format = try #require(FinalCutPro.FCPXML.Format(element: formatEl))
        #expect(format.heroEye == "left")
    }

    // MARK: - Asset heroEyeOverride (1.13+)

    @Test("Asset heroEyeOverride round trip")
    func assetHeroEyeOverrideRoundTrip() {
        let asset = FinalCutPro.FCPXML.Asset(id: "a1")
        asset.mediaRep = FinalCutPro.FCPXML.MediaRep(src: URL(fileURLWithPath: "/tmp/test.mov"))
        #expect(asset.heroEyeOverride == nil)

        asset.heroEyeOverride = "left"
        #expect(asset.heroEyeOverride == "left")
        #expect(asset.element.stringValue(forAttributeNamed: "heroEyeOverride") == "left")

        asset.heroEyeOverride = "right"
        #expect(asset.heroEyeOverride == "right")

        asset.heroEyeOverride = nil
        #expect(asset.heroEyeOverride == nil)
    }

    @Test("Asset init with heroEyeOverride")
    func assetInitWithHeroEyeOverride() {
        let asset = FinalCutPro.FCPXML.Asset(
            id: "a1",
            heroEyeOverride: "right",
            mediaRep: FinalCutPro.FCPXML.MediaRep(src: URL(fileURLWithPath: "/tmp/v.mov"))
        )
        #expect(asset.heroEyeOverride == "right")
    }

    @Test("Asset from element with heroEyeOverride")
    func assetFromElementWithHeroEyeOverride() throws {
        let assetEl = factory.makeElement(name: "asset")
        assetEl.addAttribute(name: "id", value: "a1")
        assetEl.addAttribute(name: "heroEyeOverride", value: "right")
        let mediaRepEl = factory.makeElement(name: "media-rep")
        mediaRepEl.addAttribute(name: "src", value: "file:///tmp/v.mov")
        assetEl.addChild(mediaRepEl)
        let asset = try #require(FinalCutPro.FCPXML.Asset(element: assetEl))
        #expect(asset.heroEyeOverride == "right")
    }

    // MARK: - Asset mediaReps (multiple media-rep)

    @Test("Asset mediaReps round trip")
    func assetMediaRepsRoundTrip() {
        let asset = FinalCutPro.FCPXML.Asset(id: "a1")
        let rep1 = FinalCutPro.FCPXML.MediaRep(kind: .originalMedia, src: URL(fileURLWithPath: "/tmp/original.mov"))
        let rep2 = FinalCutPro.FCPXML.MediaRep(kind: .proxyMedia, src: URL(fileURLWithPath: "/tmp/proxy.mov"))
        asset.mediaReps = [rep1, rep2]
        #expect(asset.mediaReps.count == 2)
        #expect(asset.mediaReps[0].kind == .originalMedia)
        #expect(asset.mediaReps[1].kind == .proxyMedia)
        let mediaRepElements = asset.element.childElements.filter { $0.name == "media-rep" }
        #expect(mediaRepElements.count == 2)
    }

    @Test("Asset mediaRep backward compatibility")
    func assetMediaRepBackwardCompatibility() {
        let asset = FinalCutPro.FCPXML.Asset(id: "a1")
        asset.mediaRep = FinalCutPro.FCPXML.MediaRep(src: URL(fileURLWithPath: "/tmp/single.mov"))
        #expect(asset.mediaReps.count == 1)
        #expect(asset.mediaRep.src?.path == "/tmp/single.mov")
        let proxy = FinalCutPro.FCPXML.MediaRep(kind: .proxyMedia, src: URL(fileURLWithPath: "/tmp/proxy.mov"))
        asset.mediaReps = asset.mediaReps + [proxy]
        #expect(asset.mediaReps.count == 2)
        #expect(asset.mediaRep.src?.path == "/tmp/single.mov")
    }

    @Test("Asset init with mediaReps")
    func assetInitWithMediaReps() {
        let rep1 = FinalCutPro.FCPXML.MediaRep(kind: .originalMedia, src: URL(fileURLWithPath: "/tmp/o.mov"))
        let rep2 = FinalCutPro.FCPXML.MediaRep(kind: .proxyMedia, src: URL(fileURLWithPath: "/tmp/p.mov"))
        let asset = FinalCutPro.FCPXML.Asset(id: "a2", mediaReps: [rep1, rep2])
        #expect(asset.mediaReps.count == 2)
        #expect(asset.mediaReps[0].kind == .originalMedia)
        #expect(asset.mediaReps[1].kind == .proxyMedia)
    }

    @Test("Asset from element with multiple mediaReps")
    func assetFromElementWithMultipleMediaReps() throws {
        let assetEl = factory.makeElement(name: "asset")
        assetEl.addAttribute(name: "id", value: "a3")
        let rep1 = factory.makeElement(name: "media-rep")
        rep1.addAttribute(name: "kind", value: "original-media")
        rep1.addAttribute(name: "src", value: "file:///tmp/orig.mov")
        let rep2 = factory.makeElement(name: "media-rep")
        rep2.addAttribute(name: "kind", value: "proxy-media")
        rep2.addAttribute(name: "src", value: "file:///tmp/proxy.mov")
        assetEl.addChild(rep1)
        assetEl.addChild(rep2)
        let asset = try #require(FinalCutPro.FCPXML.Asset(element: assetEl))
        #expect(asset.mediaReps.count == 2)
        #expect(asset.mediaReps[0].kind == .originalMedia)
        #expect(asset.mediaReps[1].kind == .proxyMedia)
    }
}
