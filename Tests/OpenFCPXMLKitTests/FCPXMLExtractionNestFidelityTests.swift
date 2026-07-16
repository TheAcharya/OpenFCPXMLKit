//
// FCPXMLExtractionNestFidelityTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Roles / Effects / Markers / Titles presets against compound, sync, multicam, occlusion nests.
//

import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLExtractionNestFidelityTests: XCTestCase {
    func testRolesPresetFindsRolesInSyncNests() async throws {
        for sample in ["SyncClipRoles", "SyncClipRoles2"] {
            let timeline = try timelineElement(fromSampleNamed: sample)
            let roles = await timeline.fcpExtract(
                preset: .roles(),
                scope: .reportMainTimelineVisible()
            )
            XCTAssertFalse(roles.isEmpty, "Expected roles in \(sample)")
        }
    }

    func testRolesPresetFindsRolesInCompoundClipSampleViaDeepScope() async throws {
        // Standalone compound / ref-clip timelines are covered by FCPXMLCompoundClipReportTests.
        // Here: RolesList + compound nest sample for preset discovery.
        let timeline = try timelineElement(fromSampleNamed: "RolesList")
        let roles = await timeline.fcpExtract(
            preset: .roles(),
            scope: .reportMainTimelineVisible()
        )
        XCTAssertFalse(roles.isEmpty, "RolesList should yield roles")
    }

    func testTitlesPresetOnTitlesRolesAndOcclusionSamples() async throws {
        let titlesRoles = try timelineElement(fromSampleNamed: "TitlesRoles")
        let titles = await titlesRoles.fcpExtract(preset: .titles, scope: .init())
        XCTAssertFalse(titles.isEmpty, "TitlesRoles should yield titles")
        XCTAssertFalse(
            titles.contains { $0.value(forContext: .effectiveOcclusion) == .fullyOccluded }
        )

        let occlusion = try timelineElement(fromSampleNamed: "Occlusion3")
        let occludedTitles = await occlusion.fcpExtract(preset: .titles, scope: .init())
        XCTAssertFalse(
            occludedTitles.contains { $0.value(forContext: .effectiveOcclusion) == .fullyOccluded },
            "Titles preset must drop fully occluded hosts"
        )
    }

    func testMarkersPresetOnMulticamAuditionAndBasicMarkersSamples() async throws {
        for sample in ["MulticamMarkers", "AuditionMarkers", "BasicMarkers"] {
            let timeline = try timelineElement(fromSampleNamed: sample)
            let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
            XCTAssertFalse(markers.isEmpty, "Expected markers in \(sample)")
        }
    }

    func testMarkersPresetKeepsTitleMarkersWhenMarkerSelfOcclusionIsFalsePositive() async throws {
        let timeline = try timelineElement(fromSampleNamed: "BasicMarkers")
        let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
        // Markers themselves may report fullyOccluded due to title local starts;
        // the preset must still return them when the host title is visible.
        XCTAssertEqual(markers.count, 4)
        XCTAssertTrue(
            markers.contains { $0.value(forContext: .effectiveOcclusion) == .fullyOccluded }
        )
    }

    func testMarkersPresetDropsMarkersOnFullyOccludedHosts() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Occlusion3")
        let markers = await timeline.fcpExtract(preset: .markers, scope: .init())
        for marker in markers {
            if let host = marker.ancestorClipElement() {
                let hostContext = marker.extractedContext(forClip: host)
                XCTAssertNotEqual(
                    hostContext.value(forContext: .effectiveOcclusion),
                    .fullyOccluded,
                    "Marker '\(marker.name)' host must not be fully occluded"
                )
            }
        }
    }

    func testEffectsPresetOnSyncAndMulticamNests() async throws {
        for sample in ["SyncClipRoles", "MulticamSample"] {
            let timeline = try timelineElement(fromSampleNamed: sample)
            let effects = await FinalCutPro.FCPXML.EffectsExtractionPreset().perform(
                on: timeline,
                scope: .init()
            )
            XCTAssertFalse(
                effects.contains {
                    $0.host.value(forContext: .effectiveOcclusion) == .fullyOccluded
                },
                "Effects hosts must not be fully occluded (\(sample))"
            )
        }
    }

    func testMulticamActiveMaskDoesNotExtractInactiveAngleOnlyMarkers() async throws {
        let timeline = try timelineElement(fromSampleNamed: "MulticamMarkers")

        var activeScope = FinalCutPro.FCPXML.ExtractionScope()
        activeScope.mcClipAngles = .active
        let activeMarkers = await timeline.fcpExtract(preset: .markers, scope: activeScope)

        var allScope = FinalCutPro.FCPXML.ExtractionScope()
        allScope.mcClipAngles = .all
        let allMarkers = await timeline.fcpExtract(preset: .markers, scope: allScope)

        XCTAssertGreaterThanOrEqual(allMarkers.count, activeMarkers.count)
        XCTAssertFalse(activeMarkers.isEmpty)
    }
}
