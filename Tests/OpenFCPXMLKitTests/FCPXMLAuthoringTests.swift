//
//  FCPXMLAuthoringTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Detached authoring layer: round-trip and version omit-on-write.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Detached authoring")
struct FCPXMLAuthoringTests {
    private typealias Authoring = FinalCutPro.FCPXML.Authoring

    private func sampleDocument(
        version: FCPXMLVersion = .v1_14,
        includeCinematic: Bool = true
    ) -> Authoring.Document {
        let format = Authoring.Format(
            id: "r1",
            frameDuration: "100/2400s",
            width: 1920,
            height: 1080,
            name: "FFVideoFormat1080p24"
        )
        let asset = Authoring.Asset(
            id: "r2",
            name: "Clip",
            hasVideo: true,
            hasAudio: true,
            duration: "10s",
            formatID: "r1",
            mediaReps: [
                Authoring.MediaRep(src: "file:///tmp/clip.mov")
            ]
        )
        var clip = Authoring.AssetClip(
            ref: "r2",
            offset: "0s",
            duration: "5s",
            name: "Clip",
            start: "0s"
        )
        if includeCinematic {
            clip.cinematic = Authoring.CinematicAdjustment(aperture: "wide")
        }
        return Authoring.Document.simpleProject(
            version: version,
            projectName: "Demo",
            eventName: "Event",
            format: format,
            asset: asset,
            clip: clip,
            sequenceDuration: "5s"
        )
    }

    @Test("VersionAvailability from and upTo")
    func versionAvailabilityRanges() {
        let from10 = FinalCutPro.FCPXML.VersionAvailability.from(.v1_10)
        #expect(from10.contains(.v1_10))
        #expect(from10.contains(.v1_14))
        #expect(!from10.contains(.v1_9))

        let upTo9 = FinalCutPro.FCPXML.VersionAvailability.upTo(.v1_9)
        #expect(upTo9.contains(.v1_5))
        #expect(upTo9.contains(.v1_9))
        #expect(!upTo9.contains(.v1_10))

        #expect(FinalCutPro.FCPXML.VersionAvailability.always.contains(.v1_5))
        #expect(FinalCutPro.FCPXML.VersionAvailability.always.contains(.v1_14))
    }

    @Test("Authored document round-trips through XML")
    func authoredDocumentRoundTrip() throws {
        let original = sampleDocument(version: .v1_14, includeCinematic: true)
        let xml = try original.xmlString()
        let parsedLive = try OFKXMLDefaultFactory().makeDocument(
            xmlString: xml,
            options: .fcpxmlDefaults
        )
        let decoded = try Authoring.Document(xmlDocument: parsedLive)

        #expect(decoded.version == .v1_14)
        #expect(decoded.resources.formats.count == 1)
        #expect(decoded.resources.assets.count == 1)
        #expect(decoded.resources.assets[0].mediaReps.count == 1)
        let project = try #require(decoded.library?.events.first?.projects.first)
        #expect(project.name == "Demo")
        #expect(project.sequence.spine.assetClips.count == 1)
        #expect(project.sequence.spine.assetClips[0].cinematic?.aperture == "wide")
    }

    @Test("Cinematic omitted when encoding to FCPXML 1.5")
    func cinematicOmittedForVersion1_5() throws {
        let document = sampleDocument(version: .v1_5, includeCinematic: true)
        let xml = try document.xmlString()
        #expect(!xml.contains("adjust-cinematic"))
        #expect(xml.contains("asset-clip"))
        #expect(xml.contains("version=\"1.5\""))

        let parsed = try OFKXMLDefaultFactory().makeDocument(
            xmlString: xml,
            options: .fcpxmlDefaults
        )
        let decoded = try Authoring.Document(xmlDocument: parsed)
        let clip = try #require(decoded.library?.events.first?.projects.first?.sequence.spine.assetClips.first)
        #expect(clip.cinematic == nil)
    }

    @Test("Cinematic retained when encoding to FCPXML 1.10+")
    func cinematicRetainedForVersion1_10() throws {
        let document = sampleDocument(version: .v1_10, includeCinematic: true)
        let xml = try document.xmlString()
        #expect(xml.contains("adjust-cinematic"))
        #expect(xml.contains("aperture=\"wide\""))
    }

    @Test("Authored XML parses as FinalCutPro.FCPXML")
    func authoredXMLParsesAsLiveFCPXML() throws {
        let document = sampleDocument(version: .v1_11, includeCinematic: false)
        let xml = try document.xmlString()
        let data = try #require(xml.data(using: .utf8))
        let fcpxml = try FinalCutPro.FCPXML(fileContent: data)
        #expect(fcpxml.allProjects().count == 1)
        #expect(fcpxml.allReportTimelineSources().count == 1)
    }

    @Test("Mixed spine items round-trip")
    func mixedSpineItemsRoundTrip() throws {
        let format = Authoring.Format(
            id: "r1",
            frameDuration: "100/2400s",
            width: 1920,
            height: 1080
        )
        let asset = Authoring.Asset(
            id: "r2",
            name: "Clip",
            hasVideo: true,
            hasAudio: true,
            duration: "30s",
            formatID: "r1",
            mediaReps: [Authoring.MediaRep(src: "file:///tmp/clip.mov")]
        )
        let titleEffect = Authoring.Effect(id: "r3", name: "Basic Title", uid: "…/Titles.localized/Basic Title")
        let transitionEffect = Authoring.Effect(id: "r4", name: "Cross Dissolve")

        let document = Authoring.Document(
            version: .v1_11,
            resources: Authoring.Resources(
                formats: [format],
                assets: [asset],
                effects: [titleEffect, transitionEffect]
            ),
            library: Authoring.Library(
                events: [
                    Authoring.Event(
                        name: "Event",
                        projects: [
                            Authoring.Project(
                                name: "Mixed",
                                sequence: Authoring.Sequence(
                                    formatID: "r1",
                                    duration: "20s",
                                    spine: Authoring.Spine(items: [
                                        .assetClip(
                                            Authoring.AssetClip(
                                                ref: "r2",
                                                offset: "0s",
                                                duration: "5s",
                                                name: "A",
                                                start: "0s",
                                                volume: Authoring.VolumeAdjustment(amount: "-3dB")
                                            )
                                        ),
                                        .transition(
                                            Authoring.Transition(
                                                ref: "r4",
                                                offset: "4s",
                                                duration: "1s",
                                                name: "XD"
                                            )
                                        ),
                                        .gap(Authoring.Gap(offset: "5s", duration: "2s", name: "Hold")),
                                        .title(
                                            Authoring.Title(
                                                ref: "r3",
                                                offset: "7s",
                                                duration: "3s",
                                                name: "Lower Third",
                                                start: "3600s"
                                            )
                                        ),
                                        .video(
                                            Authoring.Video(
                                                ref: "r2",
                                                offset: "10s",
                                                duration: "2s",
                                                name: "VLeaf",
                                                start: "0s",
                                                srcID: "1"
                                            )
                                        ),
                                        .audio(
                                            Authoring.Audio(
                                                ref: "r2",
                                                offset: "12s",
                                                duration: "2s",
                                                name: "ALeaf",
                                                start: "0s",
                                                srcID: "1"
                                            )
                                        ),
                                    ])
                                )
                            )
                        ]
                    )
                ]
            )
        )

        let xml = try document.xmlString()
        #expect(xml.contains("<gap "))
        #expect(xml.contains("<title "))
        #expect(xml.contains("<transition "))
        #expect(xml.contains("<video "))
        #expect(xml.contains("<audio "))
        #expect(xml.contains("adjust-volume"))
        #expect(xml.contains("-3dB"))

        let parsed = try OFKXMLDefaultFactory().makeDocument(xmlString: xml, options: .fcpxmlDefaults)
        let decoded = try Authoring.Document(xmlDocument: parsed)
        let items = try #require(decoded.library?.events.first?.projects.first?.sequence.spine.items)
        #expect(items.count == 6)
        #expect(decoded.resources.effects.count == 2)

        if case .assetClip(let clip) = items[0] {
            #expect(clip.volume?.amount == "-3dB")
        } else {
            Issue.record("Expected asset-clip at index 0")
        }
        if case .transition(let transition) = items[1] {
            #expect(transition.ref == "r4")
        } else {
            Issue.record("Expected transition at index 1")
        }
        if case .gap(let gap) = items[2] {
            #expect(gap.duration == "2s")
        } else {
            Issue.record("Expected gap at index 2")
        }
        if case .title(let title) = items[3] {
            #expect(title.name == "Lower Third")
        } else {
            Issue.record("Expected title at index 3")
        }
        if case .video(let video) = items[4] {
            #expect(video.srcID == "1")
        } else {
            Issue.record("Expected video at index 4")
        }
        if case .audio(let audio) = items[5] {
            #expect(audio.name == "ALeaf")
        } else {
            Issue.record("Expected audio at index 5")
        }
    }

    @Test("Authored J/L asset-clip preserves audioStart attributes")
    func authoredJLAttributesRoundTrip() throws {
        let clip = Authoring.AssetClip(
            ref: "r2",
            offset: "2s",
            duration: "5s",
            name: "JL",
            start: "10s",
            audioStart: "9s",
            audioDuration: "7s"
        )
        let format = Authoring.Format(id: "r1", frameDuration: "100/2400s", width: 1920, height: 1080)
        let asset = Authoring.Asset(
            id: "r2",
            hasVideo: true,
            hasAudio: true,
            duration: "60s",
            formatID: "r1",
            mediaReps: [Authoring.MediaRep(src: "file:///tmp/a.mov")]
        )
        let document = Authoring.Document.simpleProject(
            version: .v1_11,
            format: format,
            asset: asset,
            clip: clip,
            sequenceDuration: "10s"
        )
        let decoded = try Authoring.Document(
            xmlDocument: try OFKXMLDefaultFactory().makeDocument(
                xmlString: try document.xmlString(),
                options: .fcpxmlDefaults
            )
        )
        let roundTrip = try #require(decoded.library?.events.first?.projects.first?.sequence.spine.assetClips.first)
        #expect(roundTrip.audioStart == "9s")
        #expect(roundTrip.audioDuration == "7s")
    }

    @Test("Authored sync-clip / ref-clip / mc-clip / audition / caption round-trip")
    func authoredCompoundStoryItemsRoundTrip() throws {
        let format = Authoring.Format(id: "r1", frameDuration: "100/2400s", width: 1920, height: 1080)
        let asset = Authoring.Asset(
            id: "r2",
            hasVideo: true,
            hasAudio: true,
            duration: "60s",
            formatID: "r1",
            mediaReps: [Authoring.MediaRep(src: "file:///tmp/a.mov")]
        )
        let compoundMedia = Authoring.Media(
            id: "r3",
            name: "Compound",
            content: .sequence(
                Authoring.MediaSequence(
                    formatID: "r1",
                    duration: "4s",
                    spine: Authoring.Spine(items: [
                        .assetClip(
                            Authoring.AssetClip(
                                ref: "r2",
                                offset: "0s",
                                duration: "4s",
                                name: "Inner",
                                start: "0s"
                            )
                        )
                    ])
                )
            )
        )
        let multicamMedia = Authoring.Media(
            id: "r4",
            name: "Multicam",
            content: .multicam(
                Authoring.Multicam(
                    formatID: "r1",
                    duration: "8s",
                    angles: [
                        Authoring.MCAngle(
                            angleID: "angleA",
                            name: "Cam A",
                            items: [
                                .assetClip(
                                    Authoring.AssetClip(
                                        ref: "r2",
                                        offset: "0s",
                                        duration: "8s",
                                        name: "A",
                                        start: "0s"
                                    )
                                )
                            ]
                        ),
                        Authoring.MCAngle(
                            angleID: "angleB",
                            name: "Cam B",
                            items: [
                                .assetClip(
                                    Authoring.AssetClip(
                                        ref: "r2",
                                        offset: "0s",
                                        duration: "8s",
                                        name: "B",
                                        start: "0s"
                                    )
                                )
                            ]
                        ),
                    ]
                )
            )
        )

        let document = Authoring.Document(
            version: .v1_11,
            resources: Authoring.Resources(
                formats: [format],
                assets: [asset],
                media: [compoundMedia, multicamMedia]
            ),
            library: Authoring.Library(
                events: [
                    Authoring.Event(
                        name: "Event",
                        projects: [
                            Authoring.Project(
                                name: "Compounds",
                                sequence: Authoring.Sequence(
                                    formatID: "r1",
                                    duration: "30s",
                                    spine: Authoring.Spine(items: [
                                        .syncClip(
                                            Authoring.SyncClip(
                                                offset: "0s",
                                                duration: "5s",
                                                name: "Synced",
                                                start: "0s",
                                                formatID: "r1",
                                                contents: [
                                                    .item(
                                                        .assetClip(
                                                            Authoring.AssetClip(
                                                                ref: "r2",
                                                                offset: "0s",
                                                                duration: "5s",
                                                                name: "SyncLeaf",
                                                                start: "0s"
                                                            )
                                                        )
                                                    )
                                                ],
                                                syncSources: [
                                                    Authoring.SyncSource(sourceID: "storyline")
                                                ]
                                            )
                                        ),
                                        .refClip(
                                            Authoring.RefClip(
                                                ref: "r3",
                                                offset: "5s",
                                                duration: "4s",
                                                name: "Ref",
                                                start: "0s",
                                                useAudioSubroles: true
                                            )
                                        ),
                                        .mcClip(
                                            Authoring.MCClip(
                                                ref: "r4",
                                                offset: "9s",
                                                duration: "8s",
                                                name: "MC",
                                                start: "0s",
                                                sources: [
                                                    Authoring.MCSource(angleID: "angleA", srcEnable: "all"),
                                                    Authoring.MCSource(angleID: "angleB", srcEnable: "audio"),
                                                ]
                                            )
                                        ),
                                        .audition(
                                            Authoring.Audition(
                                                offset: "17s",
                                                candidates: [
                                                    .assetClip(
                                                        Authoring.AssetClip(
                                                            ref: "r2",
                                                            offset: "17s",
                                                            duration: "3s",
                                                            name: "Active",
                                                            start: "0s"
                                                        )
                                                    ),
                                                    .assetClip(
                                                        Authoring.AssetClip(
                                                            ref: "r2",
                                                            offset: "17s",
                                                            duration: "3s",
                                                            name: "Alt",
                                                            start: "10s"
                                                        )
                                                    ),
                                                ]
                                            )
                                        ),
                                        .caption(
                                            Authoring.Caption(
                                                offset: "0s",
                                                duration: "2s",
                                                name: "Hello",
                                                lane: 1,
                                                role: "iTT?caption",
                                                note: "spoken"
                                            )
                                        ),
                                    ])
                                )
                            )
                        ]
                    )
                ]
            )
        )

        let xml = try document.xmlString()
        #expect(xml.contains("<sync-clip "))
        #expect(xml.contains("<sync-source "))
        #expect(xml.contains("sourceID=\"storyline\""))
        #expect(xml.contains("<ref-clip "))
        #expect(xml.contains("useAudioSubroles=\"1\""))
        #expect(xml.contains("<mc-clip "))
        #expect(xml.contains("<mc-source "))
        #expect(xml.contains("<audition "))
        #expect(xml.contains("<caption "))
        #expect(xml.contains("<media "))
        #expect(xml.contains("<multicam "))
        #expect(xml.contains("<mc-angle "))

        let decoded = try Authoring.Document(
            xmlDocument: try OFKXMLDefaultFactory().makeDocument(
                xmlString: xml,
                options: .fcpxmlDefaults
            )
        )
        #expect(decoded.resources.media.count == 2)
        if case .sequence(let sequence) = decoded.resources.media[0].content {
            #expect(sequence.spine.items.count == 1)
        } else {
            Issue.record("Expected compound media sequence")
        }
        if case .multicam(let multicam) = decoded.resources.media[1].content {
            #expect(multicam.angles.count == 2)
            #expect(multicam.angles[0].angleID == "angleA")
        } else {
            Issue.record("Expected multicam media")
        }

        let items = try #require(decoded.library?.events.first?.projects.first?.sequence.spine.items)
        #expect(items.count == 5)

        if case .syncClip(let sync) = items[0] {
            #expect(sync.name == "Synced")
            #expect(sync.syncSources.first?.sourceID == "storyline")
            #expect(sync.contents.count == 1)
        } else {
            Issue.record("Expected sync-clip")
        }
        if case .refClip(let ref) = items[1] {
            #expect(ref.ref == "r3")
            #expect(ref.useAudioSubroles == true)
        } else {
            Issue.record("Expected ref-clip")
        }
        if case .mcClip(let mc) = items[2] {
            #expect(mc.sources.count == 2)
            #expect(mc.sources[1].srcEnable == "audio")
        } else {
            Issue.record("Expected mc-clip")
        }
        if case .audition(let audition) = items[3] {
            #expect(audition.candidates.count == 2)
            if case .assetClip(let active) = audition.candidates[0] {
                #expect(active.name == "Active")
            } else {
                Issue.record("Expected active audition asset-clip")
            }
        } else {
            Issue.record("Expected audition")
        }
        if case .caption(let caption) = items[4] {
            #expect(caption.role == "iTT?caption")
            #expect(caption.note == "spoken")
            #expect(caption.lane == 1)
        } else {
            Issue.record("Expected caption")
        }
    }
}
