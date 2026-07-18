//
//  FCPXMLTestingSampleSupport.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Swift Testing sample / fixture helpers (Test.cancel for optional fixtures).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

/// Loads a **bundled** public sample. Missing samples fail the test (not skip).
func requireFCPXMLSampleData(named name: String) throws -> Data {
    try tryLoadFCPXMLSampleData(named: name)
}

/// Loads a **bundled** public sample as ``FinalCutPro/FCPXML``. Missing samples fail.
func requireFCPXMLSample(named name: String) throws -> FinalCutPro.FCPXML {
    try tryLoadFCPXMLSample(named: name)
}

@available(macOS 26.0, *)
func requireTimelineElement(fromSampleNamed name: String) throws -> any OFKXMLElement {
    try tryTimelineElement(fromSampleNamed: name)
}

@available(macOS 26.0, *)
func requireFirstProject(fromSampleNamed name: String) throws -> FinalCutPro.FCPXML.Project {
    try tryFirstProject(fromSampleNamed: name)
}

func requireExtractedHost(
    from fcpxml: FinalCutPro.FCPXML,
    elementName: String,
    where predicate: ((any OFKXMLElement) -> Bool)? = nil
) throws -> FinalCutPro.FCPXML.ExtractedElement {
    try tryMakeExtractedHost(from: fcpxml, elementName: elementName, where: predicate)
}

/// Cancels (skips) the current test when a bundled sample is absent.
/// Prefer ``requireFCPXMLSample(named:)`` for package resources that must exist in CI.
func cancelIfSampleMissing(named name: String) throws {
    guard fcpxmlSampleExists(named: name) else {
        try Test.cancel("Sample not found: \(name).fcpxml")
    }
}

/// Loads the optional reporting integration fixture, or cancels when unset / missing.
func requireReportingFixtureFCPXML() throws -> FinalCutPro.FCPXML {
    do {
        return try FCPXMLReportingReportFixture.tryLoadFCPXML()
    } catch let error as FCPXMLTestSampleError where error.isOptionalFixtureAbsence {
        try Test.cancel("\(error.description)")
    }
}

func requireReportingFixtureMediaBaseURL() throws -> URL {
    do {
        return try FCPXMLReportingReportFixture.tryMediaBaseURL()
    } catch let error as FCPXMLTestSampleError where error.isOptionalFixtureAbsence {
        try Test.cancel("\(error.description)")
    }
}

/// Lists submitted-inbox items, or cancels when the private inbox is empty.
func requireSubmittedInboxItems(
    relativeToFile fileURL: URL = URL(fileURLWithPath: #filePath)
) throws -> [URL] {
    let items = FCPXMLSubmittedInbox.items(relativeToFile: fileURL)
    guard !items.isEmpty else {
        try Test.cancel("\(FCPXMLTestSampleError.submittedInboxEmpty.description)")
    }
    return items
}
