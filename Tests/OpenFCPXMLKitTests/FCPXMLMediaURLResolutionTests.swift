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
        // Audio-component rows prefer the active audio angle leaf.
        #expect(names.contains("4CH001I.wav"))
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
