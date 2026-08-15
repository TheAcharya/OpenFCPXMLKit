//
//  FCPXMLRoleInventoryScreenshotMediaTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Role Inventory screenshot original / proxy candidate ordering.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory screenshot media")
struct FCPXMLRoleInventoryScreenshotMediaTests {
    
    @Test("On-disk original is preferred over on-disk proxy")
    func onDiskOriginalPreferredOverProxy() throws {
        let (original, proxy, cleanup) = try writePair(originalExists: true, proxyExists: true)
        defer { cleanup() }
        
        let ordered = FinalCutPro.FCPXML.RoleInventoryScreenshotMedia.orderedCandidateURLs(
            original: original,
            proxy: proxy,
            mediaBaseURL: nil
        )
        #expect(ordered.count == 2)
        #expect(ordered[0].lastPathComponent == original.lastPathComponent)
        #expect(ordered[1].lastPathComponent == proxy.lastPathComponent)
    }
    
    @Test("Missing proxy falls back to on-disk original")
    func missingProxyFallsBackToOriginal() throws {
        let (original, proxy, cleanup) = try writePair(originalExists: true, proxyExists: false)
        defer { cleanup() }
        
        let ordered = FinalCutPro.FCPXML.RoleInventoryScreenshotMedia.orderedCandidateURLs(
            original: original,
            proxy: proxy,
            mediaBaseURL: nil
        )
        #expect(ordered.map(\.lastPathComponent) == [original.lastPathComponent])
    }
    
    @Test("Missing original uses on-disk proxy alone")
    func missingOriginalUsesOnDiskProxy() throws {
        let (original, proxy, cleanup) = try writePair(originalExists: false, proxyExists: true)
        defer { cleanup() }
        
        let ordered = FinalCutPro.FCPXML.RoleInventoryScreenshotMedia.orderedCandidateURLs(
            original: original,
            proxy: proxy,
            mediaBaseURL: nil
        )
        #expect(ordered.map(\.lastPathComponent) == [proxy.lastPathComponent])
    }
    
    @Test("Neither on disk keeps declared original then proxy")
    func neitherOnDiskKeepsDeclaredOrder() {
        let original = URL(fileURLWithPath: "/tmp/ofk-declared-original-\(UUID().uuidString).mov")
        let proxy = URL(fileURLWithPath: "/tmp/ofk-declared-proxy-\(UUID().uuidString).mov")
        
        let ordered = FinalCutPro.FCPXML.RoleInventoryScreenshotMedia.orderedCandidateURLs(
            original: original,
            proxy: proxy,
            mediaBaseURL: nil
        )
        #expect(ordered.map(\.lastPathComponent) == [
            original.lastPathComponent,
            proxy.lastPathComponent
        ])
    }
    
    @Test("mediaBaseURL resolves relative proxy by filename")
    func mediaBaseURLResolvesProxyByFilename() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-base-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let proxyOnDisk = directory.appendingPathComponent("clip-proxy.mov")
        try Data([0x00]).write(to: proxyOnDisk)
        
        let original = URL(fileURLWithPath: "/Volumes/Offline/clip-original.mov")
        let proxy = URL(fileURLWithPath: "/Volumes/Offline/clip-proxy.mov")
        
        let ordered = FinalCutPro.FCPXML.RoleInventoryScreenshotMedia.orderedCandidateURLs(
            original: original,
            proxy: proxy,
            mediaBaseURL: directory
        )
        #expect(ordered.count == 1)
        #expect(ordered[0].path == proxyOnDisk.path)
    }
    
    @Test("Screenshot target prefers original and keeps proxy as fallback")
    func screenshotTargetPrefersOriginalAndKeepsProxyFallback() async throws {
        let (original, proxy, cleanup) = try writePair(originalExists: true, proxyExists: true)
        defer { cleanup() }
        
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="A" start="3600s" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="\(original.absoluteString)"/>
                        <media-rep kind="proxy-media" src="\(proxy.absoluteString)"/>
                    </asset>
                </resources>
                <library><event name="E"><project name="P">
                    <sequence format="r1" duration="5s" tcStart="0s">
                        <spine>
                            <asset-clip ref="r2" offset="0s" name="Clip" start="3601s" duration="5s"/>
                        </spine>
                    </sequence>
                </project></event></library>
            </fcpxml>
            """)
        
        var options = FinalCutPro.FCPXML.ReportOptions.roleInventoryOnly
        options.includeScreenshotsInRoleInventory = true
        let report = try await fcpxml.buildReport(options: options)
        let row = try #require(report.roleInventory?.selectedRoles.first)
        
        #expect(row.screenshotMediaFileURL?.lastPathComponent == original.lastPathComponent)
        #expect(row.screenshotFallbackMediaFileURL?.lastPathComponent == proxy.lastPathComponent)
        #expect(row.screenshotFileTimeSeconds == 1)
        #expect(row.sourceFileName == original.lastPathComponent)
    }
    
    private func writePair(
        originalExists: Bool,
        proxyExists: Bool
    ) throws -> (original: URL, proxy: URL, cleanup: () -> Void) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-pair-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let original = directory.appendingPathComponent("original.mov")
        let proxy = directory.appendingPathComponent("proxy.mov")
        if originalExists {
            try Data([0x00]).write(to: original)
        }
        if proxyExists {
            try Data([0x00]).write(to: proxy)
        }
        
        return (original, proxy, {
            try? FileManager.default.removeItem(at: directory)
        })
    }
}
