//
//  ImportOptionsTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML import options functionality.
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class ImportOptionsTests: XCTestCase {
    
    // MARK: - ImportOption Tests
    
    func testImportOptionInitialization() {
        let option = FinalCutPro.FCPXML.ImportOption(key: "test-key", value: "test-value")
        XCTAssertEqual(option.key, "test-key")
        XCTAssertEqual(option.value, "test-value")
    }
    
    func testImportOptionEquality() {
        let option1 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option2 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option3 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "different")
        
        XCTAssertEqual(option1, option2)
        XCTAssertNotEqual(option1, option3)
    }
    
    func testImportOptionHashable() {
        let option1 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        let option2 = FinalCutPro.FCPXML.ImportOption(key: "key", value: "value")
        
        XCTAssertEqual(option1.hashValue, option2.hashValue)
    }
    
    func testImportOptionCodable() throws {
        let option = FinalCutPro.FCPXML.ImportOption(key: "test-key", value: "test-value")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(option)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.ImportOption.self, from: data)
        
        XCTAssertEqual(option, decoded)
    }
    
    // MARK: - Convenience Initializers
    
    func testCopyAssetsOption() {
        let copyOption = FinalCutPro.FCPXML.ImportOption.copyAssets(true)
        XCTAssertEqual(copyOption.key, "copy assets")
        XCTAssertEqual(copyOption.value, "1")
        
        let linkOption = FinalCutPro.FCPXML.ImportOption.copyAssets(false)
        XCTAssertEqual(linkOption.key, "copy assets")
        XCTAssertEqual(linkOption.value, "0")
    }
    
    func testSuppressWarningsOption() {
        let suppressOption = FinalCutPro.FCPXML.ImportOption.suppressWarnings(true)
        XCTAssertEqual(suppressOption.key, "suppress warnings")
        XCTAssertEqual(suppressOption.value, "1")
        
        let allowOption = FinalCutPro.FCPXML.ImportOption.suppressWarnings(false)
        XCTAssertEqual(allowOption.key, "suppress warnings")
        XCTAssertEqual(allowOption.value, "0")
    }
    
    func testLibraryLocationOptionString() {
        let location = "/path/to/library.fcpxlibrary"
        let option = FinalCutPro.FCPXML.ImportOption.libraryLocation(location)
        
        XCTAssertEqual(option.key, "library location")
        XCTAssertEqual(option.value, location)
    }
    
    func testLibraryLocationOptionURL() {
        let url = URL(fileURLWithPath: "/path/to/library.fcpxlibrary")
        let option = FinalCutPro.FCPXML.ImportOption.libraryLocation(url)
        
        XCTAssertEqual(option.key, "library location")
        XCTAssertEqual(option.value, url.absoluteString)
    }
    
    // MARK: - ImportOptions Container Tests
    
    func testImportOptionsInitializationWithOptions() {
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1"),
            FinalCutPro.FCPXML.ImportOption(key: "key2", value: "value2")
        ]
        
        let container = FinalCutPro.FCPXML.ImportOptions(options: options)
        XCTAssertEqual(container.options.count, 2)
        XCTAssertEqual(container.options[0].key, "key1")
        XCTAssertEqual(container.options[1].key, "key2")
    }
    
    func testImportOptionsInitializationWithNil() {
        let container = FinalCutPro.FCPXML.ImportOptions(options: nil)
        XCTAssertNil(container)
    }
    
    func testImportOptionsInitializationWithEmptyArray() {
        let container = FinalCutPro.FCPXML.ImportOptions(options: [] as [FinalCutPro.FCPXML.ImportOption]?)
        XCTAssertNil(container)
    }
    
    func testImportOptionsCodable() throws {
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1"),
            FinalCutPro.FCPXML.ImportOption(key: "key2", value: "value2")
        ]
        let container = FinalCutPro.FCPXML.ImportOptions(options: options)!
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(container)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.ImportOptions.self, from: data)
        
        XCTAssertEqual(container.options.count, decoded.options.count)
        XCTAssertEqual(container.options[0], decoded.options[0])
        XCTAssertEqual(container.options[1], decoded.options[1])
    }
    
    // MARK: - FCPXML.Root Import Options Tests
    
    func testRootImportOptionsGetSet() {
        let root = FinalCutPro.FCPXML.Root()
        
        // Initially nil
        XCTAssertNil(root.importOptions)
        
        // Set import options
        let options = [
            FinalCutPro.FCPXML.ImportOption(key: "key1", value: "value1")
        ]
        root.importOptions = FinalCutPro.FCPXML.ImportOptions(options: options)
        
        // Verify it was set
        XCTAssertNotNil(root.importOptions)
        XCTAssertEqual(root.importOptions?.options.count, 1)
        XCTAssertEqual(root.importOptions?.options[0].key, "key1")
        
        // Set to nil
        root.importOptions = nil
        XCTAssertNil(root.importOptions)
    }
    
    func testRootImportOptionsFromXML() throws {
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
        
        let data = xmlString.data(using: .utf8)!
        let document = try FoundationXMLFactory().makeDocument(data: data)
        guard let rootElement = document.rootElement(),
              let root = FinalCutPro.FCPXML.Root(element: rootElement) else {
            XCTFail("Failed to create root")
            return
        }
        
        // Verify import options were parsed
        XCTAssertNotNil(root.importOptions)
        XCTAssertEqual(root.importOptions?.options.count, 2)
        
        let options = root.importOptions!.options
        let copyAssetsOption = options.first { $0.key == "copy assets" }
        let suppressWarningsOption = options.first { $0.key == "suppress warnings" }
        
        XCTAssertNotNil(copyAssetsOption)
        XCTAssertEqual(copyAssetsOption?.value, "1")
        XCTAssertNotNil(suppressWarningsOption)
        XCTAssertEqual(suppressWarningsOption?.value, "0")
    }
    
    func testRootImportOptionsToXML() {
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
        XCTAssertTrue(xmlString.contains("<import-options>"))
        XCTAssertTrue(xmlString.contains("key=\"copy assets\""))
        XCTAssertTrue(xmlString.contains("value=\"1\""))
        XCTAssertTrue(xmlString.contains("key=\"suppress warnings\""))
        XCTAssertTrue(xmlString.contains("value=\"0\""))
        
        // Verify import-options comes before resources
        if let importOptionsRange = xmlString.range(of: "<import-options>"),
           let resourcesRange = xmlString.range(of: "<resources>") {
            XCTAssertTrue(importOptionsRange.lowerBound < resourcesRange.lowerBound,
                         "import-options should come before resources")
        }
    }
    
    // MARK: - Helper Methods Tests
    
    func testSetShouldCopyAssetsOnImport() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        // Set copy assets to true
        root.setShouldCopyAssetsOnImport(true)
        
        XCTAssertNotNil(root.importOptions)
        let copyAssetsOption = root.importOptions?.options.first { $0.key == "copy assets" }
        XCTAssertNotNil(copyAssetsOption)
        XCTAssertEqual(copyAssetsOption?.value, "1")
        
        // Change to false
        root.setShouldCopyAssetsOnImport(false)
        let updatedOption = root.importOptions?.options.first { $0.key == "copy assets" }
        XCTAssertEqual(updatedOption?.value, "0")
        
        // Verify only one copy assets option exists
        let copyAssetsOptions = root.importOptions?.options.filter { $0.key == "copy assets" }
        XCTAssertEqual(copyAssetsOptions?.count, 1)
    }
    
    func testSetShouldSuppressWarningsOnImport() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        // Set suppress warnings to true
        root.setShouldSuppressWarningsOnImport(true)
        
        XCTAssertNotNil(root.importOptions)
        let suppressOption = root.importOptions?.options.first { $0.key == "suppress warnings" }
        XCTAssertNotNil(suppressOption)
        XCTAssertEqual(suppressOption?.value, "1")
        
        // Change to false
        root.setShouldSuppressWarningsOnImport(false)
        let updatedOption = root.importOptions?.options.first { $0.key == "suppress warnings" }
        XCTAssertEqual(updatedOption?.value, "0")
        
        // Verify only one suppress warnings option exists
        let suppressOptions = root.importOptions?.options.filter { $0.key == "suppress warnings" }
        XCTAssertEqual(suppressOptions?.count, 1)
    }
    
    func testSetLibraryLocationForImportString() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        let location = "/path/to/library.fcpxlibrary"
        root.setLibraryLocationForImport(location)
        
        XCTAssertNotNil(root.importOptions)
        let locationOption = root.importOptions?.options.first { $0.key == "library location" }
        XCTAssertNotNil(locationOption)
        XCTAssertEqual(locationOption?.value, location)
    }
    
    func testSetLibraryLocationForImportURL() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        let url = URL(fileURLWithPath: "/path/to/library.fcpxlibrary")
        root.setLibraryLocationForImport(url)
        
        XCTAssertNotNil(root.importOptions)
        let locationOption = root.importOptions?.options.first { $0.key == "library location" }
        XCTAssertNotNil(locationOption)
        XCTAssertEqual(locationOption?.value, url.absoluteString)
    }
    
    func testMultipleImportOptions() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        // Add multiple options
        root.setShouldCopyAssetsOnImport(true)
        root.setShouldSuppressWarningsOnImport(false)
        root.setLibraryLocationForImport("/path/to/library.fcpxlibrary")
        
        XCTAssertNotNil(root.importOptions)
        XCTAssertEqual(root.importOptions?.options.count, 3)
        
        let copyAssets = root.importOptions?.options.first { $0.key == "copy assets" }
        let suppressWarnings = root.importOptions?.options.first { $0.key == "suppress warnings" }
        let libraryLocation = root.importOptions?.options.first { $0.key == "library location" }
        
        XCTAssertNotNil(copyAssets)
        XCTAssertEqual(copyAssets?.value, "1")
        XCTAssertNotNil(suppressWarnings)
        XCTAssertEqual(suppressWarnings?.value, "0")
        XCTAssertNotNil(libraryLocation)
        XCTAssertEqual(libraryLocation?.value, "/path/to/library.fcpxlibrary")
    }
    
    func testUpdateExistingImportOption() {
        var root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        // Set copy assets to true
        root.setShouldCopyAssetsOnImport(true)
        XCTAssertEqual(root.importOptions?.options.first { $0.key == "copy assets" }?.value, "1")
        
        // Update to false
        root.setShouldCopyAssetsOnImport(false)
        XCTAssertEqual(root.importOptions?.options.first { $0.key == "copy assets" }?.value, "0")
        
        // Verify only one copy assets option exists
        let copyAssetsOptions = root.importOptions?.options.filter { $0.key == "copy assets" }
        XCTAssertEqual(copyAssetsOptions?.count, 1)
    }
    
    // MARK: - Integration Tests
    
    func testImportOptionsRoundTrip() throws {
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
        let xmlData = root.element.xmlString.data(using: .utf8)!
        
        // Parse back
        let parsedDocument = try FoundationXMLFactory().makeDocument(data: xmlData)
        guard let parsedRootElement = parsedDocument.rootElement(),
              let parsedRoot = FinalCutPro.FCPXML.Root(element: parsedRootElement) else {
            XCTFail("Failed to parse root")
            return
        }
        
        // Verify import options were preserved
        XCTAssertNotNil(parsedRoot.importOptions)
        XCTAssertEqual(parsedRoot.importOptions?.options.count, 3)
        
        let copyAssets = parsedRoot.importOptions?.options.first { $0.key == "copy assets" }
        let suppressWarnings = parsedRoot.importOptions?.options.first { $0.key == "suppress warnings" }
        let libraryLocation = parsedRoot.importOptions?.options.first { $0.key == "library location" }
        
        XCTAssertEqual(copyAssets?.value, "1")
        XCTAssertEqual(suppressWarnings?.value, "0")
        XCTAssertEqual(libraryLocation?.value, "/path/to/library.fcpxlibrary")
    }
    
    func testImportOptionsWithInvalidXML() {
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
            XCTAssertTrue(validOptions.isEmpty, "Invalid option should be filtered out")
        } else {
            // If all options are invalid, importOptions should be nil
            XCTAssertNil(root.importOptions)
        }
    }
}
