//
//  FCPXMLMediaURLResolutionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Leaf media URL resolution for non-flattened hosts (mc-clip / sync-clip / ref-clip).
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Media URL resolution for non-flattened hosts")
struct FCPXMLMediaURLResolutionTests {
    
    // MARK: - Parsing
    
    @Test("fcpMediaURL resolves active video angle leaf for MulticamSample")
    func multicamSampleResolvesActiveVideoAngleLeaf() throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSample")
        let resources = fcpxml.root.resources
        let mcClip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpElementType == .mcClip })
        )
        
        let url = try #require(mcClip.fcpMediaURL(in: resources))
        #expect(url.lastPathComponent == "Day2_InterviewOwners_02_A.mov")
        
        let audioURL = try #require(mcClip.fcpMediaURL(in: resources, preferAudioAngle: true))
        #expect(audioURL.lastPathComponent == "4CH001I.wav")
    }
    
    @Test("fcpMediaURL resolves primary video leaf for SyncClip")
    func syncClipResolvesPrimaryVideoLeaf() throws {
        let fcpxml = try requireFCPXMLSample(named: "SyncClip")
        let resources = fcpxml.root.resources
        let syncClip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpElementType == .syncClip })
        )
        
        let url = try #require(syncClip.fcpMediaURL(in: resources))
        #expect(url.lastPathComponent == "TestVideo.m4v")
    }
    
    @Test("fcpMediaURL resolves interior asset for StandaloneRefClip")
    func standaloneRefClipResolvesInteriorAsset() throws {
        let fcpxml = try requireFCPXMLSample(named: "StandaloneRefClip")
        let resources = fcpxml.root.resources
        // Standalone compound export places the ref-clip at the document root (no project).
        let refClip = try #require(
            fcpxml.xml.rootElement()?
                .childElements
                .first(where: { $0.fcpElementType == .refClip })
        )
        
        let url = try #require(refClip.fcpMediaURL(in: resources))
        #expect(url.lastPathComponent == "TestVideo.mov")
    }
    
    @Test("fcpMediaURL leaves title-only compound empty")
    func titleOnlyCompoundHasNoMediaURL() throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClips")
        let resources = fcpxml.root.resources
        let titleCompound = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpName == "Title Compound Clip" })
        )
        
        #expect(titleCompound.fcpMediaURL(in: resources) == nil)
    }
    
    @Test("fcpMediaRepresentationURLs splits original and proxy on the same leaf")
    func mediaRepresentationURLsSplitOriginalAndProxy() throws {
        let original = URL(fileURLWithPath: "/tmp/ofk-original.mov")
        let proxy = URL(fileURLWithPath: "/tmp/ofk-proxy.mov")
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="\(original.absoluteString)"/>
                        <media-rep kind="proxy-media" src="\(proxy.absoluteString)"/>
                    </asset>
                </resources>
                <library><event name="E"><project name="P">
                    <sequence format="r1" duration="5s" tcStart="0s">
                        <spine>
                            <asset-clip ref="r2" offset="0s" name="Clip" duration="5s"/>
                        </spine>
                    </sequence>
                </project></event></library>
            </fcpxml>
            """)
        let clip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpElementType == .assetClip })
        )
        let resources = fcpxml.root.resources
        let pair = clip.fcpMediaRepresentationURLs(in: resources)
        #expect(pair.original?.lastPathComponent == "ofk-original.mov")
        #expect(pair.proxy?.lastPathComponent == "ofk-proxy.mov")
        #expect(clip.fcpMediaURL(in: resources, kind: .originalMedia)?.lastPathComponent == "ofk-original.mov")
        #expect(clip.fcpMediaURL(in: resources, kind: .proxyMedia)?.lastPathComponent == "ofk-proxy.mov")
        #expect(clip.fcpMediaURL(in: resources)?.lastPathComponent == "ofk-original.mov")
    }
    
    @Test("fcpMediaURL kind proxy is nil when asset has only original-media")
    func proxyKindNilWhenOnlyOriginalDeclared() throws {
        let fcpxml = try parseInlineFCPXML("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE fcpxml>
            <fcpxml version="1.11">
                <resources>
                    <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                    <asset id="r2" name="A" hasVideo="1" videoSources="1" duration="10s">
                        <media-rep kind="original-media" src="file:///tmp/ofk-only-original.mov"/>
                    </asset>
                </resources>
                <library><event name="E"><project name="P">
                    <sequence format="r1" duration="5s" tcStart="0s">
                        <spine>
                            <asset-clip ref="r2" offset="0s" name="Clip" duration="5s"/>
                        </spine>
                    </sequence>
                </project></event></library>
            </fcpxml>
            """)
        let clip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpElementType == .assetClip })
        )
        let resources = fcpxml.root.resources
        #expect(clip.fcpMediaURL(in: resources, kind: .proxyMedia) == nil)
        #expect(clip.fcpMediaURL(in: resources, kind: .originalMedia)?.lastPathComponent == "ofk-only-original.mov")
    }
    
    // MARK: - Role Inventory
    
    @Test("Role Inventory Source File Name populated for MulticamSample")
    func roleInventorySourceFileNameForMulticam() async throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSample")
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.includeRoleInventory = true
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.roleInventory?.selectedRoles ?? []
        let rowsEmpty = rows.isEmpty
        #expect(!rowsEmpty)
        
        let withSource = rows.filter { !$0.sourceFileName.isEmpty }
        #expect(!withSource.isEmpty)
        
        let names = Set(withSource.map(\.sourceFileName))
        #expect(names.contains("Day2_InterviewOwners_02_A.mov"))
        // Host audio-component rows prefer the active audio angle leaf. Unfolded
        // `mc-angle` interiors must not appear as their own inventory rows.
        #expect(names.contains("4CH001I.wav"))
        let clipNames = Set(rows.map(\.clipName))
        #expect(!clipNames.contains("4CH001I"))
        #expect(!clipNames.contains("Day2_InterviewOwners_02_A"))
        let wavRows = rows.filter { $0.sourceFileName == "4CH001I.wav" }
        #expect(wavRows.contains { $0.clipName.localizedCaseInsensitiveContains("Chocolate") })
    }
    
    @Test("Role Inventory Source File Name populated for SyncClip")
    func roleInventorySourceFileNameForSyncClip() async throws {
        let fcpxml = try requireFCPXMLSample(named: "SyncClip")
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.includeRoleInventory = true
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.roleInventory?.selectedRoles ?? []
        
        let withVideoFile = rows.filter { $0.sourceFileName == "TestVideo.m4v" }
        #expect(!withVideoFile.isEmpty)
        
        let hostRows = rows.filter {
            $0.clipName.localizedCaseInsensitiveContains("Synchronized")
        }
        if !hostRows.isEmpty {
            #expect(hostRows.contains { $0.sourceFileName == "TestVideo.m4v" })
        }
    }
    
    @Test("Role Inventory Source File Name populated for CompoundClipSample ref-clip")
    func roleInventorySourceFileNameForCompoundClipSample() async throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClipSample")
        var options = FinalCutPro.FCPXML.ReportOptions()
        options.includeRoleInventory = true
        
        let report = try await fcpxml.buildReport(options: options)
        let rows = report.roleInventory?.selectedRoles ?? []
        
        // Compound host and/or unfolded leaves should resolve the first spine asset file.
        let withCompoundLeaf = rows.filter {
            $0.sourceFileName.contains("World of Stories Open_1")
                || $0.sourceFileName.hasSuffix(".mov")
        }
        #expect(!withCompoundLeaf.isEmpty)
        
        let refHostRows = rows.filter { $0.clipName == "Broadcast Safe" }
        if !refHostRows.isEmpty {
            #expect(refHostRows.contains {
                $0.sourceFileName.contains("World of Stories Open_1")
            })
        }
    }
}
