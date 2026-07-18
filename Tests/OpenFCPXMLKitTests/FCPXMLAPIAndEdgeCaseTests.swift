//
//  FCPXMLAPIAndEdgeCaseTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	API edge case tests for file loading, logging, and validation.
//

import Foundation
import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("API and edge cases")
struct FCPXMLAPIAndEdgeCaseTests {

    // MARK: - FCPXMLFileLoader async load(from:)

    @Test("FCPXML file loader async load from URL")
    func fcpxmlFileLoaderAsyncLoadFromURL() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".fcpxml")
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.14">
            <resources/>
        </fcpxml>
        """
        try xml.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        let loader = FCPXMLFileLoader()
        let doc = try await loader.load(from: temp)
        #expect(doc.rootElement() != nil)
        #expect(doc.rootElement()?.name == "fcpxml")
    }

    @Test("FCPXML file loader async load throws for missing file")
    func fcpxmlFileLoaderAsyncLoadThrowsForMissingFile() async {
        let url = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).fcpxml")
        let loader = FCPXMLFileLoader()
        do {
            _ = try await loader.load(from: url)
            Issue.record("expected throw")
        } catch let err as FCPXMLLoadError {
            switch err {
            case .notAFile: break
            case .readFailed: break
            }
        } catch is FCPXMLError {
            // Parse failures surface as FCPXMLError.parsingFailed
        } catch {
            Issue.record("Expected FCPXMLLoadError or FCPXMLError, got \(error)")
        }
    }

    // MARK: - Logger injection

    @Test("FCPXML service with NoOp logger parses successfully")
    func fcpxmlServiceWithNoOpLoggerParsesSuccessfully() throws {
        let logger = NoOpServiceLogger()
        let service = FCPXMLService(logger: logger)
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.14"><resources/></fcpxml>
        """
        let data = try #require(xml.data(using: .utf8))
        let doc = try service.parseFCPXML(from: data)
        #expect(doc.rootElement()?.name == "fcpxml")
    }

    @Test("FCPXML service with Print logger parses successfully")
    func fcpxmlServiceWithPrintLoggerParsesSuccessfully() throws {
        let logger = PrintServiceLogger(minimumLevel: .error)
        let service = FCPXMLService(logger: logger)
        let xml = "<?xml version=\"1.0\"?><fcpxml version=\"1.14\"><resources/></fcpxml>"
        let data = try #require(xml.data(using: .utf8))
        let doc = try service.parseFCPXML(from: data)
        #expect(doc.rootElement()?.name == "fcpxml")
    }

    @Test("Create custom service with logger")
    func createCustomServiceWithLogger() throws {
        let logger = NoOpServiceLogger()
        let service = ModularUtilities.createCustomService(
            parser: FCPXMLParser(),
            timecodeConverter: TimecodeConverter(),
            documentManager: XMLDocumentManager(),
            errorHandler: ErrorHandler(),
            logger: logger
        )
        let data = try #require("<fcpxml version=\"1.14\"><resources/></fcpxml>".data(using: .utf8))
        let doc = try service.parseFCPXML(from: data)
        #expect(doc.rootElement() != nil)
    }

    // MARK: - Edge cases: invalid / empty input

    @Test("Parse empty data throws")
    func parseEmptyDataThrows() {
        let service = FCPXMLService()
        let data = Data()
        #expect(throws: (any Error).self) {
            try service.parseFCPXML(from: data)
        }
    }

    @Test("Parse invalid XML throws")
    func parseInvalidXMLThrows() throws {
        let service = FCPXMLService()
        let data = try #require("not xml at all".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try service.parseFCPXML(from: data)
        }
    }

    @Test("Parse malformed XML throws")
    func parseMalformedXMLThrows() throws {
        let service = FCPXMLService()
        let data = try #require("<fcpxml version=\"1.14\"><resources".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try service.parseFCPXML(from: data)
        }
    }

    @Test("Load document from invalid path throws correct error")
    func loadDocumentFromInvalidPathThrowsCorrectError() {
        let loader = FCPXMLFileLoader()
        let url = URL(fileURLWithPath: "/nonexistent/file.fcpxml")
        do {
            _ = try loader.loadDocument(from: url)
            Issue.record("expected throw")
        } catch {
            #expect(error is FCPXMLLoadError)
        }
    }

    @Test("Resolve FCPXML file URL for nonexistent path throws")
    func resolveFCPXMLFileURLForNonexistentPathThrows() {
        let loader = FCPXMLFileLoader()
        let url = URL(fileURLWithPath: "/does/not/exist.fcpxml")
        #expect(throws: FCPXMLLoadError.self) {
            try loader.resolveFCPXMLFileURL(from: url)
        }
    }

    // MARK: - FCPXML creation (smoke)

    @Test("Create FCPXML document all versions")
    func createFCPXMLDocumentAllVersions() throws {
        let service = FCPXMLService()
        for v in ["1.5", "1.10", "1.14"] {
            let doc = service.createFCPXMLDocument(version: v)
            #expect(doc.rootElement()?.attribute(forName: "version") == v)
            #expect(doc.rootElement() != nil)
        }
    }

    // MARK: - ValidationResult / ValidationError

    @Test("Validation result with errors")
    func validationResultWithErrors() {
        let err = ValidationError(type: .missingAssetReference, message: "Missing ref", context: ["id": "r1"])
        let result = ValidationResult(errors: [err], warnings: [])
        #expect(!result.isValid)
        #expect(result.errors.count == 1)
        #expect(result.errors.first?.message == "Missing ref")
    }

    @Test("Validation warning")
    func validationWarning() {
        let warning = ValidationWarning(type: .missingMetadata, message: "Deprecated attribute")
        #expect(!warning.message.isEmpty)
    }

    // MARK: - HiddenClipMarker (1.13+, marker_item)

    @Test("Hidden clip marker model and annotation elements")
    func hiddenClipMarkerModelAndAnnotationElements() {
        let clip = FoundationXMLFactory().makeElement(name: "clip")
        clip.addAttribute(name: "ref", value: "r1")
        clip.addAttribute(name: "offset", value: "0s")
        clip.addAttribute(name: "start", value: "0s")
        clip.addAttribute(name: "duration", value: "1s")
        let video = FoundationXMLFactory().makeElement(name: "video")
        video.addAttribute(name: "ref", value: "r1")
        clip.addChild(video)
        let hiddenEl = FoundationXMLFactory().makeElement(name: "hidden-clip-marker")
        clip.addChild(hiddenEl)
        let marker = FinalCutPro.FCPXML.HiddenClipMarker(element: hiddenEl)
        #expect(marker != nil)
        #expect(marker?.element.name == "hidden-clip-marker")
        let annotations = clip.fcpxAnnotations
        #expect(annotations.contains { $0.name == "hidden-clip-marker" })
        let created = FinalCutPro.FCPXML.HiddenClipMarker()
        #expect(created.element.name == "hidden-clip-marker")
    }

    // MARK: - LiveDrawing (1.11+, live-drawing story element)

    @Test("Live drawing model init and attributes")
    func liveDrawingModelInitAndAttributes() {
        let ld = FinalCutPro.FCPXML.LiveDrawing(
            role: "video",
            dataLocator: "r1",
            animationType: "draw",
            lane: 1,
            offset: nil,
            name: "Sketch",
            start: Fraction(0, 1),
            duration: Fraction(5, 1),
            enabled: true,
            note: nil
        )
        #expect(ld.element.name == "live-drawing")
        #expect(ld.role == "video")
        #expect(ld.dataLocator == "r1")
        #expect(ld.animationType == "draw")
        #expect(ld.name == "Sketch")
        #expect(ld.duration == Fraction(5, 1))
    }

    @Test("Live drawing from element and AnyTimeline round trip")
    func liveDrawingFromElementAndAnyTimelineRoundTrip() throws {
        let el = FoundationXMLFactory().makeElement(name: "live-drawing")
        el.addAttribute(name: "name", value: "Draw")
        el.addAttribute(name: "duration", value: "3s")
        el.addAttribute(name: "role", value: "video")
        let ld = try #require(FinalCutPro.FCPXML.LiveDrawing(element: el))
        #expect(ld.name == "Draw")
        #expect(ld.role == "video")
        let anyTimeline = try #require(FinalCutPro.FCPXML.AnyTimeline(element: el))
        if case .liveDrawing(let model) = anyTimeline {
            #expect(model.name == "Draw")
            #expect(model.element === ld.element)
        } else {
            Issue.record("Expected AnyTimeline.liveDrawing, got \(anyTimeline)")
        }
    }
}

