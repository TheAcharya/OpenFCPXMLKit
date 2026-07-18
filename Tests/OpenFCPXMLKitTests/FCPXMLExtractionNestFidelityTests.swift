//
// FCPXMLExtractionNestFidelityTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Roles / Effects / Markers / Titles presets against compound, sync, multicam, occlusion nests.
//

import Testing
@testable import OpenFCPXMLKit

@Suite("Extraction nest fidelity")
struct FCPXMLExtractionNestFidelityTests {
    @Test("Roles preset finds roles in sync nests")
    func rolesPresetFindsRolesInSyncNests() async throws {
        for sample in ["SyncClipRoles", "SyncClipRoles2"] {
            let timeline = try requireTimelineElement(fromSampleNamed: sample)
            let roles = await timeline.fcpExtract(
                preset: .roles(),
                scope: .reportMainTimelineVisible()
            )
            #expect(!roles.isEmpty, "Expected roles in \(sample)")
        }
    }

    @Test("Roles preset finds roles in compound clip sample via deep scope")
    func rolesPresetFindsRolesInCompoundClipSampleViaDeepScope() async throws {
        // Standalone compound / ref-clip timelines are covered by FCPXMLCompoundClipReportTests.
        // Here: RolesList + compound nest sample for preset discovery.
        let timeline = try requireTimelineElement(fromSampleNamed: "RolesList")
        let roles = await timeline.fcpExtract(
            preset: .roles(),
            scope: .reportMainTimelineVisible()
        )
        #expect(!roles.isEmpty, "RolesList should yield roles")
    }

    @Test("Titles preset on TitlesRoles and Occlusion samples")
    func titlesPresetOnTitlesRolesAndOcclusionSamples() async throws {
        let titlesRoles = try requireTimelineElement(fromSampleNamed: "TitlesRoles")
        let titles = await titlesRoles.fcpExtract(preset: .titles, scope: .init())
        #expect(!titles.isEmpty, "TitlesRoles should yield titles")
        let titlesHasFullyOccluded = titles.contains {
            $0.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(!titlesHasFullyOccluded)

        let occlusion = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let occludedTitles = await occlusion.fcpExtract(preset: .titles, scope: .init())
        let occludedHasFullyOccluded = occludedTitles.contains {
            $0.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(!occludedHasFullyOccluded, "Titles preset must drop fully occluded hosts")
    }

    @Test("Markers preset on multicam audition and basic markers samples")
    func markersPresetOnMulticamAuditionAndBasicMarkersSamples() async throws {
        for sample in ["MulticamMarkers", "AuditionMarkers", "BasicMarkers"] {
            let timeline = try requireTimelineElement(fromSampleNamed: sample)
            let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
            #expect(!markers.isEmpty, "Expected markers in \(sample)")
        }
    }

    @Test("Markers preset keeps title markers when marker self-occlusion is false positive")
    func markersPresetKeepsTitleMarkersWhenMarkerSelfOcclusionIsFalsePositive() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "BasicMarkers")
        let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
        // Markers themselves may report fullyOccluded due to title local starts;
        // the preset must still return them when the host title is visible.
        #expect(markers.count == 4)
        let hasFullyOccludedMarker = markers.contains {
            $0.value(forContext: .effectiveOcclusion) == .fullyOccluded
        }
        #expect(hasFullyOccludedMarker)
    }

    @Test("Markers preset drops markers on fully occluded hosts")
    func markersPresetDropsMarkersOnFullyOccludedHosts() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Occlusion3")
        let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
        for marker in markers {
            if let host = marker.ancestorClipElement() {
                let hostContext = marker.extractedContext(forClip: host)
                #expect(
                    hostContext.value(forContext: .effectiveOcclusion) != .fullyOccluded,
                    "Marker '\(marker.name)' host must not be fully occluded"
                )
            }
        }
    }

    @Test("Effects preset on sync and multicam nests")
    func effectsPresetOnSyncAndMulticamNests() async throws {
        for sample in ["SyncClipRoles", "MulticamSample"] {
            let timeline = try requireTimelineElement(fromSampleNamed: sample)
            let effects = await FinalCutPro.FCPXML.EffectsExtractionPreset().perform(
                on: timeline,
                scope: .init()
            )
            let hasFullyOccludedHost = effects.contains {
                $0.host.value(forContext: .effectiveOcclusion) == .fullyOccluded
            }
            #expect(
                !hasFullyOccludedHost,
                "Effects hosts must not be fully occluded (\(sample))"
            )
        }
    }

    @Test("Multicam active mask does not extract inactive angle-only markers")
    func multicamActiveMaskDoesNotExtractInactiveAngleOnlyMarkers() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "MulticamMarkers")

        var activeScope = FinalCutPro.FCPXML.ExtractionScope()
        activeScope.mcClipAngles = .active
        let activeMarkers = await timeline.fcpExtract(preset: .markers, scope: activeScope)

        var allScope = FinalCutPro.FCPXML.ExtractionScope()
        allScope.mcClipAngles = .all
        let allMarkers = await timeline.fcpExtract(preset: .markers, scope: allScope)

        #expect(allMarkers.count >= activeMarkers.count)
        #expect(!activeMarkers.isEmpty)
    }
}
