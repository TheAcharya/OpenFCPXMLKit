//
//  ExcelReportFixture.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Local FCPXML fixture resolution for Excel report integration tests.
//

import Foundation
import Testing

enum ExcelReportFixture {
    static let preferredBundleName = "Sample.fcpxmld"
    static let preferredFileName = "Sample.fcpxml"
    static let outputDirectoryName = "Output"
    static let environmentVariableName = "OFK_REPORTING_FCPXML_BUNDLE"
    
    static let defaultOutputFileName = "OFK-Default.xlsx"
    static let fullOutputFileName = "OFK-Full.xlsx"
    static let defaultOutputPDFFileName = "OFK-Default.pdf"
    static let fullOutputPDFFileName = "OFK-Full.pdf"
    static let copyrightOutputXLSXFileName = "OFK-Copyright.xlsx"
    static let copyrightOutputPDFFileName = "OFK-Copyright.pdf"
    static let outsideClipBoundariesOutputXLSXFileName = "OFK-OutsideClipBoundaries.xlsx"
    static let outsideClipBoundariesOutputPDFFileName = "OFK-OutsideClipBoundaries.pdf"
    static let protectedSheetsOutputXLSXFileName = "OFK-ProtectedSheets.xlsx"
    
    /// URL to a `.fcpxml` file or `.fcpxmld` bundle directory.
    static func fixtureURL() -> URL? {
        if let path = ProcessInfo.processInfo.environment[environmentVariableName],
           !path.isEmpty
        {
            let url = URL(fileURLWithPath: path)
            if isValidFixture(at: url) {
                return url
            }
        }
        
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        
        let outputDirectory = testDirectory.appendingPathComponent(outputDirectoryName, isDirectory: true)
        let preferredURLs = [
            testDirectory.appendingPathComponent(preferredBundleName, isDirectory: true),
            testDirectory.appendingPathComponent(preferredFileName),
            // Local investigation fixtures may live under Output/ beside generated workbooks.
            outputDirectory.appendingPathComponent(preferredBundleName, isDirectory: true),
            outputDirectory.appendingPathComponent(preferredFileName),
        ]
        
        for url in preferredURLs where isValidFixture(at: url) {
            return url
        }
        
        return discoverFixture(in: testDirectory)
            ?? discoverFixture(in: outputDirectory)
    }
    
    /// Resolves a fixture URL or cancels the current Swift Testing test when none is available.
    static func requireFixtureURL() throws -> URL {
        guard let url = fixtureURL() else {
            let message =
                "Excel report fixture unavailable. Add \(preferredBundleName) or " +
                "\(preferredFileName) under Tests/ExcelReportTest/, or set " +
                "\(environmentVariableName) to a .fcpxml file or .fcpxmld bundle path."
            try Test.cancel("\(message)")
        }
        return url
    }
    
    /// Base directory for resolving relative media paths in the Media Summary sheet.
    static func mediaBaseURL(for fixtureURL: URL) -> URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fixtureURL.path, isDirectory: &isDirectory) else {
            return fixtureURL.deletingLastPathComponent()
        }
        
        return isDirectory.boolValue
            ? fixtureURL
            : fixtureURL.deletingLastPathComponent()
    }
    
    static func outputDirectoryURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(outputDirectoryName, isDirectory: true)
    }
    
    private static func discoverFixture(in directory: URL) -> URL? {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        let candidates = entries
            .filter { url in
                let name = url.lastPathComponent
                if name == outputDirectoryName
                    || name.hasSuffix(".swift")
                    || name.hasSuffix(".md")
                    || name.hasSuffix(".xlsx")
                    || name.hasSuffix(".pdf")
                {
                    return false
                }
                
                return isValidFixture(at: url)
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        return candidates.first
    }
    
    private static func isValidFixture(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        
        if isDirectory.boolValue {
            let infoURL = url.appendingPathComponent("Info.fcpxml")
            return FileManager.default.fileExists(atPath: infoURL.path)
        }
        
        return url.pathExtension.lowercased() == "fcpxml"
    }
}

