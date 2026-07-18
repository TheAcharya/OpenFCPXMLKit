//
//  FCPXMLCodableTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for FCPXML Codable support (JSON/PLIST conversion).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("FCPXML Codable")
struct FCPXMLCodableTests {

    // MARK: - Basic Codable Tests

    @Test("FCPXML Codable encoding/decoding")
    func fcpxmlCodableEncodingDecoding() throws {
        // Create a simple FCPXML document
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997" frameDuration="1001/30000s" width="1920" height="1080"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let original = try FinalCutPro.FCPXML(fileContent: data)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(original)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.self, from: jsonData)

        // Verify the decoded document matches
        #expect(original.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
        #expect(
            original.xml.rootElement()?.stringValue(forAttributeNamed: "version")
                == decoded.xml.rootElement()?.stringValue(forAttributeNamed: "version")
        )
    }

    @Test("Root Codable encoding/decoding")
    func rootCodableEncodingDecoding() throws {
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
        #expect(root.element.name == decoded.element.name)
        #expect(root.version == decoded.version)
    }

    // MARK: - JSON Conversion Tests

    @Test("JSON string conversion")
    func jsonStringConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Convert to JSON string
        let jsonString = try fcpxml.jsonString()

        // Verify it's valid JSON
        #expect(!jsonString.isEmpty)
        #expect(jsonString.contains("xmlString"))

        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(jsonString: jsonString)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("JSON data conversion")
    func jsonDataConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Convert to JSON data
        let jsonData = try fcpxml.jsonData()

        // Verify it's valid JSON
        #expect(!jsonData.isEmpty)

        // Parse JSON to verify structure
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(jsonObject != nil)
        #expect(jsonObject?["xmlString"] as? String != nil)

        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("JSON round-trip preserves structure")
    func jsonRoundTrip() throws {
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

        let data = try #require(xmlString.data(using: .utf8))
        let original = try FinalCutPro.FCPXML(fileContent: data)

        // Round trip through JSON
        let jsonData = try original.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        // Verify structure is preserved
        let originalRoot = original.xml.rootElement()
        let decodedRoot = decoded.xml.rootElement()

        #expect(originalRoot?.name == decodedRoot?.name)
        #expect(
            originalRoot?.stringValue(forAttributeNamed: "version")
                == decodedRoot?.stringValue(forAttributeNamed: "version")
        )

        // Verify resources exist
        let originalResources = originalRoot?.firstChildElement(named: "resources")
        let decodedResources = decodedRoot?.firstChildElement(named: "resources")
        #expect(originalResources != nil)
        #expect(decodedResources != nil)
    }

    // MARK: - PLIST Conversion Tests

    @Test("PLIST string conversion")
    func plistStringConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Convert to PLIST string
        let plistString = try fcpxml.plistString()

        // Verify it's valid PLIST XML
        #expect(!plistString.isEmpty)
        let looksLikePlist = plistString.contains("<?xml") || plistString.contains("<plist")
        #expect(looksLikePlist)

        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(plistString: plistString)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("PLIST data conversion")
    func plistDataConversion() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Convert to PLIST data
        let plistData = try fcpxml.plistData()

        // Verify it's valid PLIST
        #expect(!plistData.isEmpty)

        // Parse PLIST to verify structure
        let plistObject = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        #expect(plistObject != nil)
        #expect(plistObject?["xmlString"] as? String != nil)

        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(plistData: plistData)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("PLIST round-trip preserves structure")
    func plistRoundTrip() throws {
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

        let data = try #require(xmlString.data(using: .utf8))
        let original = try FinalCutPro.FCPXML(fileContent: data)

        // Round trip through PLIST
        let plistData = try original.plistData()
        let decoded = try FinalCutPro.FCPXML.from(plistData: plistData)

        // Verify structure is preserved
        let originalRoot = original.xml.rootElement()
        let decodedRoot = decoded.xml.rootElement()

        #expect(originalRoot?.name == decodedRoot?.name)
        #expect(
            originalRoot?.stringValue(forAttributeNamed: "version")
                == decodedRoot?.stringValue(forAttributeNamed: "version")
        )

        // Verify resources exist
        let originalResources = originalRoot?.firstChildElement(named: "resources")
        let decodedResources = decodedRoot?.firstChildElement(named: "resources")
        #expect(originalResources != nil)
        #expect(decodedResources != nil)
    }

    // MARK: - Converter Utility Tests

    @Test("FCPXMLCodableConverter JSON string")
    func fcpxmlCodableConverterJSONString() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        let jsonString = try FCPXMLCodableConverter.jsonString(from: fcpxml)
        #expect(!jsonString.isEmpty)

        let decoded = try FCPXMLCodableConverter.fcpxml(from: jsonString)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("FCPXMLCodableConverter JSON data")
    func fcpxmlCodableConverterJSONData() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        let jsonData = try FCPXMLCodableConverter.jsonData(from: fcpxml)
        #expect(!jsonData.isEmpty)

        let decoded = try FCPXMLCodableConverter.fcpxml(from: jsonData)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("FCPXMLCodableConverter PLIST string")
    func fcpxmlCodableConverterPlistString() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        let plistString = try FCPXMLCodableConverter.plistString(from: fcpxml)
        #expect(!plistString.isEmpty)

        let decoded = try FCPXMLCodableConverter.fcpxml(fromPlistString: plistString)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("FCPXMLCodableConverter PLIST data")
    func fcpxmlCodableConverterPlistData() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        let plistData = try FCPXMLCodableConverter.plistData(from: fcpxml)
        #expect(!plistData.isEmpty)

        let decoded = try FCPXMLCodableConverter.fcpxml(fromPlistData: plistData)
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    // MARK: - Error Handling Tests

    @Test("Invalid JSON decoding throws")
    func invalidJSONDecoding() throws {
        let invalidJSON = "{ invalid json }"

        do {
            _ = try FinalCutPro.FCPXML.from(jsonString: invalidJSON)
            Issue.record("Expected decoding to throw")
        } catch {
            let isExpectedType = error is DecodingError || error is FCPXMLCodableError
            #expect(isExpectedType)
        }
    }

    @Test("Invalid PLIST decoding throws")
    func invalidPlistDecoding() throws {
        let invalidPlist = "<?xml version=\"1.0\"?><invalid/>"

        do {
            _ = try FinalCutPro.FCPXML.from(plistString: invalidPlist)
            Issue.record("Expected decoding to throw")
        } catch {
            let isExpectedType = error is DecodingError || error is FCPXMLCodableError
            #expect(isExpectedType)
        }
    }

    @Test("Invalid XML string in JSON throws")
    func invalidXMLStringInJSON() throws {
        // Create JSON with invalid XML string
        let invalidJSON = """
        {
            "xmlString": "not valid xml"
        }
        """

        do {
            _ = try FinalCutPro.FCPXML.from(jsonString: invalidJSON)
            Issue.record("Expected decoding to throw")
        } catch {
            let isExpectedType = error is FCPXMLCodableError || error is DecodingError
            #expect(isExpectedType)
        }
    }

    // MARK: - Integration Tests with Real Samples

    @Test("Codable with FCPXML Structure sample")
    func codableWithFCPXMLSample() throws {
        let fcpxml = try requireFCPXMLSample(named: "Structure")

        // Convert to JSON
        let jsonData = try fcpxml.jsonData()
        #expect(!jsonData.isEmpty)

        // Convert back
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        // Verify basic structure
        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
        #expect(fcpxml.version == decoded.version)
    }

    @Test("Codable with import options")
    func codableWithImportOptions() throws {
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

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Convert to JSON and back
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        // Verify import options are preserved
        let originalRootElement = try #require(fcpxml.xml.rootElement())
        let decodedRootElement = try #require(decoded.xml.rootElement())
        let originalRoot = try #require(FinalCutPro.FCPXML.Root(element: originalRootElement))
        let decodedRoot = try #require(FinalCutPro.FCPXML.Root(element: decodedRootElement))

        #expect(
            originalRoot.importOptions?.options.count
                == decodedRoot.importOptions?.options.count
        )
    }

    // MARK: - Edge Cases

    @Test("Empty FCPXML document round-trip")
    func emptyFCPXMLDocument() throws {
        // Create minimal valid FCPXML
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources/>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        #expect(fcpxml.xml.rootElement()?.name == decoded.xml.rootElement()?.name)
    }

    @Test("Large FCPXML document round-trip")
    func largeFCPXMLDocument() throws {
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

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        // Verify resources count
        let originalResources = fcpxml.xml.rootElement()?.firstChildElement(named: "resources")
        let decodedResources = decoded.xml.rootElement()?.firstChildElement(named: "resources")

        #expect(originalResources?.childElements.count == decodedResources?.childElements.count)
    }

    @Test("Special characters in XML are preserved")
    func specialCharactersInXML() throws {
        // Create FCPXML with special characters
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="Format &amp; Test &quot;Quote&quot;"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // Should encode/decode successfully
        let jsonData = try fcpxml.jsonData()
        let decoded = try FinalCutPro.FCPXML.from(jsonData: jsonData)

        // Verify special characters are preserved
        let originalFormat = fcpxml.xml.rootElement()?.firstChildElement(named: "resources")?.firstChildElement(named: "format")
        let decodedFormat = decoded.xml.rootElement()?.firstChildElement(named: "resources")?.firstChildElement(named: "format")

        #expect(
            originalFormat?.stringValue(forAttributeNamed: "name")
                == decodedFormat?.stringValue(forAttributeNamed: "name")
        )
    }

    // MARK: - Performance Tests

    @Test("Codable encode/decode completes")
    func codablePerformance() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
            <resources>
                <format id="r1" name="FFVideoFormat1080p2997"/>
            </resources>
        </fcpxml>
        """

        let data = try #require(xmlString.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)

        // XCTest `measure` has no Swift Testing equivalent; exercise the same round-trip.
        let jsonData = try fcpxml.jsonData()
        _ = try FinalCutPro.FCPXML.from(jsonData: jsonData)
    }
}

