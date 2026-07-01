//
//  FCPXMLTestUtilities.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Test helper functions for loading FCPXML samples.
//

import Foundation
import XCTest
@testable import OpenFCPXMLKit

/// Loads FCPXML sample data by name. Throws XCTSkip if file is missing.
func loadFCPXMLSampleData(named name: String) throws -> Data {
    let url = urlForFCPXMLSample(named: name)
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw XCTSkip("Sample not found: \(name).fcpxml at \(url.path)")
    }
    return try Data(contentsOf: url)
}

/// Loads FCPXML as FinalCutPro.FCPXML from a sample by name. Throws XCTSkip if file missing.
func loadFCPXMLSample(named name: String) throws -> FinalCutPro.FCPXML {
    let data = try loadFCPXMLSampleData(named: name)
    return try FinalCutPro.FCPXML(fileContent: data)
}

/// Parses inline FCPXML for unit tests.
func parseInlineFCPXML(_ xml: String) throws -> FinalCutPro.FCPXML {
    try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
}

@available(macOS 26.0, *)
func timelineElement(fromSampleNamed name: String) throws -> any OFKXMLElement {
    let fcpxml = try loadFCPXMLSample(named: name)
    guard let project = fcpxml.allProjects().first else {
        throw XCTSkip("No project in sample \(name)")
    }
    return project.sequence.element
}

@available(macOS 26.0, *)
func firstProject(fromSampleNamed name: String) throws -> FinalCutPro.FCPXML.Project {
    let fcpxml = try loadFCPXMLSample(named: name)
    guard let project = fcpxml.allProjects().first else {
        throw XCTSkip("No project in sample \(name)")
    }
    return project
}

func interpolatedRole(_ rawValue: String) -> FinalCutPro.FCPXML.AnyInterpolatedRole {
    guard let role = FinalCutPro.FCPXML.AnyInterpolatedRole(rawValue: rawValue) else {
        XCTFail("Could not create role from raw value: \(rawValue)")
        return .assigned(.video(.init(role: rawValue)))
    }
    return role
}

func firstDescendantElement(
    in root: any OFKXMLElement,
    named name: String,
    where predicate: ((any OFKXMLElement) -> Bool)? = nil
) -> (any OFKXMLElement)? {
    if root.name == name, predicate?(root) ?? true {
        return root
    }
    for child in root.childElements {
        if let match = firstDescendantElement(in: child, named: name, where: predicate) {
            return match
        }
    }
    return nil
}

func makeExtractedHost(
    from fcpxml: FinalCutPro.FCPXML,
    elementName: String,
    where predicate: ((any OFKXMLElement) -> Bool)? = nil
) throws -> FinalCutPro.FCPXML.ExtractedElement {
    let element = try XCTUnwrap(
        firstDescendantElement(in: fcpxml.root.element, named: elementName, where: predicate)
    )
    return FinalCutPro.FCPXML.ExtractedElement(
        element: element,
        breadcrumbs: [],
        resources: fcpxml.root.resources
    )
}

func makeExtractedEffect(
    name: String,
    kind: FinalCutPro.FCPXML.ExtractedEffect.Kind = .filterVideo,
    host: FinalCutPro.FCPXML.ExtractedElement,
    settings: FinalCutPro.FCPXML.ExtractedEffect.Settings? = nil
) -> FinalCutPro.FCPXML.ExtractedEffect {
    FinalCutPro.FCPXML.ExtractedEffect(
        host: host,
        timelineContext: nil,
        effectElement: host.element,
        kind: kind,
        name: name,
        settings: settings ?? .text(name),
        sortOrder: 0,
        isAppleSupplied: false
    )
}

/// Frame rate sample names (one test file per frame rate in DAW).
let fcpxmlFrameRateSampleNames: [String] = [
    "23.98", "24", "24With25Media", "25i", "29.97", "29.97d", "30", "50", "59.94", "60"
]

/// All sample names for smoke/iteration tests.
func allFCPXMLSampleNames() -> [String] {
    let dir = fcpxmlSamplesDirectory()
    guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
        return []
    }
    var names: [String] = []
    for case let url as URL in enumerator {
        guard url.pathExtension == "fcpxml" else { continue }
        names.append(url.deletingPathExtension().lastPathComponent)
    }
    return names.sorted()
}
