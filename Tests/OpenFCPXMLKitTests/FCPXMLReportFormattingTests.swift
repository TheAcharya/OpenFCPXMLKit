//
//  FCPXMLReportFormattingTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for workbook column string formatting.
//

import SwiftTimecode
import XCTest
@testable import OpenFCPXMLKit

@available(macOS 26.0, *)
final class FCPXMLReportFormattingTests: XCTestCase {
    private typealias ReportFormatting = FinalCutPro.FCPXML.ReportFormatting
    private typealias ReportTimecodeFormat = FinalCutPro.FCPXML.ReportTimecodeFormat
    private typealias ExtractedEffect = FinalCutPro.FCPXML.ExtractedEffect
    
    func testTimecodeStringFormatsHoursMinutesSecondsFrames() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: TimecodeFrameRate.fps24)
        XCTAssertEqual(ReportFormatting.timecodeString(timecode), "01:02:03:04")
    }
    
    func testTimecodeStringUsesSemicolonForDropFrameRate() throws {
        let timecode = try Timecode(.realTime(seconds: 3600), at: .fps29_97d)
        XCTAssertEqual(ReportFormatting.timecodeString(timecode), timecode.stringValue())
        XCTAssertTrue(ReportFormatting.timecodeString(timecode).contains(";"))
    }
    
    func testTimecodeStringUsesColonForNonDropFrameRate() throws {
        let timecode = try Timecode(.realTime(seconds: 3600), at: .fps29_97)
        XCTAssertEqual(ReportFormatting.timecodeString(timecode), timecode.stringValue())
        XCTAssertFalse(ReportFormatting.timecodeString(timecode).contains(";"))
    }
    
    func testTimecodeStringFramesFormatReturnsWholeFrameCount() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: .fps24)
        XCTAssertEqual(
            ReportFormatting.timecodeString(timecode, format: .frames),
            String(timecode.frameCount.wholeFrames)
        )
    }
    
    func testTimecodeStringFeetAndFramesFormat() throws {
        let timecode = try Timecode(.feetAndFrames(feet: 60, frames: 10), at: .fps24)
        XCTAssertEqual(
            ReportFormatting.timecodeString(timecode, format: .feetAndFrames),
            timecode.feetAndFramesValue.stringValue
        )
    }
    
    func testTimecodeStringSmpteNoFramesFormat() throws {
        let totalFrames = (1 * 3600 + 2 * 60 + 3) * 24 + 4
        let timecode = try Timecode(.frames(totalFrames), at: .fps24)
        XCTAssertEqual(
            ReportFormatting.timecodeString(timecode, format: .smpteNoFrames),
            "01:02:03"
        )
    }
    
    func testCompareTimelinePositionsUsesNumericOrderForFramesFormat() {
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("9", "100", format: .frames),
            .orderedAscending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("20", "100", format: .frames),
            .orderedAscending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("100", "20", format: .frames),
            .orderedDescending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("1500", "1500", format: .frames),
            .orderedSame
        )
    }
    
    func testFramesFormatSortDiffersFromLexicographicStringSort() {
        // Pure character-wise order treats "20" as after "100"; timeline order is the opposite.
        XCTAssertEqual("20".compare("100"), .orderedDescending)
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("20", "100", format: .frames),
            .orderedAscending
        )
    }
    
    func testCompareTimelinePositionsUsesChronologicalOrderForSmpteFormats() {
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("01:00:00:00", "01:00:00:01", format: .smpteFrames),
            .orderedAscending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("01:02:03", "01:02:04", format: .smpteNoFrames),
            .orderedAscending
        )
    }
    
    func testCompareTimelinePositionsUsesNumericOrderForFeetAndFramesFormat() {
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("9+00", "10+00", format: .feetAndFrames),
            .orderedAscending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("100+00", "20+00", format: .feetAndFrames),
            .orderedDescending
        )
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("60+09", "60+10", format: .feetAndFrames),
            .orderedAscending
        )
    }
    
    func testFeetAndFramesFormatSortDiffersFromLexicographicStringSort() {
        XCTAssertEqual("9+00".compare("10+00"), .orderedDescending)
        XCTAssertEqual(
            ReportFormatting.compareTimelinePositions("9+00", "10+00", format: .feetAndFrames),
            .orderedAscending
        )
    }
    
    func testReportTimecodeFormatParsesCLIValues() {
        XCTAssertEqual(ReportTimecodeFormat(cliValue: "HH:MM:SS:FF"), .smpteFrames)
        XCTAssertEqual(ReportTimecodeFormat(cliValue: "frames"), .frames)
        XCTAssertEqual(ReportTimecodeFormat(cliValue: "Feet+Frames"), .feetAndFrames)
        XCTAssertEqual(ReportTimecodeFormat(cliValue: "HH:MM:SS"), .smpteNoFrames)
        XCTAssertNil(ReportTimecodeFormat(cliValue: "invalid"))
    }
    
    func testMarkerReportTypeMapsConfigurations() {
        XCTAssertEqual(
            ReportFormatting.markerReportType(for: .standard),
            .standard
        )
        XCTAssertEqual(
            ReportFormatting.markerReportType(for: .toDo(completed: false)),
            .incompleteToDo
        )
        XCTAssertEqual(
            ReportFormatting.markerReportType(for: .toDo(completed: true)),
            .completedToDo
        )
        XCTAssertEqual(
            ReportFormatting.markerReportType(for: .chapter(posterOffset: Fraction(1, 24))),
            .chapter
        )
        XCTAssertEqual(
            ReportFormatting.markerReportType(
                for: .analysis(
                    shotTypes: [FinalCutPro.FCPXML.ShotType(value: .closeUp)],
                    stabilizationTypes: []
                )
            ),
            .analysis
        )
    }
    
    func testRoleSubroleDisplayIncludesSubroleSeparator() {
        let role = interpolatedRole("dialogue.MixL")
        let display = ReportFormatting.roleSubroleDisplay(from: role)
        
        XCTAssertTrue(display.contains("▸"))
        XCTAssertTrue(display.lowercased().contains("dialogue"))
    }
    
    func testMainRoleDisplayTitleCasesBuiltInRoles() {
        let role = interpolatedRole("dialogue")
        XCTAssertEqual(ReportFormatting.mainRoleDisplay(from: role), "Dialogue")
    }
    
    func testEnabledAndAppleCheckmarks() {
        let enabled = OFKXMLDefaultFactory().makeElement(name: "title")
        enabled.addAttribute(name: "enabled", value: "1")
        
        XCTAssertEqual(ReportFormatting.enabledCheckmark(for: enabled), "✓")
        XCTAssertEqual(ReportFormatting.appleCheckmark(forAppleSupplied: true), "✓")
        XCTAssertEqual(ReportFormatting.appleCheckmark(forAppleSupplied: false), "")
        XCTAssertEqual(ReportFormatting.appleCheckmarkForTitle(isAppleSupplied: false), "✗")
    }
    
    func testTransitionCategoryDisplayNames() {
        XCTAssertEqual(
            ReportFormatting.transitionCategory(for: .primary),
            "Primary transition"
        )
        XCTAssertEqual(
            ReportFormatting.transitionCategory(for: .secondary),
            "Secondary transition"
        )
    }
    
    func testEffectSettingsDisplayFormatsStructuredSettings() throws {
        let host = try makeExtractedHost(from: parseInlineFCPXML(minimalTimeline()), elementName: "asset-clip")
        
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
            let effect = makeExtractedEffect(name: "Test", kind: .transform, host: host, settings: settings)
            XCTAssertEqual(ReportFormatting.effectSettingsDisplay(for: effect), expected)
        }
    }
    
    func testTitleRoleSubroleAlwaysReturnsTitles() async throws {
        let timeline = try timelineElement(fromSampleNamed: "DisabledClips")
        let titles = await timeline.fcpExtract(types: [.title], scope: .mainTimeline)
        let title = try XCTUnwrap(titles.first)
        
        XCTAssertEqual(ReportFormatting.titleRoleSubrole(for: title), "Titles")
    }
    
    func testInventoryCombinedRoleFieldUsesAnchorFormatWhenVideoPresent() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ Boom 1"
        ])
        
        XCTAssertEqual(field, "Video, Dialogue ▸ Boom 1, Mix L, Mix R")
    }
    
    func testInventoryCombinedRoleFieldGroupsSubrolesWithoutVideo() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ Boom 1",
            "Dialogue ▸ <Blank>"
        ])
        
        XCTAssertEqual(field, "Dialogue ▸ Mix L, Mix R, Boom 1")
    }
    
    func testInventoryCombinedRoleFieldLoneEmptyDialogueUsesDefaultSubrole() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ <Blank>"
        ])
        
        XCTAssertEqual(field, "Video, Dialogue ▸ Dialogue-1")
    }
    
    func testInventoryCombinedRoleFieldLoneEmptyAtmosUsesDefaultSubrole() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Atmos ▸ <Blank>"
        ])
        
        XCTAssertEqual(field, "Atmos ▸ Atmos-1")
    }
    
    func testInventoryCombinedRoleFieldDropsBlankDialogueAmongSiblingSubroles() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Video",
            "Dialogue ▸ Boom 1",
            "Dialogue ▸ Mix L",
            "Dialogue ▸ Mix R",
            "Dialogue ▸ <Blank>"
        ])
        
        XCTAssertEqual(field, "Video, Dialogue ▸ Boom 1, Mix L, Mix R")
    }
    
    func testInventoryCombinedRoleFieldUsesStableChannelOrderForRadioSubroles() {
        let field = ReportFormatting.inventoryCombinedRoleField(from: [
            "Dialogue ▸ R_Fahd",
            "Dialogue ▸ R_Slate"
        ])
        
        XCTAssertEqual(field, "Dialogue ▸ R_Slate, R_Fahd")
    }
    
    func testKeywordRoleDisplaysSortsVideoBeforeDialogueWhenBothPresent() async throws {
        let timeline = try timelineElement(fromSampleNamed: "Keywords")
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
            
            XCTAssertLessThan(videoIndex, dialogueIndex)
            return
        }
        
        throw XCTSkip("No keyword with both Video and Dialogue roles in Keywords sample")
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
