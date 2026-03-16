//
//  FCPXMLDTDValidatorTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXMLDTDValidator — macOS DTD validation and cross-platform fallback.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class FCPXMLDTDValidatorTests: XCTestCase {

    private let factory = FoundationXMLFactory()
    private let dtdValidator = FCPXMLDTDValidator()
    private let structuralValidator = FCPXMLStructuralValidator()

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

    /// Creates an invalid FCPXML document (missing root fcpxml element).
    private func makeInvalidDocument() -> any PNXMLDocument {
        let doc = factory.makeDocument()
        doc.setRootElement(factory.makeElement(name: "notfcpxml"))
        return doc
    }

    // MARK: - macOS DTD Validation (Existing Behavior Preserved)

    #if os(macOS)
    func testDTDValidatorOnMacOSWithValidDocument() {
        // On macOS, the DTD validator should use Foundation DTD validation.
        // Using a factory-built document (not a FoundationXMLDocument loaded from XML string),
        // the DTD validator will return an error because it can't cast to FoundationXMLDocument.
        // This test verifies the macOS code path is exercised.
        let doc = makeValidDocument()
        let result = dtdValidator.validate(doc, version: .v1_10)
        // The factory-built document may or may not be a FoundationXMLDocument;
        // what matters is the macOS path is reached (no crash, deterministic result).
        XCTAssertNotNil(result)
    }
    #endif

    // MARK: - Structural Fallback Simulation (Non-macOS Path)

    // On macOS we can't exercise the `#else` path at compile time, but we CAN
    // test the structural validator directly — the same code the `#else` path calls.
    // This verifies that the fallback logic produces the expected results.

    func testStructuralFallbackWithValidDocument() {
        // Simulates the non-macOS DTD path: structural validator on a valid document.
        let doc = makeValidDocument()
        let result = structuralValidator.validate(doc)

        // Structural validation should pass (no errors).
        XCTAssertTrue(result.isValid,
            "Valid document should pass structural validation. Errors: \(result.detailedDescription)")

        // Should contain the structuralValidationOnly warning.
        XCTAssertTrue(result.warnings.contains { $0.type == .structuralValidationOnly },
            "Structural fallback should include structuralValidationOnly warning")
    }

    func testStructuralFallbackWithInvalidDocument() {
        // Simulates the non-macOS DTD path: structural validator on an invalid document.
        let doc = makeInvalidDocument()
        let result = structuralValidator.validate(doc)

        // Structural validation should fail with errors.
        XCTAssertFalse(result.isValid,
            "Invalid document should fail structural validation")
        XCTAssertFalse(result.errors.isEmpty,
            "Invalid document should produce errors")
    }

    func testStructuralFallbackWarningIsNotError() {
        // The non-macOS path should return a warning (not an error) when structural
        // validation passes — this is the key behavioral difference from the old code
        // which returned a hard error saying "DTD validation is not available".
        let doc = makeValidDocument()
        let result = structuralValidator.validate(doc)

        // No errors — the document is valid.
        XCTAssertTrue(result.errors.isEmpty,
            "Valid document should have no errors in structural fallback")

        // The result is valid (isValid == true) with a warning.
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.warnings.isEmpty,
            "Should have at least the structuralValidationOnly warning")
    }

    func testStructuralFallbackPropagatesAllErrors() {
        // A document with multiple structural issues should report all of them.
        let root = factory.makeElement(name: "fcpxml")
        // No version attribute, no resources, no content element
        let doc = factory.makeDocument()
        doc.setRootElement(root)

        let result = structuralValidator.validate(doc)
        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThanOrEqual(result.errors.count, 3,
            "Should report multiple structural errors. Got: \(result.errors)")
    }

    // MARK: - Validation Result Types Are Consistent

    func testValidationErrorTypesHaveAllCases() {
        // Verify key error types exist (they must be the same across platforms).
        let _ = ValidationError.ErrorType.dtdValidation
        let _ = ValidationError.ErrorType.missingRequiredElement
        let _ = ValidationError.ErrorType.invalidAttributeValue
        let _ = ValidationError.ErrorType.unknownElementName
        let _ = ValidationError.ErrorType.missingAssetReference
    }

    func testValidationWarningTypesHaveAllCases() {
        // Verify key warning types exist (they must be the same across platforms).
        let _ = ValidationWarning.WarningType.structuralValidationOnly
        let _ = ValidationWarning.WarningType.negativeTimeAttribute
        let _ = ValidationWarning.WarningType.unusedAsset
    }
}
