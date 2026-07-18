//
//  FCPXMLImportOptionsTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML import options functionality.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Import options")
struct FCPXMLImportOptionsTests {

    // MARK: - ImportOption Tests

    @Test("ImportOption initialization")
    func importOptionInitialization() {
        let option = FinalCutPro.FCPXML.ImportOption(key: "test-key", value: "test-value")
        #expect(option.key == "test-key")
        #expect(option.value == "test-value")
    }

    @Test("ImportOption equality")
    func importOptionEquality() {
        let option1 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option2 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option3 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "different")

        #expect(option1 == option2)
        #expect(option1 != option3)
    }

    @Test("ImportOption hashable")
    func importOptionHashable() {
        let option1 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option2 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")

        #expect(option1.hashValue == option2.hashValue)
    }

    @Test("ImportOption Codable round-trip")
    func importOptionCodable() throws {
        let option = FinalCutPro.FCPXML.ImportOption(key: "test-key", value: "test-value")

        let encoder = JSONEncoder()
        let data = try encoder.encode(option)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.ImportOption.self, from: data)

        #expect(option == decoded)
    }

    // MARK: - Convenience Initializers

    @Test("copyAssets option")
    func copyAssetsOption() {
        let copyOption = FinalCutPro.FCPXML.ImportOption.copyAssets(true)
        #expect(copyOption.key == "copy assets")
        #expect(copyOption.value == "1")

        let linkOption = FinalCutPro.FCPXML.ImportOption.copyAssets(false)
        #expect(linkOption.key == "copy assets")
        #expect(linkOption.value == "0")
    }

    @Test("suppressWarnings option")
    func suppressWarningsOption() {
        let suppressOption = FinalCutPro.FCPXML.ImportOption.suppressWarnings(true)
        #expect(suppressOption.key == "suppress warnings")
        #expect(suppressOption.value == "1")

        let allowOption = FinalCutPro.FCPXML.ImportOption.suppressWarnings(false)
        #expect(allowOption.key == "suppress warnings")
        #expect(allowOption.value == "0")
    }

    @Test("libraryLocation option from string")
    func libraryLocationOptionString() {
        let location = "/path/to/library.fcpxlibrary"
        let option = FinalCutPro.FCPXML.ImportOption.libraryLocation(location)

        #expect(option.key == "library location")
        #expect(option.value == location)
    }

    @Test("libraryLocation option from URL")
    func libraryLocationOptionURL() {
        let url = URL(fileURLWithPath: "/path/to/library.fcpxlibrary")
        let option = FinalCutPro.FCPXML.ImportOption.libraryLocation(url)

        #expect(option.key == "library location")
        #expect(option.value == url.absoluteString)
    }

    // MARK: - ImportOptions Container Tests

    @Test("ImportOptions initialization with options")
    func importOptionsInitializationWithOptions() {
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1"),
            FinalCutPro.FCPXML.ImportOption(key: "key2", value: "value2")
        ]

        let container = FinalCutPro.FCPXML.ImportOptions(options: options)
        #expect(container.options.count == 2)
        #expect(container.options[0].key == "key1")
        #expect(container.options[1].key == "key2")
    }

    @Test("ImportOptions initialization with nil")
    func importOptionsInitializationWithNil() {
        let container = FinalCutPro.FCPXML.ImportOptions(options: nil)
        #expect(container == nil)
    }

    @Test("ImportOptions initialization with empty array")
    func importOptionsInitializationWithEmptyArray() {
        let container = FinalCutPro.FCPXML.ImportOptions(options: [] as [FinalCutPro.FCPXML.ImportOption]?)
        #expect(container == nil)
    }

    @Test("ImportOptions Codable round-trip")
    func importOptionsCodable() throws {
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1"),
            FinalCutPro.FCPXML.ImportOption(key: "key2", value: "value2")
        ]
        let container = FinalCutPro.FCPXML.ImportOptions(options: options)

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.ImportOptions.self, from: data)

        #expect(container.options.count == decoded.options.count)
        #expect(container.options[0] == decoded.options[0])
        #expect(container.options[1] == decoded.options[1])
    }

    // MARK: - FCPXML.Root Import Options Tests

    @Test("Root importOptions get/set")
    func rootImportOptionsGetSet() {
        let root = FinalCutPro.FCPXML.Root()

        // Initially nil
        #expect(root.importOptions == nil)

        // Set import options
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1")
        ]
        root.importOptions = FinalCutPro.FCPXML.ImportOptions(options: options)

        // Verify it was set
        #expect(root.importOptions != nil)
        #expect(root.importOptions?.options.count == 1)
        #expect(root.importOptions?.options[0].key == "key1")

        // Set to nil
        root.importOptions = nil
        #expect(root.importOptions == nil)
    }

    @Test("Root importOptions from XML")
    func rootImportOptionsFromXML() throws {
        // Create XML with import-options
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <import-options>
                <option key="copy assets" value="1"/>
                <option key="suppress warnings" value="0"/>
            </import-options>
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let document = try FoundationXMLFactory().makeDocument(data: data)
        let rootElement = try #require(document.rootElement())
        let root = try #require(FinalCutPro.FCPXML.Root(element: rootElement))

        // Verify import options were parsed
        #expect(root.importOptions != nil)
        #expect(root.importOptions?.options.count == 2)

        let options = try #require(root.importOptions?.options)
        let copyAssetsOption = options.first { $0.key == "copy assets" }
        let suppressWarningsOption = options.first { $0.key == "suppress warnings" }

        #expect(copyAssetsOption != nil)
        #expect(copyAssetsOption?.value == "1")
        #expect(suppressWarningsOption != nil)
        #expect(suppressWarningsOption?.value == "0")
    }

    @Test("Root importOptions to XML")
    func rootImportOptionsToXML() {
        let root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")

        // Add resources element (required)
        let resources = FoundationXMLFactory().makeElement(name: "resources")
        root.resources = resources

        // Set import options
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "copy assets", value: "1"),
            FinalCutPro.FCPXML.ImportOption(key: "suppress warnings", value: "0")
        ]
        root.importOptions = FinalCutPro.FCPXML.ImportOptions(options: options)

        // Verify XML structure
        let xmlString = root.element.xmlString
        #expect(xmlString.contains("<import-options>"))
        #expect(xmlString.contains("key=\"copy assets\""))
        #expect(xmlString.contains("value=\"1\""))
        #expect(xmlString.contains("key=\"suppress warnings\""))
        #expect(xmlString.contains("value=\"0\""))

        // Verify import-options comes before resources
        if let importOptionsRange = xmlString.range(of: "<import-options>"),
           let resourcesRange = xmlString.range(of: "<resources>") {
            let comesBefore = importOptionsRange.lowerBound < resourcesRange.lowerBound
            #expect(comesBefore, "import-options should come before resources")
        }
    }

    // MARK: - Helper Methods Tests

    @Test("setShouldCopyAssetsOnImport")
    func setShouldCopyAssetsOnImport() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        // Set copy assets to true
        root.setShouldCopyAssetsOnImport(true)

        #expect(root.importOptions != nil)
        let copyAssetsOption = root.importOptions?.options.first { $0.key == "copy assets" }
        #expect(copyAssetsOption != nil)
        #expect(copyAssetsOption?.value == "1")

        // Change to false
        root.setShouldCopyAssetsOnImport(false)
        let updatedOption = root.importOptions?.options.first { $0.key == "copy assets" }
        #expect(updatedOption?.value == "0")

        // Verify only one copy assets option exists
        let copyAssetsOptions = root.importOptions?.options.filter { $0.key == "copy assets" }
        #expect(copyAssetsOptions?.count == 1)
    }

    @Test("setShouldSuppressWarningsOnImport")
    func setShouldSuppressWarningsOnImport() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        // Set suppress warnings to true
        root.setShouldSuppressWarningsOnImport(true)

        #expect(root.importOptions != nil)
        let suppressOption = root.importOptions?.options.first { $0.key == "suppress warnings" }
        #expect(suppressOption != nil)
        #expect(suppressOption?.value == "1")

        // Change to false
        root.setShouldSuppressWarningsOnImport(false)
        let updatedOption = root.importOptions?.options.first { $0.key == "suppress warnings" }
        #expect(updatedOption?.value == "0")

        // Verify only one suppress warnings option exists
        let suppressOptions = root.importOptions?.options.filter { $0.key == "suppress warnings" }
        #expect(suppressOptions?.count == 1)
    }

    @Test("setLibraryLocationForImport from string")
    func setLibraryLocationForImportString() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        let location = "/path/to/library.fcpxlibrary"
        root.setLibraryLocationForImport(location)

        #expect(root.importOptions != nil)
        let locationOption = root.importOptions?.options.first { $0.key == "library location" }
        #expect(locationOption != nil)
        #expect(locationOption?.value == location)
    }

    @Test("setLibraryLocationForImport from URL")
    func setLibraryLocationForImportURL() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        let url = URL(fileURLWithPath: "/path/to/library.fcpxlibrary")
        root.setLibraryLocationForImport(url)

        #expect(root.importOptions != nil)
        let locationOption = root.importOptions?.options.first { $0.key == "library location" }
        #expect(locationOption != nil)
        #expect(locationOption?.value == url.absoluteString)
    }

    @Test("Multiple import options")
    func multipleImportOptions() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        // Add multiple options
        root.setShouldCopyAssetsOnImport(true)
        root.setShouldSuppressWarningsOnImport(false)
        root.setLibraryLocationForImport("/path/to/library.fcpxlibrary")

        #expect(root.importOptions != nil)
        #expect(root.importOptions?.options.count == 3)

        let copyAssets = root.importOptions?.options.first { $0.key == "copy assets" }
        let suppressWarnings = root.importOptions?.options.first { $0.key == "suppress warnings" }
        let libraryLocation = root.importOptions?.options.first { $0.key == "library location" }

        #expect(copyAssets != nil)
        #expect(copyAssets?.value == "1")
        #expect(suppressWarnings != nil)
        #expect(suppressWarnings?.value == "0")
        #expect(libraryLocation != nil)
        #expect(libraryLocation?.value == "/path/to/library.fcpxlibrary")
    }

    @Test("Update existing import option")
    func updateExistingImportOption() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        // Set copy assets to true
        root.setShouldCopyAssetsOnImport(true)
        #expect(root.importOptions?.options.first { $0.key == "copy assets" }?.value == "1")

        // Update to false
        root.setShouldCopyAssetsOnImport(false)
        #expect(root.importOptions?.options.first { $0.key == "copy assets" }?.value == "0")

        // Verify only one copy assets option exists
        let copyAssetsOptions = root.importOptions?.options.filter { $0.key == "copy assets" }
        #expect(copyAssetsOptions?.count == 1)
    }

    // MARK: - Integration Tests

    @Test("Import options round-trip")
    func importOptionsRoundTrip() throws {
        // Create root with import options
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        root.setShouldCopyAssetsOnImport(true)
        root.setShouldSuppressWarningsOnImport(false)
        root.setLibraryLocationForImport("/path/to/library.fcpxlibrary")

        // Convert to XML
        let document = FoundationXMLFactory().makeDocument()
        document.setRootElement(root.element)
        let xmlData = try #require(root.element.xmlString.data(using: .utf8))

        // Parse back
        let parsedDocument = try FoundationXMLFactory().makeDocument(data: xmlData)
        let parsedRootElement = try #require(parsedDocument.rootElement())
        let parsedRoot = try #require(FinalCutPro.FCPXML.Root(element: parsedRootElement))

        // Verify import options were preserved
        #expect(parsedRoot.importOptions != nil)
        #expect(parsedRoot.importOptions?.options.count == 3)

        let copyAssets = parsedRoot.importOptions?.options.first { $0.key == "copy assets" }
        let suppressWarnings = parsedRoot.importOptions?.options.first { $0.key == "suppress warnings" }
        let libraryLocation = parsedRoot.importOptions?.options.first { $0.key == "library location" }

        #expect(copyAssets?.value == "1")
        #expect(suppressWarnings?.value == "0")
        #expect(libraryLocation?.value == "/path/to/library.fcpxlibrary")
    }

    @Test("Import options with invalid XML")
    func importOptionsWithInvalidXML() {
        let root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")

        // Create import-options element with invalid option (missing value)
        let importOptionsElement = FoundationXMLFactory().makeElement(name: "import-options")
        let invalidOption = FoundationXMLFactory().makeElement(name: "option")
        invalidOption.addAttribute(name: "key", value: "test-key")
        // Missing value attribute
        importOptionsElement.addChild(invalidOption)

        // Manually set the element
        root.element.insertChild(importOptionsElement, at: 0)

        // Should gracefully handle invalid options (skip them)
        // The invalid option should be filtered out
        if let importOptions = root.importOptions {
            let validOptions = importOptions.options.filter { $0.key == "test-key" }
            #expect(validOptions.isEmpty, "Invalid option should be filtered out")
        } else {
            // If all options are invalid, importOptions should be nil
            #expect(root.importOptions == nil)
        }
    }
}

