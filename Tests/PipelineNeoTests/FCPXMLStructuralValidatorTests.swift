//
//  FCPXMLStructuralValidatorTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXMLStructuralValidator — cross-platform structural validation.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class FCPXMLStructuralValidatorTests: XCTestCase {

    private let factory = FoundationXMLFactory()
    private let validator = FCPXMLStructuralValidator()

    // MARK: - Helpers

    /// Creates a well-formed FCPXML document with resources and a project.
    private func makeValidDocument(version: String = "1.10") -> any PNXMLDocument {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: version)

        let resources = factory.makeElement(name: "resources")
        let asset = factory.makeElement(name: "asset")
        asset.addAttribute(name: "id", value: "r1")
        asset.addAttribute(name: "src", value: "file:///media/clip.mov")
        resources.addChild(asset)
        root.addChild(resources)

        let project = factory.makeElement(name: "project")
        project.addAttribute(name: "name", value: "Test Project")
        let sequence = factory.makeElement(name: "sequence")
        let spine = factory.makeElement(name: "spine")
        let clip = factory.makeElement(name: "asset-clip")
        clip.addAttribute(name: "ref", value: "r1")
        clip.addAttribute(name: "name", value: "Test Clip")
        spine.addChild(clip)
        sequence.addChild(spine)
        project.addChild(sequence)
        root.addChild(project)

        let doc = factory.makeDocument()
        doc.setRootElement(root)
        return doc
    }

    // MARK: - Valid Document

    func testValidFCPXMLPasses() {
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        XCTAssertTrue(result.isValid, "Well-formed FCPXML should pass. Errors: \(result.detailedDescription)")
        // Should still have the structural-only warning
        XCTAssertTrue(result.warnings.contains { $0.type == .structuralValidationOnly })
    }

    func testValidDocumentWithLibraryPasses() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.11")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "library"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertTrue(result.isValid, "FCPXML with library should pass. Errors: \(result.detailedDescription)")
    }

    func testValidDocumentWithEventPasses() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.9")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "event"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertTrue(result.isValid, "FCPXML with event should pass. Errors: \(result.detailedDescription)")
    }

    // MARK: - Missing Root Element

    func testMissingRootElementFails() {
        let doc = factory.makeDocument()
        doc.setRootElement(factory.makeElement(name: "notfcpxml"))

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("fcpxml")
        })
    }

    func testEmptyDocumentFails() {
        let xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><wrongroot/>"
        guard let doc = try? factory.makeDocument(xmlString: xmlString) else {
            XCTFail("Failed to parse XML")
            return
        }

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.type == .missingRequiredElement })
    }

    // MARK: - Missing Version Attribute

    func testMissingVersionAttributeFails() {
        let root = factory.makeElement(name: "fcpxml")
        // No version attribute
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .invalidAttributeValue && $0.message.contains("version")
        })
    }

    // MARK: - Invalid Version Attribute

    func testEmptyVersionAttributeFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .invalidAttributeValue && $0.message.contains("empty")
        })
    }

    func testNonNumericVersionFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "abc")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .invalidAttributeValue && $0.message.contains("invalid")
        }, "Non-numeric version should be flagged. Errors: \(result.errors)")
    }

    func testKnownVersionPasses() {
        // All known versions should pass structural validation
        for version in ["1.6", "1.10", "1.13", "1.14"] {
            let root = factory.makeElement(name: "fcpxml")
            root.addAttribute(name: "version", value: version)
            root.addChild(factory.makeElement(name: "resources"))
            root.addChild(factory.makeElement(name: "project"))
            let doc = factory.makeDocument()
            doc.setRootElement(root)

            let result = validator.validate(doc)
            XCTAssertTrue(result.isValid, "Version \(version) should be valid. Errors: \(result.detailedDescription)")
        }
    }

    func testFutureNumericVersionPasses() {
        // An unknown but properly formatted version (e.g., "2.0") should pass
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "2.0")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertTrue(result.isValid, "Future numeric version should be accepted. Errors: \(result.detailedDescription)")
    }

    // MARK: - Missing Resources

    func testMissingResourcesFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        // No resources element
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("resources")
        })
    }

    // MARK: - Missing Content Element

    func testMissingContentElementFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        root.addChild(factory.makeElement(name: "resources"))
        // No library, event, or project
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("library, event, or project")
        })
    }

    // MARK: - Unknown Element Names

    func testUnknownElementNameDetected() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        root.addChild(factory.makeElement(name: "resources"))
        let project = factory.makeElement(name: "project")
        let fakeElement = factory.makeElement(name: "fake-element")
        project.addChild(fakeElement)
        root.addChild(project)
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains {
            $0.type == .unknownElementName && $0.message.contains("fake-element")
        })
    }

    func testMultipleUnknownElementsDetected() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        root.addChild(factory.makeElement(name: "resources"))
        let project = factory.makeElement(name: "project")
        project.addChild(factory.makeElement(name: "bogus-one"))
        project.addChild(factory.makeElement(name: "bogus-two"))
        root.addChild(project)
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        let unknownErrors = result.errors.filter { $0.type == .unknownElementName }
        XCTAssertEqual(unknownErrors.count, 2, "Should detect both unknown elements")
    }

    func testAllKnownElementsPass() {
        // A document with only known element names should have no unknownElementName errors
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        let unknownErrors = result.errors.filter { $0.type == .unknownElementName }
        XCTAssertTrue(unknownErrors.isEmpty, "Known elements should not trigger unknown element errors")
    }

    // MARK: - Structural Warning

    func testStructuralWarningAlwaysPresent() {
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        XCTAssertTrue(result.warnings.contains { $0.type == .structuralValidationOnly },
                       "Structural-only warning should always be present")
    }

    // MARK: - Multiple Errors

    func testMultipleStructuralErrorsReported() {
        // Missing version AND missing resources AND missing content element
        let root = factory.makeElement(name: "fcpxml")
        // No version, no resources, no content
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThanOrEqual(result.errors.count, 3,
            "Should report at least 3 errors (version, resources, content). Got: \(result.errors)")
    }
}
