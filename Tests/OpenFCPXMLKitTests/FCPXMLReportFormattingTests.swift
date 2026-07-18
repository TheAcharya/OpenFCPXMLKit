//
//  FCPXMLReportFormattingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for workbook column string formatting.
//

import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Report formatting")
struct FCPXMLReportFormattingTests {
    private typealias ReportFormatting = FinalCutPro.FCPXML.ReportFormatting
    private typealias ReportTimecodeFormat = FinalCutPro.FCPXML.ReportTimecodeFormat
    private typealias ExtractedEffect = FinalCutPro.FCPXML.ExtractedEffect

    @Test("Timecode string formats hours minutes seconds frames")
    func timecodeStringFormatsHoursMinutesSecondsFrames() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: TimecodeFrameRate.fps24)
        #expect(ReportFormatting.timecodeString(timecode) == "01:02:03:04")
    }

    @Test("Timecode string uses semicolon for drop-frame rate")
    func timecodeStringUsesSemicolonForDropFrameRate() throws {
        let timecode = try Timecode(.realTime(seconds: 3600), at: .fps29_97d)
        #expect(ReportFormatting.timecodeString(timecode) == timecode.stringValue())
        #expect(ReportFormatting.timecodeString(timecode).contains(";"))
    }

    @Test("Timecode string uses colon for non-drop-frame rate")
    func timecodeStringUsesColonForNonDropFrameRate() throws {
        let timecode = try Timecode(.realTime(seconds: 3600), at: .fps29_97)
        #expect(ReportFormatting.timecodeString(timecode) == timecode.stringValue())
        #expect(!ReportFormatting.timecodeString(timecode).contains(";"))
    }

    @Test("Timecode string frames format returns whole frame count")
    func timecodeStringFramesFormatReturnsWholeFrameCount() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: .fps24)
        #expect(
            ReportFormatting.timecodeString(timecode, format: .frames)
                == String(timecode.frameCount.wholeFrames)
        )
    }

    @Test("Timecode string feet+frames format")
    func timecodeStringFeetAndFramesFormat() throws {
        let timecode = try Timecode(.feetAndFrames(feet: 60, frames: 10), at: .fps24)
        #expect(
            ReportFormatting.timecodeString(timecode, format: .feetAndFrames)
                == timecode.feetAndFramesValue.stringValue
        )
    }

    @Test("Timecode string SMPTE no-frames format")
    func timecodeStringSmpteNoFramesFormat() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: .fps24)
        #expect(
            ReportFormatting.timecodeString(timecode, format: .smpteNoFrames)
                == "01:02:03"
        )
    }

    @Test("Compare timeline positions uses numeric order for frames")
    func compareTimelinePositionsUsesNumericOrderForFramesFormat() {
        #expect(
            ReportFormatting.compareTimelinePositions("9", "100", format: .frames)
                == .orderedAscending
        )
        #expect(
            ReportFormatting.compareTimelinePositions("20", "100", format: .frames)
                == .orderedAscending
        )
        #expect(
            ReportFormatting.compareTimelinePositions("100", "20", format: .frames)
                == .orderedDescending
        )
        #expect(
            ReportFormatting.compareTimelinePositions("1500", "1500", format: .frames)
                == .orderedSame
        )
    }

    @Test("Frames format sort differs from lexicographic string sort")
    func framesFormatSortDiffersFromLexicographicStringSort() {
        #expect("20".compare("100") == .orderedDescending)
        #expect(
            ReportFormatting.compareTimelinePositions("20", "100", format: .frames)
                == .orderedAscending
        )
    }

    @Test("Compare timeline positions uses chronological order for SMPTE")
    func compareTimelinePositionsUsesChronologicalOrderForSmpteFormats() {
        #expect(
            ReportFormatting.compareTimelinePositions(
                "01:00:00:00",
                "01:00:00:01",
                format: .smpteFrames
            ) == .orderedAscending
        )
        #expect(
            ReportFormatting.compareTimelinePositions(
                "01:02:03",
                "01:02:04",
                format: .smpteNoFrames
            ) == .orderedAscending
        )
    }

    @Test("Compare timeline positions uses numeric order for feet+frames")
    func compareTimelinePositionsUsesNumericOrderForFeetAndFramesFormat() {
        #expect(
            ReportFormatting.compareTimelinePositions("9+00", "10+00", format: .feetAndFrames)
                == .orderedAscending
        )
        #expect(
            ReportFormatting.compareTimelinePositions("100+00", "20+00", format: .feetAndFrames)
                == .orderedDescending
        )
        #expect(
            ReportFormatting.compareTimelinePositions("60+09", "60+10", format: .feetAndFrames)
                == .orderedAscending
        )
    }

    @Test("Feet+frames format sort differs from lexicographic string sort")
    func feetAndFramesFormatSortDiffersFromLexicographicStringSort() {
        #expect("9+00".compare("10+00") == .orderedDescending)
        #expect(
            ReportFormatting.compareTimelinePositions("9+00", "10+00", format: .feetAndFrames)
                == .orderedAscending
        )
    }

    @Test("ReportTimecodeFormat parses CLI values")
    func reportTimecodeFormatParsesCLIValues() {
        #expect(ReportTimecodeFormat(cliValue: "HH:MM:SS:FF") == .smpteFrames)
        #expect(ReportTimecodeFormat(cliValue: "frames") == .frames)
        #expect(ReportTimecodeFormat(cliValue: "Feet+Frames") == .feetAndFrames)
        #expect(ReportTimecodeFormat(cliValue: "HH:MM:SS") == .smpteNoFrames)
        #expect(ReportTimecodeFormat(cliValue: "invalid") == nil)
    }

    @Test("Marker report type maps configurations")
    func markerReportTypeMapsConfigurations() {
        #expect(ReportFormatting.markerReportType(for: .standard) == .standard)
        #expect(
            ReportFormatting.markerReportType(for: .toDo(completed: false))
                == .incompleteToDo
        )
        #expect(
            ReportFormatting.markerReportType(for: .toDo(completed: true))
                == .completedToDo
        )
        #expect(
            ReportFormatting.markerReportType(for: .chapter(posterOffset: Fraction(1, 24)))
                == .chapter
        )
        #expect(
            ReportFormatting.markerReportType(
                for: .analysis(
                    shotTypes: [FinalCutPro.FCPXML.ShotType(value: .closeUp)],
                    stabilizationTypes: []
                )
            ) == .analysis
        )
    }

    @Test("Role subrole display includes subrole separator")
    func roleSubroleDisplayIncludesSubroleSeparator() {
        let role = interpolatedRole("dialogue.MixL")
        let display = ReportFormatting.roleSubroleDisplay(from: role)

        #expect(display.contains("▸"))
        #expect(display.lowercased().contains("dialogue"))
    }

    @Test("Main role display title-cases built-in roles")
    func mainRoleDisplayTitleCasesBuiltInRoles() {
        let role = interpolatedRole("dialogue")
        #expect(ReportFormatting.mainRoleDisplay(from: role) == "Dialogue")
    }

    @Test("Enabled and Apple checkmarks")
    func enabledAndAppleCheckmarks() {
        let enabled = OFKXMLDefaultFactory().makeElement(name: "title")
        enabled.addAttribute(name: "enabled", value: "1")

        #expect(ReportFormatting.enabledCheckmark(for: enabled) == "✓")
        #expect(ReportFormatting.appleCheckmark(forAppleSupplied: true) == "✓")
        #expect(ReportFormatting.appleCheckmark(forAppleSupplied: false) == "")
        #expect(ReportFormatting.appleCheckmarkForTitle(isAppleSupplied: false) == "✗")
    }

    @Test("Transition category display names")
    func transitionCategoryDisplayNames() {
        #expect(
            ReportFormatting.transitionCategory(for: .primary)
                == "Primary transition"
        )
        #expect(
            ReportFormatting.transitionCategory(for: .secondary)
                == "Secondary transition"
        )
    }

    @Test("Effect settings display formats structured settings")
    func effectSettingsDisplayFormatsStructuredSettings() throws {
        let host = try requireExtractedHost(
            from: parseInlineFCPXML(minimalTimeline()),
            elementName: "asset-clip"
        )

        let cases: [(ExtractedEffect.Settings, String)] = [
            (.empty, ""),
            (.text("Blur"), "Blur"),
            (.decibels(12), "12.0 dB"),
            (.opacityPercent(0.3), "Opacity 0.3%"),
            (.conformType("fit"), "Fit"),
            (.transformCenter(.init(x: 10, y: 20)), "Center 10.0 px, 20.0 px"),
            (.transformRotation(45), "Rotation 45.0°"),
            (.transformScale(.init(x: 1.5, y: 1.5)), "Scale 150.0%")
        ]

        for (settings, expected) in cases {
            let effect = makeExtractedEffect(
                name: "Test",
                kind: .transform,
                host: host,
                settings: settings
            )
            #expect(ReportFormatting.effectSettingsDisplay(for: effect) == expected)
        }
    }

    @Test("Title role subrole always returns Titles")
    func titleRoleSubroleAlwaysReturnsTitles() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        let title = try #require(titles.first)

        #expect(ReportFormatting.titleRoleSubrole(for: title) == "Titles")
    }

    @Test("Inventory combined role field uses anchor format when video present")
    func inventoryCombinedRoleFieldUsesAnchorFormatWhenVideoPresent() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ Boom 1"
        ])

        #expect(field == "Video, Dialogue ▸ Boom 1, Mix L, Mix R")
    }

    @Test("Inventory combined role field groups subroles without video")
    func inventoryCombinedRoleFieldGroupsSubrolesWithoutVideo() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ Boom 1",
            "Dialogue ▸ <Blank>"
        ])

        #expect(field == "Dialogue ▸ Mix L, Mix R, Boom 1")
    }

    @Test("Lone empty Dialogue uses default subrole")
    func inventoryCombinedRoleFieldLoneEmptyDialogueUsesDefaultSubrole() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ <Blank>"
        ])

        #expect(field == "Video, Dialogue ▸ Dialogue-1")
    }

    @Test("Lone empty Atmosphere uses default subrole")
    func inventoryCombinedRoleFieldLoneEmptyAtmosphereUsesDefaultSubrole() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Atmosphere ▸ <Blank>"
        ])

        #expect(field == "Atmosphere ▸ Atmosphere-1")
    }

    @Test("Drops blank Dialogue among sibling subroles")
    func inventoryCombinedRoleFieldDropsBlankDialogueAmongSiblingSubroles() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ Boom 1",
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ <Blank>"
        ])

        #expect(field == "Video, Dialogue ▸ Boom 1, Mix L, Mix R")
    }

    @Test("Stable channel order for radio subroles")
    func inventoryCombinedRoleFieldUsesStableChannelOrderForRadioSubroles() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Dialogue ▸ R_Fahd",
            "Dialogue ▸ R_Slate"
        ])

        #expect(field == "Dialogue ▸ R_Slate, R_Fahd")
    }

    @Test("Keyword role displays sort video before dialogue when both present")
    func keywordRoleDisplaysSortsVideoBeforeDialogueWhenBothPresent() async throws {
        let timeline = try requireTimelineElement(fromSampleNamed: "Keywords")
        let keywords = await timeline.fcpExtract(
            types: [.keyword],
            scope: .reportMainTimelineVisible()
        )

        for keyword in keywords {
            let displays = ReportFormatting.keywordRoleDisplays(for: keyword)
            guard displays.count >= 2,
                  let videoIndex = displays.firstIndex(where: { $0.lowercased() == "video" }),
                  let dialogueIndex = displays.firstIndex(where: { $0.lowercased() == "dialogue" })
            else { continue }

            #expect(videoIndex < dialogueIndex)
            return
        }

        try Test.cancel("No keyword with both Video and Dialogue roles in Keywords sample")
    }

    private func minimalTimeline() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <format id="r1" name="FFVideoFormat1080p24" frameDuration="100/2400s" width="1920" height="1080"/>
            </resources>
            <library>
                <event name="E" uid="E1">
                    <project name="P" uid="P1">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                            <spine>
                                <asset-clip offset="0s" name="Clip" duration="10s" format="r1" audioRole="dialogue"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}

