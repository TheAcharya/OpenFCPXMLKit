//
//  FCPXMLVersionConversionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML version conversion and save as .fcpxml / .fcpxmld.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Version conversion")
struct FCPXMLVersionConversionTests {
    private var service: FCPXMLService { FCPXMLService(versionConverter: FCPXMLVersionConverter()) }
    private let factory = FoundationXMLFactory()

    private func docVersion(_ doc: any OFKXMLDocument) -> String? {
        doc.rootElement()?.attribute(forName: "version")
    }

    // MARK: - Convert to version

    @Test("Convert to version 1.14 to 1.10")
    func convertToVersion_1_14_to_1_10() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        #expect(docVersion(doc) == "1.14")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        #expect(docVersion(converted) == "1.10")
    }

    @Test("Convert to version 1.10 to 1.14")
    func convertToVersion_1_10_to_1_14() throws {
        let doc = service.createFCPXMLDocument(version: "1.10")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_14)
        #expect(docVersion(converted) == "1.14")
    }

    @Test("Convert to version returns new document")
    func convertToVersion_ReturnsNewDocument() throws {
        let doc = service.createFCPXMLDocument(version: "1.13")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        let originalID = ObjectIdentifier(doc as AnyObject)
        let convertedID = ObjectIdentifier(converted as AnyObject)
        #expect(originalID != convertedID)
        #expect(docVersion(doc) == "1.13")
        #expect(docVersion(converted) == "1.10")
    }

    /// When converting to 1.10, elements not in the 1.10 DTD (e.g. adjust-colorConform from 1.11+) are stripped so FCP can import.
    @Test("Convert to version 1.10 strips adjust-colorConform")
    func convertToVersion_1_10_StripsAdjustColorConform() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let assetClip = factory.makeElement(name: "asset-clip")
        let adjustColorConform = factory.makeElement(name: "adjust-colorConform")
        for (k, v) in [("enabled", "1"), ("autoOrManual", "automatic"), ("conformType", "conformNone"), ("peakNitsOfPQSource", "1000"), ("peakNitsOfSDRToPQSource", "100")] as [(String, String)] {
            adjustColorConform.addAttribute(name: k, value: v)
        }
        assetClip.addChild(adjustColorConform)
        root.addChild(assetClip)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        #expect(docVersion(converted) == "1.10")

        let found = findElement(named: "adjust-colorConform", in: converted)
        #expect(found == nil, "adjust-colorConform must be stripped when converting to 1.10 for FCP DTD validation")
    }

    /// When converting to 1.12, adjust-stereo-3D (1.13+) is stripped.
    @Test("Convert to version 1.12 strips adjust-stereo-3D")
    func convertToVersion_1_12_StripsAdjustStereo3D() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let assetClip = factory.makeElement(name: "asset-clip")
        let adjustStereo = factory.makeElement(name: "adjust-stereo-3D")
        assetClip.addChild(adjustStereo)
        root.addChild(assetClip)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_12)
        #expect(docVersion(converted) == "1.12")
        let found = findElement(named: "adjust-stereo-3D", in: converted)
        #expect(found == nil, "adjust-stereo-3D must be stripped when converting to 1.12")
    }

    /// When converting to 1.12, hidden-clip-marker (1.13+) is stripped.
    @Test("Convert to version 1.12 strips hidden-clip-marker")
    func convertToVersion_1_12_StripsHiddenClipMarker() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let resources = root.firstChildElement(named: "resources") ?? factory.makeElement(name: "resources")
        if root.firstChildElement(named: "resources") == nil { root.addChild(resources) }
        let format = factory.makeElement(name: "format")
        format.addAttribute(name: "id", value: "f1")
        resources.addChild(format)
        let asset = factory.makeElement(name: "asset")
        let mediaRep = factory.makeElement(name: "media-rep")
        mediaRep.addAttribute(name: "src", value: "file:///tmp/x.mov")
        asset.addChild(mediaRep)
        resources.addChild(asset)
        let sequence = root.firstChildElement(named: "sequence") ?? factory.makeElement(name: "sequence")
        if root.firstChildElement(named: "sequence") == nil { root.addChild(sequence) }
        let spine = sequence.firstChildElement(named: "spine") ?? factory.makeElement(name: "spine")
        if sequence.firstChildElement(named: "spine") == nil { sequence.addChild(spine) }
        let clip = factory.makeElement(name: "clip")
        clip.addAttribute(name: "ref", value: "r1")
        clip.addAttribute(name: "offset", value: "0s")
        clip.addAttribute(name: "start", value: "0s")
        clip.addAttribute(name: "duration", value: "1s")
        let video = factory.makeElement(name: "video")
        video.addAttribute(name: "ref", value: "r1")
        clip.addChild(video)
        let hidden = factory.makeElement(name: "hidden-clip-marker")
        clip.addChild(hidden)
        spine.addChild(clip)
        let converted = try service.convertToVersion(doc, targetVersion: .v1_12)
        #expect(docVersion(converted) == "1.12")
        let found = findElement(named: "hidden-clip-marker", in: converted)
        #expect(found == nil, "hidden-clip-marker must be stripped when converting to 1.12")
    }

    // MARK: - Attribute stripping (backward compatibility with 1.5)

    /// When converting to 1.5, format heroEye and asset heroEyeOverride (1.13+) are stripped.
    @Test("Convert to version 1.5 strips format heroEye and asset heroEyeOverride")
    func convertToVersion_1_5_StripsFormatHeroEyeAndAssetHeroEyeOverride() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let resources = root.firstChildElement(named: "resources") ?? factory.makeElement(name: "resources")
        if root.firstChildElement(named: "resources") == nil { root.addChild(resources) }

        let format = factory.makeElement(name: "format")
        format.addAttribute(name: "id", value: "f1")
        format.addAttribute(name: "heroEye", value: "left")
        resources.addChild(format)

        let asset = factory.makeElement(name: "asset")
        asset.addAttribute(name: "id", value: "a1")
        asset.addAttribute(name: "heroEyeOverride", value: "right")
        let mediaRep = factory.makeElement(name: "media-rep")
        mediaRep.addAttribute(name: "src", value: "file:///tmp/test.mov")
        asset.addChild(mediaRep)
        resources.addChild(asset)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_5)
        #expect(docVersion(converted) == "1.5")

        let convFormat = findElement(named: "format", in: converted)
        #expect(convFormat != nil)
        #expect(convFormat?.attribute(forName: "heroEye") == nil, "heroEye must be stripped when converting to 1.5")

        let convAsset = findElement(named: "asset", in: converted)
        #expect(convAsset != nil)
        #expect(convAsset?.attribute(forName: "heroEyeOverride") == nil, "heroEyeOverride must be stripped when converting to 1.5")
    }

    /// When converting to 1.10, param auxValue and keyframe auxValue (1.11+) are stripped.
    @Test("Convert to version 1.10 strips param and keyframe auxValue")
    func convertToVersion_1_10_StripsParamAndKeyframeAuxValue() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let resources = root.firstChildElement(named: "resources") ?? factory.makeElement(name: "resources")
        if root.firstChildElement(named: "resources") == nil { root.addChild(resources) }

        let clip = factory.makeElement(name: "clip")
        let filterVideo = factory.makeElement(name: "filter-video")
        filterVideo.addAttribute(name: "ref", value: "r1")
        let param = factory.makeElement(name: "param")
        param.addAttribute(name: "name", value: "Amount")
        param.addAttribute(name: "value", value: "1.0")
        param.addAttribute(name: "auxValue", value: "linear")
        filterVideo.addChild(param)
        clip.addChild(filterVideo)
        root.addChild(clip)

        let keyframe = factory.makeElement(name: "keyframe")
        keyframe.addAttribute(name: "time", value: "0s")
        keyframe.addAttribute(name: "value", value: "0")
        keyframe.addAttribute(name: "auxValue", value: "extra")
        clip.addChild(keyframe)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        #expect(docVersion(converted) == "1.10")

        let convParam = findElement(named: "param", in: converted)
        #expect(convParam != nil)
        #expect(convParam?.attribute(forName: "auxValue") == nil, "param auxValue must be stripped when converting to 1.10")

        let convKeyframe = findElement(named: "keyframe", in: converted)
        #expect(convKeyframe != nil)
        #expect(convKeyframe?.attribute(forName: "auxValue") == nil, "keyframe auxValue must be stripped when converting to 1.10")
    }

    /// When converting to 1.13, param auxValue is kept (1.11+); when converting to 1.5, it is stripped.
    @Test("Convert to version keeps auxValue at 1.13 strips at 1.5")
    func convertToVersion_KeepsAuxValueAt1_13_StripsAt1_5() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        let root = try #require(doc.rootElement())
        let param = factory.makeElement(name: "param")
        param.addAttribute(name: "name", value: "Gain")
        param.addAttribute(name: "value", value: "0.8")
        param.addAttribute(name: "auxValue", value: "dB")
        root.addChild(param)

        let to13 = try service.convertToVersion(doc, targetVersion: .v1_13)
        let param13 = findElement(named: "param", in: to13)
        #expect(param13?.attribute(forName: "auxValue") == "dB", "param auxValue kept at 1.13")

        let to5 = try service.convertToVersion(doc, targetVersion: .v1_5)
        let param5 = findElement(named: "param", in: to5)
        #expect(param5?.attribute(forName: "auxValue") == nil, "param auxValue stripped at 1.5")
    }

    private func findElement(named name: String, in document: any OFKXMLDocument) -> (any OFKXMLElement)? {
        guard let root = document.rootElement() else { return nil }
        return findElement(named: name, in: root)
    }

    private func findElement(named name: String, in element: any OFKXMLElement) -> (any OFKXMLElement)? {
        if element.name == name { return element }
        for child in element.childElements {
            if let match = findElement(named: name, in: child) { return match }
        }
        return nil
    }

    // MARK: - Edge Cases

    @Test("Convert to version document always has root")
    func convertToVersion_DocumentAlwaysHasRoot() throws {
        // Verify that converted documents always have a root element
        let doc = service.createFCPXMLDocument(version: "1.14")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)

        // Converted document should always have a root element
        let root = converted.rootElement()
        #expect(root != nil, "Converted document should always have a root element")
        #expect(root?.name == "fcpxml", "Root element should be 'fcpxml'")
        #expect(docVersion(converted) == "1.10", "Version should be set correctly")
    }

    @Test("Convert to version stripping works with valid root")
    func convertToVersion_StrippingWorksWithValidRoot() throws {
        // Verify that element stripping works when root exists
        let doc = service.createFCPXMLDocument(version: "1.14")

        let root = try #require(doc.rootElement())

        let resources = root.firstChildElement(named: "resources") ?? factory.makeElement(name: "resources")
        if root.firstChildElement(named: "resources") == nil {
            root.addChild(resources)
        }

        let asset = factory.makeElement(name: "asset")
        asset.addAttribute(name: "id", value: "r1")
        asset.addAttribute(name: "name", value: "Test")
        let adjustColorConform = factory.makeElement(name: "adjust-colorConform")
        adjustColorConform.addAttribute(name: "enabled", value: "1")
        asset.addChild(adjustColorConform)
        resources.addChild(asset)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)

        // Verify adjust-colorConform was stripped
        let convertedRoot = try #require(converted.rootElement())

        // Search for adjust-colorConform - it should not exist
        let found = findElement(named: "adjust-colorConform", in: convertedRoot)
        #expect(found == nil, "adjust-colorConform should be stripped when converting to 1.10")
    }

    // MARK: - Save as .fcpxml

    @Test("Save as FCPXML")
    func saveAsFCPXML() throws {
        let doc = try service.convertToVersion(service.createFCPXMLDocument(version: "1.14"), targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("VersionConversionTests_\(UUID().uuidString).fcpxml")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try service.saveAsFCPXML(doc, to: fileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        let data = try Data(contentsOf: fileURL)
        let loaded = try factory.makeDocument(data: data)
        #expect(docVersion(loaded) == "1.10")
    }

    // MARK: - Save as .fcpxmld (1.10+ only)

    @Test("Save as bundle when version 1.10 succeeds")
    func saveAsBundle_WhenVersion1_10_Succeeds() throws {
        let doc = try service.convertToVersion(service.createFCPXMLDocument(version: "1.14"), targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VersionConversionTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let bundleURL = try service.saveAsBundle(doc, to: tempDir, bundleName: "TestProject")
        #expect(FileManager.default.fileExists(atPath: bundleURL.path))
        let infoFcpxml = bundleURL.appendingPathComponent("Info.fcpxml")
        let infoPlist = bundleURL.appendingPathComponent("Info.plist")
        #expect(FileManager.default.fileExists(atPath: infoFcpxml.path))
        #expect(FileManager.default.fileExists(atPath: infoPlist.path))
        let data = try Data(contentsOf: infoFcpxml)
        let loaded = try factory.makeDocument(data: data)
        #expect(docVersion(loaded) == "1.10")
    }

    @Test("Save as bundle when version below 1.10 throws")
    func saveAsBundle_WhenVersionBelow1_10_Throws() throws {
        let doc = service.createFCPXMLDocument(version: "1.9")
        let tempDir = FileManager.default.temporaryDirectory
        do {
            _ = try service.saveAsBundle(doc, to: tempDir, bundleName: "Test")
            Issue.record("expected throw")
        } catch let error as FCPXMLBundleExportError {
            if case .bundleRequiresVersion1_10OrHigher(let v) = error {
                #expect(v == "1.9")
            } else {
                Issue.record("Expected bundleRequiresVersion1_10OrHigher, got \(error)")
            }
        }
    }

    // MARK: - Async

    @Test("Convert to version async")
    func convertToVersionAsync() async throws {
        let doc = await service.createFCPXMLDocument(version: "1.14")
        let converted = try await service.convertToVersion(doc, targetVersion: .v1_10)
        #expect(docVersion(converted) == "1.10")
    }

    @Test("Save as bundle async")
    func saveAsBundleAsync() async throws {
        let doc = await service.createFCPXMLDocument(version: "1.14")
        let converted = try await service.convertToVersion(doc, targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VersionConversionTests_async_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let bundleURL = try await service.saveAsBundle(converted, to: tempDir, bundleName: "AsyncProject")
        #expect(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("Info.fcpxml").path))
    }
}

