//
//  FCPXMLStructuralValidatorTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXMLStructuralValidator — cross-platform structural validation.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Structural validator")
struct FCPXMLStructuralValidatorTests {
    private let factory = FoundationXMLFactory()
    private let validator = FCPXMLStructuralValidator()

    // MARK: - Helpers

    /// Creates a well-formed FCPXML document with resources and a project.
    private func makeValidDocument(version: String = "1.10") -> any OFKXMLDocument {
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

    @Test("Valid FCPXML passes")
    func validFCPXMLPasses() {
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        #expect(result.isValid, "Well-formed FCPXML should pass. Errors: \(result.detailedDescription)")
        // Should still have the structural-only warning
        #expect(result.warnings.contains { $0.type == .structuralValidationOnly })
    }

    @Test("Valid document with library passes")
    func validDocumentWithLibraryPasses() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.11")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "library"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(result.isValid, "FCPXML with library should pass. Errors: \(result.detailedDescription)")
    }

    @Test("Valid document with event passes")
    func validDocumentWithEventPasses() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.9")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "event"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(result.isValid, "FCPXML with event should pass. Errors: \(result.detailedDescription)")
    }

    // MARK: - Missing Root Element

    @Test("Missing root element fails")
    func missingRootElementFails() {
        let doc = factory.makeDocument()
        doc.setRootElement(factory.makeElement(name: "notfcpxml"))

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("fcpxml")
        })
    }

    @Test("Empty document fails")
    func emptyDocumentFails() throws {
        let xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><wrongroot/>"
        let doc = try #require(try? factory.makeDocument(xmlString: xmlString))

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains { $0.type == .missingRequiredElement })
    }

    // MARK: - Missing Version Attribute

    @Test("Missing version attribute fails")
    func missingVersionAttributeFails() {
        let root = factory.makeElement(name: "fcpxml")
        // No version attribute
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .invalidAttributeValue && $0.message.contains("version")
        })
    }

    // MARK: - Invalid Version Attribute

    @Test("Empty version attribute fails")
    func emptyVersionAttributeFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .invalidAttributeValue && $0.message.contains("empty")
        })
    }

    @Test("Non-numeric version fails")
    func nonNumericVersionFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "abc")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(
            result.errors.contains {
                $0.type == .invalidAttributeValue && $0.message.contains("invalid")
            },
            "Non-numeric version should be flagged. Errors: \(result.errors)"
        )
    }

    @Test("Known version passes")
    func knownVersionPasses() {
        // All known versions should pass structural validation
        for version in ["1.6", "1.10", "1.13", "1.14"] {
            let root = factory.makeElement(name: "fcpxml")
            root.addAttribute(name: "version", value: version)
            root.addChild(factory.makeElement(name: "resources"))
            root.addChild(factory.makeElement(name: "project"))
            let doc = factory.makeDocument()
            doc.setRootElement(root)

            let result = validator.validate(doc)
            #expect(result.isValid, "Version \(version) should be valid. Errors: \(result.detailedDescription)")
        }
    }

    @Test("Future numeric version passes")
    func futureNumericVersionPasses() {
        // An unknown but properly formatted version (e.g., "2.0") should pass
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "2.0")
        root.addChild(factory.makeElement(name: "resources"))
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(result.isValid, "Future numeric version should be accepted. Errors: \(result.detailedDescription)")
    }

    // MARK: - Missing Resources

    @Test("Missing resources fails")
    func missingResourcesFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        // No resources element
        root.addChild(factory.makeElement(name: "project"))
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("resources")
        })
    }

    // MARK: - Missing Content Element

    @Test("Missing content element fails")
    func missingContentElementFails() {
        let root = factory.makeElement(name: "fcpxml")
        root.addAttribute(name: "version", value: "1.10")
        root.addChild(factory.makeElement(name: "resources"))
        // No library, event, or project
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .missingRequiredElement && $0.message.contains("library, event, or project")
        })
    }

    // MARK: - Unknown Element Names

    @Test("Unknown element name detected")
    func unknownElementNameDetected() {
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
        #expect(!result.isValid)
        #expect(result.errors.contains {
            $0.type == .unknownElementName && $0.message.contains("fake-element")
        })
    }

    @Test("Multiple unknown elements detected")
    func multipleUnknownElementsDetected() {
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
        #expect(!result.isValid)
        let unknownErrors = result.errors.filter { $0.type == .unknownElementName }
        #expect(unknownErrors.count == 2, "Should detect both unknown elements")
    }

    @Test("All known elements pass")
    func allKnownElementsPass() {
        // A document with only known element names should have no unknownElementName errors
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        let unknownErrors = result.errors.filter { $0.type == .unknownElementName }
        #expect(unknownErrors.isEmpty, "Known elements should not trigger unknown element errors")
    }

    // MARK: - Structural Warning

    @Test("Structural warning always present")
    func structuralWarningAlwaysPresent() {
        let doc = makeValidDocument()
        let result = validator.validate(doc)
        #expect(
            result.warnings.contains { $0.type == .structuralValidationOnly },
            "Structural-only warning should always be present"
        )
    }

    // MARK: - Multiple Errors

    @Test("Multiple structural errors reported")
    func multipleStructuralErrorsReported() {
        // Missing version AND missing resources AND missing content element
        let root = factory.makeElement(name: "fcpxml")
        // No version, no resources, no content
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = validator.validate(doc)
        #expect(!result.isValid)
        #expect(
            result.errors.count >= 3,
            "Should report at least 3 errors (version, resources, content). Got: \(result.errors)"
        )
    }
}
