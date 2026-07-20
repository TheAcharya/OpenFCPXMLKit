//
//  FCPXMLNonStandardEffectsTemplatesReportTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Non-Standard Effects & Templates builder and sheet placement tests.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Non-standard effects and templates report")
struct FCPXMLNonStandardEffectsTemplatesReportTests {
    @Test("Builder lists non-Apple effect resources and marks missing paths")
    func builderListsNonAppleEffectResourcesAndMarksMissingPaths() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.10">
            <resources>
                <effect id="r1" name="Gaussian Blur" uid=".../Titles.localized/Build In:Out.localized/Blur.motn"/>
                <effect id="r2" name="My Drop Shadow" uid="~/Movies/Motion Templates/Generators/Category/DropShadow/DropShadow.motn" src="file:///tmp/ofk-missing-drop-shadow.motn"/>
                <effect id="r3" name="Custom LUT" uid="Custom.LUT.Plugin" src="/tmp/ofk-missing-custom-lut.moef"/>
            </resources>
        </fcpxml>
        """
        let document = try OFKXMLDefaultFactory().makeDocument(xmlString: xml)
        let section = FinalCutPro.FCPXML.NonStandardEffectsTemplatesReportBuilder.build(
            document: document,
            baseURL: nil
        )
        
        #expect(section.rows.count == 2)
        #expect(section.rows.allSatisfy { !$0.uid.contains(".../") })
        
        let dropShadow = try #require(section.rows.first { $0.name.contains("Drop Shadow") })
        #expect(dropShadow.kind == "Generator")
        #expect(dropShadow.status == "MISSING")
        #expect(dropShadow.name.hasSuffix("(MISSING)"))
        
        let lut = try #require(section.rows.first { $0.name.contains("Custom LUT") })
        #expect(lut.kind == "Effect")
        #expect(lut.status == "MISSING")
    }
    
    @Test("Full options enable Non-Standard phase before Effects")
    func fullOptionsEnableNonStandardPhaseBeforeEffects() {
        let phases = FinalCutPro.FCPXML.ReportBuildPhase.enabledPhases(for: .full)
        let nonStandard = phases.firstIndex(of: .nonStandardEffectsTemplates)
        let effects = phases.firstIndex(of: .effects)
        #expect(nonStandard != nil)
        #expect(effects != nil)
        if let nonStandard, let effects {
            #expect(nonStandard < effects)
        }
    }
    
    @Test("Workbook inserts Non-Standard sheet before Video & Audio Effects")
    @MainActor
    func workbookInsertsNonStandardSheetBeforeEffects() {
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Test",
            nonStandardEffectsTemplates: .init(rows: [
                .init(name: "Custom", kind: "Effect", status: "MISSING", path: "/tmp/x", uid: "u1")
            ]),
            effects: .init(rows: [
                .init(
                    effect: "Blur",
                    settings: "",
                    enabled: "✓",
                    isApple: "✓",
                    clipName: "Clip",
                    roleSubrole: "Video",
                    timelineIn: "00:00:00:00",
                    timelineOut: "00:00:01:00"
                )
            ])
        )
        let names = FinalCutPro.FCPXML.ReportExcelExport.makeWorkbook(from: report)
            .getSheets()
            .map(\.name)
        let nonStandard = names.firstIndex(
            of: FinalCutPro.FCPXML.NonStandardEffectsTemplatesReportSection.defaultSheetName
        )
        let effects = names.firstIndex(
            of: FinalCutPro.FCPXML.EffectsReportSection.defaultSheetName
        )
        #expect(nonStandard != nil)
        #expect(effects != nil)
        if let nonStandard, let effects {
            #expect(nonStandard < effects)
        }
    }
}
