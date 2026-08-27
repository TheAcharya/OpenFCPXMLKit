//
//  FCPXMLPublicMediaLeafAPITests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Public-import coverage for primary media leaf URL APIs (no @testable).
//

import Foundation
import OpenFCPXMLKit
import Testing

@Suite("Public primary media leaf API")
struct FCPXMLPublicMediaLeafAPITests {

    // MARK: - Access level

    @Test("External clients can call all primary media leaf APIs on an empty clip")
    func publicAccessCompilesWithoutTestableImport() {
        let element = FinalCutPro.FCPXML.AssetClip().element

        #expect(element.fcpMediaURL() == nil)
        #expect(element.fcpMediaURL(preferAudioAngle: true) == nil)
        #expect(element.fcpMediaURL(kind: .originalMedia) == nil)
        #expect(element.fcpMediaURL(kind: .proxyMedia) == nil)
        #expect(element.fcpMediaURL(kind: .originalMedia, preferAudioAngle: true) == nil)

        let representations = element.fcpMediaRepresentationURLs()
        #expect(representations.original == nil)
        #expect(representations.proxy == nil)

        let audioRepresentations = element.fcpMediaRepresentationURLs(preferAudioAngle: true)
        #expect(audioRepresentations.original == nil)
        #expect(audioRepresentations.proxy == nil)
    }

    // MARK: - Bundled samples (public APIs only)

    @Test("MulticamSample resolves video and audio angle leaves consistently")
    func multicamSampleResolvesVideoAndAudioLeavesConsistently() throws {
        let fcpxml = try requireFCPXMLSample(named: "MulticamSample")
        let resources = fcpxml.root.resources
        let mcClip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(whereFCPElementType: .mcClip)
        )

        try expectConsistentPrimaryLeaf(
            mcClip,
            resources: resources,
            expectedFileName: "Day2_InterviewOwners_02_A.mov"
        )
        try expectConsistentPrimaryLeaf(
            mcClip,
            resources: resources,
            preferAudioAngle: true,
            expectedFileName: "4CH001I.wav"
        )

        let videoURL = try #require(mcClip.fcpMediaURL(in: resources))
        #expect(mcClip.fcpMediaURL()?.lastPathComponent == videoURL.lastPathComponent)
    }

    @Test("SyncClip resolves the primary video leaf")
    func syncClipResolvesPrimaryVideoLeaf() throws {
        let fcpxml = try requireFCPXMLSample(named: "SyncClip")
        let resources = fcpxml.root.resources
        let syncClip = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(whereFCPElementType: .syncClip)
        )

        try expectConsistentPrimaryLeaf(
            syncClip,
            resources: resources,
            expectedFileName: "TestVideo.m4v"
        )
        try expectConsistentPrimaryLeaf(
            syncClip,
            resources: resources,
            preferAudioAngle: true,
            expectedFileName: "TestVideo.m4v"
        )
    }

    @Test("StandaloneRefClip resolves the interior compound asset")
    func standaloneRefClipResolvesInteriorAsset() throws {
        let fcpxml = try requireFCPXMLSample(named: "StandaloneRefClip")
        let resources = fcpxml.root.resources
        let refClip = try #require(
            fcpxml.xml.rootElement()?
                .childElements
                .first(whereFCPElementType: .refClip)
        )

        try expectConsistentPrimaryLeaf(
            refClip,
            resources: resources,
            expectedFileName: "TestVideo.mov"
        )
    }

    @Test("Title-only compound returns nil for every public overload")
    func titleOnlyCompoundReturnsNilForAllOverloads() throws {
        let fcpxml = try requireFCPXMLSample(named: "CompoundClips")
        let resources = fcpxml.root.resources
        let titleCompound = try #require(
            fcpxml.allProjects().first?
                .sequence.spine.storyElements
                .first(where: { $0.fcpName == "Title Compound Clip" })
        )

        #expect(titleCompound.fcpMediaURL(in: resources) == nil)
        #expect(titleCompound.fcpMediaURL(in: resources, preferAudioAngle: true) == nil)
        #expect(titleCompound.fcpMediaURL(in: resources, kind: .originalMedia) == nil)
        #expect(titleCompound.fcpMediaURL(in: resources, kind: .proxyMedia) == nil)

        let pair = titleCompound.fcpMediaRepresentationURLs(in: resources)
        #expect(pair.original == nil)
        #expect(pair.proxy == nil)
    }

    // MARK: - Original / proxy pair

    @Test("Original and proxy kinds stay on the same resolved leaf")
    func originalAndProxyKindsStayOnTheSameLeaf() throws {
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
                .first(whereFCPElementType: .assetClip)
        )
        let resources = fcpxml.root.resources

        try expectConsistentPrimaryLeaf(
            clip,
            resources: resources,
            expectedFileName: "ofk-original.mov"
        )

        let pair = clip.fcpMediaRepresentationURLs(in: resources)
        #expect(pair.original?.lastPathComponent == "ofk-original.mov")
        #expect(pair.proxy?.lastPathComponent == "ofk-proxy.mov")
        #expect(
            clip.fcpMediaURL(in: resources, kind: .proxyMedia)?.lastPathComponent
                == "ofk-proxy.mov"
        )
    }

    @Test("Proxy kind is nil when the leaf declares only original-media")
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
                .first(whereFCPElementType: .assetClip)
        )
        let resources = fcpxml.root.resources

        try expectConsistentPrimaryLeaf(
            clip,
            resources: resources,
            expectedFileName: "ofk-only-original.mov"
        )
        #expect(clip.fcpMediaURL(in: resources, kind: .proxyMedia) == nil)
        #expect(clip.fcpMediaRepresentationURLs(in: resources).proxy == nil)
    }

    // MARK: - Contract

    /// Locks the public overloads together: `kind:` matches the pair, and the default
    /// URL is original then proxy. Does not prove the file exists on disk.
    private func expectConsistentPrimaryLeaf(
        _ element: any OFKXMLElement,
        resources: (any OFKXMLElement)?,
        preferAudioAngle: Bool = false,
        expectedFileName: String? = nil
    ) throws {
        let pair = element.fcpMediaRepresentationURLs(
            in: resources,
            preferAudioAngle: preferAudioAngle
        )
        let preferred = element.fcpMediaURL(
            in: resources,
            preferAudioAngle: preferAudioAngle
        )
        let original = element.fcpMediaURL(
            in: resources,
            kind: .originalMedia,
            preferAudioAngle: preferAudioAngle
        )
        let proxy = element.fcpMediaURL(
            in: resources,
            kind: .proxyMedia,
            preferAudioAngle: preferAudioAngle
        )

        #expect(original == pair.original)
        #expect(proxy == pair.proxy)
        #expect(preferred == pair.original ?? pair.proxy)

        if let expectedFileName {
            let name = try #require(preferred?.lastPathComponent)
            #expect(name == expectedFileName)
        }
    }
}
