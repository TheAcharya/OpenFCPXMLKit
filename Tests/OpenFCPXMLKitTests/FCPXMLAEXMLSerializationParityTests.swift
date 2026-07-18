//
//  FCPXMLAEXMLSerializationParityTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//  WU4 Sortie 8: AEXML Serialization Parity Tests
//
//  Validates that the AEXML backend correctly round-trips FCPXML documents
//  and produces structurally equivalent output compared to the Foundation backend.
//
//  These tests use two sample files:
//  - "BasicMarkers" — a relatively simple FCPXML with markers, text styles,
//    smart collections, and a single project/event structure.
//  - "24" — a complex FCPXML with multiple assets, compound clips, transitions,
//    timeMaps, nested spines, metadata arrays, and comments.
//
//  KNOWN SERIALIZATION DIFFERENCES (Foundation vs AEXML):
//
//  1. ATTRIBUTE ORDERING: Foundation's XMLElement preserves attribute insertion
//     order (or source order); AEXML stores attributes in a Swift Dictionary,
//     so attribute order is non-deterministic. Structural comparison ignores
//     attribute order by comparing sorted attribute sets.
//
//  2. WHITESPACE / INDENTATION: Foundation's nodePrettyPrint and AEXML's `.xml`
//     use different indentation strategies. Foundation may use tab characters or
//     varying space counts; AEXML uses 4-space indentation by default. Raw string
//     comparison is therefore unreliable — we compare structure, not text.
//
//  3. EMPTY ELEMENT STYLE: Foundation with nodeCompactEmptyElement produces
//     `<tag/>`, while AEXML always serializes childless elements as `<tag />`
//     (with a space before the slash). This is a cosmetic difference only.
//
//  4. XML DECLARATION HEADER: Foundation's XMLDocument includes an XML declaration
//     (`<?xml version="1.0" encoding="UTF-8"?>`) that may differ from AEXML's
//     header (which always includes `standalone="no"` unless configured otherwise).
//
//  5. DOCTYPE / DTD: Foundation preserves `<!DOCTYPE fcpxml>` from the source;
//     AEXML strips it (AEXML does not support DTD). The root element structure
//     is unaffected.
//
//  6. COMMENT NODES: Foundation's XMLDocument preserves XML comments as child
//     nodes; AEXML silently drops them during parsing. This means child counts
//     may differ when comments are present in the source. The structural
//     comparison accounts for this by comparing only element children.
//
//  7. TEXT NODE HANDLING: Foundation may create separate text nodes for whitespace
//     between elements; AEXML collapses or ignores inter-element whitespace.
//     Structural comparison focuses on element children, not text nodes.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

// Both backends are available on macOS.
#if canImport(FoundationXML) || os(macOS)

@Suite("AEXML serialization parity")
struct FCPXMLAEXMLSerializationParityTests {

    // MARK: - Factories

    private let aeFactory = AEXMLBackendFactory()
    private let foundationFactory = FoundationXMLFactory()

    // MARK: - Sample File Names

    /// Sample names used in these tests (at least 2 as required by Sortie 8).
    private static let sampleNames = ["BasicMarkers", "24"]

    // MARK: - Round-Trip Tests (AEXML)
    //
    // Parse FCPXML via AEXML → serialize → re-parse → compare structure.
    // This validates that AEXML can faithfully round-trip FCPXML documents.

    @Test("AEXML round trip BasicMarkers")
    func aexmlRoundTrip_BasicMarkers() throws {
        try assertAEXMLRoundTrip(sampleName: "BasicMarkers")
    }

    @Test("AEXML round trip 24")
    func aexmlRoundTrip_24() throws {
        try assertAEXMLRoundTrip(sampleName: "24")
    }

    // MARK: - Comparison Tests (Foundation vs AEXML)
    //
    // Parse the same FCPXML file through both backends and compare structural
    // equivalence: element names, attribute names + values, child element counts.

    @Test("Backend parity BasicMarkers")
    func backendParity_BasicMarkers() throws {
        try assertBackendParity(sampleName: "BasicMarkers")
    }

    @Test("Backend parity 24")
    func backendParity_24() throws {
        try assertBackendParity(sampleName: "24")
    }

    // MARK: - Round-Trip Implementation

    /// Parses a sample via AEXML, serializes, re-parses, and compares structure.
    private func assertAEXMLRoundTrip(sampleName: String) throws {
        let data = try requireFCPXMLSampleData(named: sampleName)

        // Parse original
        let originalDoc = try aeFactory.makeDocument(data: data, options: [])
        let originalRoot = try #require(originalDoc.rootElement())

        // Serialize to data
        let serializedData = originalDoc.xmlData(options: [])
        #expect(!serializedData.isEmpty, "AEXML serialization produced empty data for \(sampleName)")

        // Re-parse the serialized output
        let reparsedDoc = try aeFactory.makeDocument(data: serializedData, options: [])
        let reparsedRoot = try #require(reparsedDoc.rootElement())

        // Compare structure recursively
        let differences = compareElements(originalRoot, reparsedRoot, path: "")
        if !differences.isEmpty {
            let report = differences.joined(separator: "\n")
            Issue.record(
                Comment(rawValue: "AEXML round-trip structural differences in \(sampleName).fcpxml (\(differences.count) difference(s)):\n\(report)")
            )
        }
    }

    // MARK: - Backend Parity Implementation

    /// Parses a sample through both Foundation and AEXML backends and compares
    /// structural equivalence.
    private func assertBackendParity(sampleName: String) throws {
        let data = try requireFCPXMLSampleData(named: sampleName)

        // Parse via Foundation
        let foundationDoc = try foundationFactory.makeDocument(data: data, options: [])
        let foundationRoot = try #require(foundationDoc.rootElement())

        // Parse via AEXML
        let aeDoc = try aeFactory.makeDocument(data: data, options: [])
        let aeRoot = try #require(aeDoc.rootElement())

        // Compare structure recursively
        let differences = compareElements(foundationRoot, aeRoot, path: "")
        if !differences.isEmpty {
            let report = differences.joined(separator: "\n")
            Issue.record(
                Comment(rawValue: "Backend parity structural differences in \(sampleName).fcpxml (\(differences.count) difference(s)):\n\(report)")
            )
        }
    }

    // MARK: - Structural Comparison

    /// Recursively compares two elements and returns a list of structural differences.
    ///
    /// Compares:
    /// - Element names
    /// - Attribute names and values (sorted, since AEXML may reorder attributes)
    /// - Child element counts and child structure (recursively)
    ///
    /// Does NOT compare:
    /// - Text node whitespace (known difference)
    /// - Attribute ordering (known difference — AEXML uses Dictionary)
    /// - Comment nodes (AEXML drops comments)
    /// - Raw XML string output
    private func compareElements(
        _ lhs: any OFKXMLElement,
        _ rhs: any OFKXMLElement,
        path: String
    ) -> [String] {
        var diffs: [String] = []

        let lhsName = lhs.name ?? "(nil)"
        let rhsName = rhs.name ?? "(nil)"
        let currentPath = path.isEmpty ? lhsName : "\(path)/\(lhsName)"

        // 1. Compare element names
        if lhsName != rhsName {
            diffs.append("[\(currentPath)] Name mismatch: '\(lhsName)' vs '\(rhsName)'")
            // If names don't match, child comparison is meaningless
            return diffs
        }

        // 2. Compare attributes (sorted by name to account for ordering differences)
        let lhsAttrs = lhs.attributes.sorted { $0.name < $1.name }
        let rhsAttrs = rhs.attributes.sorted { $0.name < $1.name }

        let lhsAttrNames = lhsAttrs.map(\.name)
        let rhsAttrNames = rhsAttrs.map(\.name)

        if lhsAttrNames != rhsAttrNames {
            let missing = Set(lhsAttrNames).subtracting(rhsAttrNames)
            let extra = Set(rhsAttrNames).subtracting(lhsAttrNames)
            if !missing.isEmpty {
                diffs.append("[\(currentPath)] Missing attributes in RHS: \(missing.sorted())")
            }
            if !extra.isEmpty {
                diffs.append("[\(currentPath)] Extra attributes in RHS: \(extra.sorted())")
            }
        } else {
            // Names match — compare values
            for (lAttr, rAttr) in zip(lhsAttrs, rhsAttrs) {
                if lAttr.value != rAttr.value {
                    diffs.append(
                        "[\(currentPath)] Attribute '\(lAttr.name)' value mismatch: "
                        + "'\(lAttr.value)' vs '\(rAttr.value)'"
                    )
                }
            }
        }

        // 3. Compare child elements (ignoring text/comment nodes — known difference)
        let lhsChildren = lhs.childElements
        let rhsChildren = rhs.childElements

        if lhsChildren.count != rhsChildren.count {
            diffs.append(
                "[\(currentPath)] Child element count mismatch: "
                + "\(lhsChildren.count) vs \(rhsChildren.count)"
            )
            // Still compare up to the minimum child count
            let minCount = min(lhsChildren.count, rhsChildren.count)
            for i in 0..<minCount {
                diffs.append(contentsOf: compareElements(
                    lhsChildren[i], rhsChildren[i],
                    path: "\(currentPath)[\(i)]"
                ))
            }
        } else {
            for i in 0..<lhsChildren.count {
                diffs.append(contentsOf: compareElements(
                    lhsChildren[i], rhsChildren[i],
                    path: "\(currentPath)[\(i)]"
                ))
            }
        }

        // 4. Compare text content (stringValue) for leaf elements only.
        // Leaf elements are those with no child elements.
        // Known difference: AEXML may handle whitespace differently for
        // non-leaf elements, so we only compare leaf text content.
        if lhsChildren.isEmpty && rhsChildren.isEmpty {
            let lhsValue = lhs.stringValue ?? ""
            let rhsValue = rhs.stringValue ?? ""
            // Trim whitespace for comparison since backends may handle
            // leading/trailing whitespace differently.
            if lhsValue.trimmingCharacters(in: .whitespacesAndNewlines)
                != rhsValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                diffs.append(
                    "[\(currentPath)] Text content mismatch: "
                    + "'\(lhsValue)' vs '\(rhsValue)'"
                )
            }
        }

        return diffs
    }

    // MARK: - Additional Validation Tests

    /// Verifies that AEXML can parse all FCPXML samples without throwing.
    @Test("AEXML parses all samples")
    func aexmlParsesAllSamples() throws {
        let sampleNames = allFCPXMLSampleNames()
        guard !sampleNames.isEmpty else {
            try Test.cancel("No FCPXML samples found")
        }

        var failures: [(name: String, error: String)] = []

        for name in sampleNames {
            do {
                let data = try requireFCPXMLSampleData(named: name)
                let doc = try aeFactory.makeDocument(data: data, options: [])
                // Verify root element exists
                guard doc.rootElement() != nil else {
                    failures.append((name: name, error: "No root element"))
                    continue
                }
            } catch {
                failures.append((name: name, error: error.localizedDescription))
            }
        }

        if !failures.isEmpty {
            let report = failures
                .map { "\($0.name): \($0.error)" }
                .joined(separator: "\n")
            Issue.record("AEXML failed to parse \(failures.count) sample(s):\n\(report)")
        }
    }

    /// Verifies that AEXML and Foundation agree on basic document metadata
    /// (root element name, version attribute) for all samples.
    @Test("Root element parity all samples")
    func rootElementParityAllSamples() throws {
        let sampleNames = allFCPXMLSampleNames()
        guard !sampleNames.isEmpty else {
            try Test.cancel("No FCPXML samples found")
        }

        var failures: [String] = []

        for name in sampleNames {
            do {
                let data = try requireFCPXMLSampleData(named: name)

                let foundationDoc = try foundationFactory.makeDocument(data: data, options: [])
                let aeDoc = try aeFactory.makeDocument(data: data, options: [])

                let fRoot = foundationDoc.rootElement()
                let aRoot = aeDoc.rootElement()

                if fRoot?.name != aRoot?.name {
                    failures.append(
                        "\(name): root name mismatch — "
                        + "Foundation='\(fRoot?.name ?? "nil")' vs "
                        + "AEXML='\(aRoot?.name ?? "nil")'"
                    )
                }

                let fVersion = fRoot?.attribute(forName: "version")
                let aVersion = aRoot?.attribute(forName: "version")
                if fVersion != aVersion {
                    failures.append(
                        "\(name): version attribute mismatch — "
                        + "Foundation='\(fVersion ?? "nil")' vs "
                        + "AEXML='\(aVersion ?? "nil")'"
                    )
                }
            } catch {
                failures.append("\(name): parse error — \(error.localizedDescription)")
            }
        }

        if !failures.isEmpty {
            let report = failures.joined(separator: "\n")
            Issue.record("Root element parity failures (\(failures.count)):\n\(report)")
        }
    }

    /// Verifies that AEXML's validate() throws dtdValidationUnavailable.
    @Test("AEXML validate throws DTD unavailable")
    func aexmlValidateThrowsDTDUnavailable() throws {
        let doc = aeFactory.makeDocument() as! AEXMLBackendDocument
        do {
            try doc.validate()
            Issue.record("expected throw")
        } catch {
            guard let xmlError = error as? OFKXMLError else {
                Issue.record("Expected OFKXMLError, got \(type(of: error))")
                return
            }
            #expect(xmlError == .dtdValidationUnavailable)
        }
    }
}

#endif

