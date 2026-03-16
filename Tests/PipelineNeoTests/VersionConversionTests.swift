//
//  VersionConversionTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML version conversion and save as .fcpxml / .fcpxmld.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class VersionConversionTests: XCTestCase, @unchecked Sendable {

    private var service: FCPXMLService!
    private var converter: FCPXMLVersionConverter!
    private let factory = FoundationXMLFactory()

    override func setUpWithError() throws {
        try super.setUpWithError()
        converter = FCPXMLVersionConverter()
        service = FCPXMLService(versionConverter: converter)
    }

    override func tearDownWithError() throws {
        service = nil
        converter = nil
        try super.tearDownWithError()
    }

    private func docVersion(_ doc: any PNXMLDocument) -> String? {
        doc.rootElement()?.attribute(forName: "version")
    }

    // MARK: - Convert to version

    func testConvertToVersion_1_14_to_1_10() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        XCTAssertEqual(docVersion(doc), "1.14")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        XCTAssertEqual(docVersion(converted), "1.10")
    }

    func testConvertToVersion_1_10_to_1_14() throws {
        let doc = service.createFCPXMLDocument(version: "1.10")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_14)
        XCTAssertEqual(docVersion(converted), "1.14")
    }

    func testConvertToVersion_ReturnsNewDocument() throws {
        let doc = service.createFCPXMLDocument(version: "1.13")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        XCTAssertNotIdentical(doc, converted)
        XCTAssertEqual(docVersion(doc), "1.13")
        XCTAssertEqual(docVersion(converted), "1.10")
    }

    /// When converting to 1.10, elements not in the 1.10 DTD (e.g. adjust-colorConform from 1.11+) are stripped so FCP can import.
    func testConvertToVersion_1_10_StripsAdjustColorConform() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else {
            XCTFail("No root")
            return
        }
        let assetClip = factory.makeElement(name: "asset-clip")
        let adjustColorConform = factory.makeElement(name: "adjust-colorConform")
        for (k, v) in [("enabled", "1"), ("autoOrManual", "automatic"), ("conformType", "conformNone"), ("peakNitsOfPQSource", "1000"), ("peakNitsOfSDRToPQSource", "100")] as [(String, String)] {
            adjustColorConform.addAttribute(name: k, value: v)
        }
        assetClip.addChild(adjustColorConform)
        root.addChild(assetClip)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)
        XCTAssertEqual(docVersion(converted), "1.10")

        let found = findElement(named: "adjust-colorConform", in: converted)
        XCTAssertNil(found, "adjust-colorConform must be stripped when converting to 1.10 for FCP DTD validation")
    }

    /// When converting to 1.12, adjust-stereo-3D (1.13+) is stripped.
    func testConvertToVersion_1_12_StripsAdjustStereo3D() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else {
            XCTFail("No root")
            return
        }
        let assetClip = factory.makeElement(name: "asset-clip")
        let adjustStereo = factory.makeElement(name: "adjust-stereo-3D")
        assetClip.addChild(adjustStereo)
        root.addChild(assetClip)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_12)
        XCTAssertEqual(docVersion(converted), "1.12")
        let found = findElement(named: "adjust-stereo-3D", in: converted)
        XCTAssertNil(found, "adjust-stereo-3D must be stripped when converting to 1.12")
    }

    /// When converting to 1.12, hidden-clip-marker (1.13+) is stripped.
    func testConvertToVersion_1_12_StripsHiddenClipMarker() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else { XCTFail("No root"); return }
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
        XCTAssertEqual(docVersion(converted), "1.12")
        let found = findElement(named: "hidden-clip-marker", in: converted)
        XCTAssertNil(found, "hidden-clip-marker must be stripped when converting to 1.12")
    }

    // MARK: - Attribute stripping (backward compatibility with 1.5)

    /// When converting to 1.5, format heroEye and asset heroEyeOverride (1.13+) are stripped.
    func testConvertToVersion_1_5_StripsFormatHeroEyeAndAssetHeroEyeOverride() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else { XCTFail("No root"); return }
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
        XCTAssertEqual(docVersion(converted), "1.5")

        let convFormat = findElement(named: "format", in: converted)
        XCTAssertNotNil(convFormat)
        XCTAssertNil(convFormat?.attribute(forName: "heroEye"), "heroEye must be stripped when converting to 1.5")

        let convAsset = findElement(named: "asset", in: converted)
        XCTAssertNotNil(convAsset)
        XCTAssertNil(convAsset?.attribute(forName: "heroEyeOverride"), "heroEyeOverride must be stripped when converting to 1.5")
    }

    /// When converting to 1.10, param auxValue and keyframe auxValue (1.11+) are stripped.
    func testConvertToVersion_1_10_StripsParamAndKeyframeAuxValue() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else { XCTFail("No root"); return }
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
        XCTAssertEqual(docVersion(converted), "1.10")

        let convParam = findElement(named: "param", in: converted)
        XCTAssertNotNil(convParam)
        XCTAssertNil(convParam?.attribute(forName: "auxValue"), "param auxValue must be stripped when converting to 1.10")

        let convKeyframe = findElement(named: "keyframe", in: converted)
        XCTAssertNotNil(convKeyframe)
        XCTAssertNil(convKeyframe?.attribute(forName: "auxValue"), "keyframe auxValue must be stripped when converting to 1.10")
    }

    /// When converting to 1.13, param auxValue is kept (1.11+); when converting to 1.5, it is stripped.
    func testConvertToVersion_KeepsAuxValueAt1_13_StripsAt1_5() throws {
        let doc = service.createFCPXMLDocument(version: "1.14")
        guard let root = doc.rootElement() else { XCTFail("No root"); return }
        let param = factory.makeElement(name: "param")
        param.addAttribute(name: "name", value: "Gain")
        param.addAttribute(name: "value", value: "0.8")
        param.addAttribute(name: "auxValue", value: "dB")
        root.addChild(param)

        let to13 = try service.convertToVersion(doc, targetVersion: .v1_13)
        let param13 = findElement(named: "param", in: to13)
        XCTAssertEqual(param13?.attribute(forName: "auxValue"), "dB", "param auxValue kept at 1.13")

        let to5 = try service.convertToVersion(doc, targetVersion: .v1_5)
        let param5 = findElement(named: "param", in: to5)
        XCTAssertNil(param5?.attribute(forName: "auxValue"), "param auxValue stripped at 1.5")
    }

    private func findElement(named name: String, in document: any PNXMLDocument) -> (any PNXMLElement)? {
        guard let root = document.rootElement() else { return nil }
        return findElement(named: name, in: root)
    }

    private func findElement(named name: String, in element: any PNXMLElement) -> (any PNXMLElement)? {
        if element.name == name { return element }
        for child in element.childElements {
            if let match = findElement(named: name, in: child) { return match }
        }
        return nil
    }

    // MARK: - Edge Cases

    func testConvertToVersion_DocumentAlwaysHasRoot() throws {
        // Verify that converted documents always have a root element
        let doc = service.createFCPXMLDocument(version: "1.14")
        let converted = try service.convertToVersion(doc, targetVersion: .v1_10)

        // Converted document should always have a root element
        let root = converted.rootElement()
        XCTAssertNotNil(root, "Converted document should always have a root element")
        XCTAssertEqual(root?.name, "fcpxml", "Root element should be 'fcpxml'")
        XCTAssertEqual(docVersion(converted), "1.10", "Version should be set correctly")
    }

    func testConvertToVersion_StrippingWorksWithValidRoot() throws {
        // Verify that element stripping works when root exists
        let doc = service.createFCPXMLDocument(version: "1.14")

        guard let root = doc.rootElement() else {
            XCTFail("Document should have root element")
            return
        }

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
        let convertedRoot = converted.rootElement()
        XCTAssertNotNil(convertedRoot, "Converted document should have root")

        // Search for adjust-colorConform - it should not exist
        let found = findElement(named: "adjust-colorConform", in: convertedRoot!)
        XCTAssertNil(found, "adjust-colorConform should be stripped when converting to 1.10")
    }

    // MARK: - Save as .fcpxml

    func testSaveAsFCPXML() throws {
        let doc = try service.convertToVersion(service.createFCPXMLDocument(version: "1.14"), targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("VersionConversionTests_\(UUID().uuidString).fcpxml")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try service.saveAsFCPXML(doc, to: fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        let data = try Data(contentsOf: fileURL)
        let loaded = try factory.makeDocument(data: data)
        XCTAssertEqual(docVersion(loaded), "1.10")
    }

    // MARK: - Save as .fcpxmld (1.10+ only)

    func testSaveAsBundle_WhenVersion1_10_Succeeds() throws {
        let doc = try service.convertToVersion(service.createFCPXMLDocument(version: "1.14"), targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VersionConversionTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let bundleURL = try service.saveAsBundle(doc, to: tempDir, bundleName: "TestProject")
        XCTAssertTrue(FileManager.default.fileExists(atPath: bundleURL.path))
        let infoFcpxml = bundleURL.appendingPathComponent("Info.fcpxml")
        let infoPlist = bundleURL.appendingPathComponent("Info.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: infoFcpxml.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: infoPlist.path))
        let data = try Data(contentsOf: infoFcpxml)
        let loaded = try factory.makeDocument(data: data)
        XCTAssertEqual(docVersion(loaded), "1.10")
    }

    func testSaveAsBundle_WhenVersionBelow1_10_Throws() throws {
        let doc = service.createFCPXMLDocument(version: "1.9")
        let tempDir = FileManager.default.temporaryDirectory
        do {
            _ = try service.saveAsBundle(doc, to: tempDir, bundleName: "Test")
            XCTFail("Expected bundleRequiresVersion1_10OrHigher")
        } catch let error as FCPXMLBundleExportError {
            if case .bundleRequiresVersion1_10OrHigher(let v) = error {
                XCTAssertEqual(v, "1.9")
            } else {
                XCTFail("Expected bundleRequiresVersion1_10OrHigher, got \(error)")
            }
        }
    }

    // MARK: - Async

    func testConvertToVersionAsync() async throws {
        let doc = await service.createFCPXMLDocument(version: "1.14")
        let converted = try await service.convertToVersion(doc, targetVersion: .v1_10)
        XCTAssertEqual(docVersion(converted), "1.10")
    }

    func testSaveAsBundleAsync() async throws {
        let doc = await service.createFCPXMLDocument(version: "1.14")
        let converted = try await service.convertToVersion(doc, targetVersion: .v1_10)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VersionConversionTests_async_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let bundleURL = try await service.saveAsBundle(converted, to: tempDir, bundleName: "AsyncProject")
        XCTAssertTrue(FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("Info.fcpxml").path))
    }
}
