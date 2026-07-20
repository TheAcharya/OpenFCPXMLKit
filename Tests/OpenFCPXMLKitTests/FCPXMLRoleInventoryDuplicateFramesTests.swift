//
//  FCPXMLRoleInventoryDuplicateFramesTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Unit tests for inventory Duplicate Frames source-range reuse math.
//

import Foundation
import SwiftTimecode
import Testing
@testable import OpenFCPXMLKit

@Suite("Role inventory duplicate frames")
struct FCPXMLRoleInventoryDuplicateFramesTests {
    @Test("Union duration merges overlapping media reuse intervals")
    func unionDurationMergesOverlappingReuseIntervals() {
        let intervals = [
            FinalCutPro.FCPXML.TimelineOccupancyIndex.Interval(start: 0, end: 2),
            FinalCutPro.FCPXML.TimelineOccupancyIndex.Interval(start: 1, end: 3),
            FinalCutPro.FCPXML.TimelineOccupancyIndex.Interval(start: 5, end: 6)
        ]
        #expect(
            FinalCutPro.FCPXML.TimelineOccupancyIndex.unionDuration(intervals) == 4
        )
    }
    
    @Test("Column exclusion resolves Duplicate Frames alias")
    func columnExclusionResolvesDuplicateFramesAlias() {
        #expect(
            FinalCutPro.FCPXML.ReportColumnExclusion.resolveColumn("Duplicate Frames")
                == .duplicateFrames
        )
    }
}
