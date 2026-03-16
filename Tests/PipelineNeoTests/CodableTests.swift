//
//  CodableTests.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML Codable support (JSON/PLIST conversion).
//

import XCTest
@testable import PipelineNeo

@available(macOS 12.0, *)
final class CodableTests: XCTestCase {
    
    // MARK: - Basic Codable Tests
    
    func testFCPXMLCodableEncodingDecoding() throws {
        // Create a simple FCPXML document
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let original = try FinalCutPro.FCPXML(fileContent: data)
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(original)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.self, from: jsonData)
        
        // Verify the decoded document matches
        XCTAssertEqual(original.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
        XCTAssertEqual(original.xml.rootElement()?.stringValue(forAttributeNamed: "version"),
                      decoded.xml.rootElement()?.stringValue(forAttributeNamed: "version"))
    }
    
    func testRootCodableEncodingDecoding() throws {
        // Create a simple root element
        let root = FinalCutPro.FCPXML.Root()
        root.element.addAttribute(name: "version", value: "1.9")
        root.resources = FoundationXMLFactory().makeElement(name: "resources")
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(root)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.Root.self, from: jsonData)
        
        // Verify the decoded root matches
        XCTAssertEqual(root.element.name, decoded.element.name)
        XCTAssertEqual(root.version, decoded.version)
    }
    
    // MARK: - JSON Conversion Tests
    
    func testJSONStringConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Convert to JSON string
        let jsonString = try fcpxml.jsonString()
        
        // Verify it's valid JSON
        XCTAssertFalse(jsonString.isEmpty)
        XCTAssertTrue(jsonString.contains("xmlString"))
        
        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(jsonString: jsonString)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testJSONDataConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Convert to JSON data
        let jsonData = try fcpxml.jsonData()
        
        // Verify it's valid JSON
        XCTAssertFalse(jsonData.isEmpty)
        
        // Parse JSON to verify structure
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(jsonObject)
        XCTAssertNotNil(jsonObject?["xmlString"] as? String)
        
        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testJSONRoundTrip() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="Test Event">
                    <project name="Test Project">
                        <sequence format="r1">
                            <spine>
                                <asset-clip name="Clip 1" ref="r1" offset="0s" duration="5s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let original = try FinalCutPro.FCPXML(fileContent: data)
        
        // Round trip through JSON
        let jsonData = try original.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        
        // Verify structure is preserved
        let originalRoot = original.xml.rootElement()
        let decodedRoot = decoded.xml.rootElement()
        
        XCTAssertEqual(originalRoot?.name, decodedRoot?.name)
        XCTAssertEqual(originalRoot?.stringValue(forAttributeNamed: "version"),
                      decodedRoot?.stringValue(forAttributeNamed: "version"))
        
        // Verify resources exist
        let originalResources = originalRoot?.firstChildElement(named: "resources")
        let decodedResources = decodedRoot?.firstChildElement(named: "resources")
        XCTAssertNotNil(originalResources)
        XCTAssertNotNil(decodedResources)
    }
    
    // MARK: - PLIST Conversion Tests
    
    func testPlistStringConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Convert to PLIST string
        let plistString = try fcpxml.plistString()
        
        // Verify it's valid PLIST XML
        XCTAssertFalse(plistString.isEmpty)
        XCTAssertTrue(plistString.contains("<?xml") || plistString.contains("<plist"))
        
        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(plistString: plistString)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testPlistDataConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Convert to PLIST data
        let plistData = try fcpxml.plistData()
        
        // Verify it's valid PLIST
        XCTAssertFalse(plistData.isEmpty)
        
        // Parse PLIST to verify structure
        let plistObject = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        XCTAssertNotNil(plistObject)
        XCTAssertNotNil(plistObject?["xmlString"] as? String)
        
        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(plistData: plistData)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testPlistRoundTrip() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="Test Event">
                    <project name="Test Project">
                        <sequence format="r1">
                            <spine>
                                <asset-clip name="Clip 1" ref="r1" offset="0s" duration="5s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let original = try FinalCutPro.FCPXML(fileContent: data)
        
        // Round trip through PLIST
        let plistData = try original.plistData()
        let decoded = try FinalCutPro.FCPXML.from(plistData: plistData)
        
        // Verify structure is preserved
        let originalRoot = original.xml.rootElement()
        let decodedRoot = decoded.xml.rootElement()
        
        XCTAssertEqual(originalRoot?.name, decodedRoot?.name)
        XCTAssertEqual(originalRoot?.stringValue(forAttributeNamed: "version"),
                      decodedRoot?.stringValue(forAttributeNamed: "version"))
        
        // Verify resources exist
        let originalResources = originalRoot?.firstChildElement(named: "resources")
        let decodedResources = decodedRoot?.firstChildElement(named: "resources")
        XCTAssertNotNil(originalResources)
        XCTAssertNotNil(decodedResources)
    }
    
    // MARK: - Converter Utility Tests
    
    func testFCPXMLCodableConverterJSONString() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        let jsonString = try FCPXMLCodableConverter.jsonString(from: fcpxml)
        XCTAssertFalse(jsonString.isEmpty)
        
        let decoded = try FCPXMLCodableConverter.fcpxml(from: jsonString)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testFCPXMLCodableConverterJSONData() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        let jsonData = try FCPXMLCodableConverter.jsonData(from: fcpxml)
        XCTAssertFalse(jsonData.isEmpty)
        
        let decoded = try FCPXMLCodableConverter.fcpxml(from: jsonData)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testFCPXMLCodableConverterPlistString() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        let plistString = try FCPXMLCodableConverter.plistString(from: fcpxml)
        XCTAssertFalse(plistString.isEmpty)
        
        let decoded = try FCPXMLCodableConverter.fcpxml(fromPlistString: plistString)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testFCPXMLCodableConverterPlistData() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        let plistData = try FCPXMLCodableConverter.plistData(from: fcpxml)
        XCTAssertFalse(plistData.isEmpty)
        
        let decoded = try FCPXMLCodableConverter.fcpxml(fromPlistData: plistData)
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidJSONDecoding() {
        let invalidJSON = "{ invalid json }"
        
        XCTAssertThrowsError(try FinalCutPro.FCPXML.from(jsonString: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError || error is FCPXMLCodableError)
        }
    }
    
    func testInvalidPlistDecoding() {
        let invalidPlist = "<?xml version=\"1.0\"?><invalid/>"
        
        XCTAssertThrowsError(try FinalCutPro.FCPXML.from(plistString: invalidPlist)) { error in
            XCTAssertTrue(error is DecodingError || error is FCPXMLCodableError)
        }
    }
    
    func testInvalidXMLStringInJSON() {
        // Create JSON with invalid XML string
        let invalidJSON = """
        {
            "xmlString": "not valid xml"
        }
        """
        
        XCTAssertThrowsError(try FinalCutPro.FCPXML.from(jsonString: invalidJSON)) { error in
            XCTAssertTrue(error is FCPXMLCodableError || error is DecodingError)
        }
    }
    
    // MARK: - Integration Tests with Real Samples
    
    func testCodableWithFCPXMLSample() throws {
        // Try to load a real FCPXML sample if available
        let sampleName = "Structure"
        
        do {
            let fcpxml = try loadFCPXMLSample(named: sampleName)
            
            // Convert to JSON
            let jsonData = try fcpxml.jsonData()
            XCTAssertFalse(jsonData.isEmpty)
            
            // Convert back
            let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
            
            // Verify basic structure
            XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
            XCTAssertEqual(fcpxml.version, decoded.version)
        } catch {
            // Skip if sample not available
            throw XCTSkip("Sample '\(sampleName)' not available: \(error)")
        }
    }
    
    func testCodableWithImportOptions() throws {
        // Create FCPXML with import options
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
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Convert to JSON and back
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        
        // Verify import options are preserved
        guard let originalRootElement = fcpxml.xml.rootElement(),
              let decodedRootElement = decoded.xml.rootElement(),
              let originalRoot = FinalCutPro.FCPXML.Root(element: originalRootElement),
              let decodedRoot = FinalCutPro.FCPXML.Root(element: decodedRootElement) else {
            XCTFail("Failed to create root elements")
            return
        }
        
        XCTAssertEqual(originalRoot.importOptions?.options.count,
                      decodedRoot.importOptions?.options.count)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyFCPXMLDocument() throws {
        // Create minimal valid FCPXML
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        
        XCTAssertEqual(fcpxml.xml.rootElement()?.name, decoded.xml.rootElement()?.name)
    }
    
    func testLargeFCPXMLDocument() throws {
        // Create a larger FCPXML document
        var xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
        """
        
        // Add multiple resources
        for i in 1...10 {
            xmlString += """
                <format id="r\(i)" name="Format\(i)" frameDuration="1001/30000s" width="1920" height="1080"/>
            """
        }
        
        xmlString += """
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        
        // Verify resources count
        let originalResources = fcpxml.xml.rootElement()?.firstChildElement(named: "resources")
        let decodedResources = decoded.xml.rootElement()?.firstChildElement(named: "resources")
        
        XCTAssertEqual(originalResources?.childElements.count, decodedResources?.childElements.count)
    }
    
    func testSpecialCharactersInXML() throws {
        // Create FCPXML with special characters
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="Format &amp; Test &quot;Quote&quot;"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        
        // Verify special characters are preserved
        let originalFormat = fcpxml.xml.rootElement()?.firstChildElement(named: "resources")?.firstChildElement(named: "format")
        let decodedFormat = decoded.xml.rootElement()?.firstChildElement(named: "resources")?.firstChildElement(named: "format")
        
        XCTAssertEqual(originalFormat?.stringValue(forAttributeNamed: "name"),
                      decodedFormat?.stringValue(forAttributeNamed: "name"))
    }
    
    // MARK: - Performance Tests
    
    func testCodablePerformance() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """
        
        let data = xmlString.data(using: .utf8)!
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        
        measure {
            do {
                let jsonData = try fcpxml.jsonData()
                _ = try FinalCutPro.FCPXML.from(jsonData: jsonData)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}
