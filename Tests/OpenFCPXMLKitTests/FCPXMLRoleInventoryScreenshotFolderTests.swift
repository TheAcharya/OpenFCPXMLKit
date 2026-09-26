//
//  FCPXMLRoleInventoryScreenshotFolderTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Full-size Role Inventory screenshot PNG names and the sibling Screenshots folder.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import OpenFCPXMLKit

@Suite("Role inventory screenshot files")
struct FCPXMLRoleInventoryScreenshotFolderTests {
    @Test("File name uses the source stem and a hyphenated Source In")
    func fileNameUsesSourceStemAndHyphenatedSourceIn() {
        let stamp = FinalCutPro.FCPXML.RoleInventoryScreenshotFileName.timecodeStamp(
            fileTimeSeconds: 1.5,
            frameRate: .fps24
        )
        #expect(stamp == "00-00-01-12")
        
        let name = FinalCutPro.FCPXML.RoleInventoryScreenshotFileName.preferredFileName(
            sourceFileName: "A001C003.mov",
            timecodeStamp: "01-04-12-08"
        )
        #expect(name == "A001C003-01-04-12-08.png")
        
        let sanitized = FinalCutPro.FCPXML.RoleInventoryScreenshotFileName.preferredFileName(
            sourceFileName: "Reel:A001.mov",
            timecodeStamp: stamp
        )
        #expect(sanitized == "Reel_A001-00-00-01-12.png")
    }
    
    @Test("Identical grab is one PNG and a different file gains a numeric suffix")
    func identicalGrabIsOnePNGAndDifferentFileGainsSuffix() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-folder-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        
        let firstMedia = root.appendingPathComponent("card-a").appendingPathComponent("A001C003.png")
        let secondMedia = root.appendingPathComponent("card-b").appendingPathComponent("A001C003.png")
        try FileManager.default.createDirectory(
            at: firstMedia.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: secondMedia.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try writeSolidPNG(to: firstMedia, width: 32, height: 18)
        try writeSolidPNG(to: secondMedia, width: 40, height: 20)
        
        let shared = inventoryRow(
            mediaURL: firstMedia,
            sourceFileName: "A001C003.mov",
            stamp: "00-00-01-12",
            fileTimeSeconds: 1.5
        )
        let otherCard = inventoryRow(
            mediaURL: secondMedia,
            sourceFileName: "A001C003.mov",
            stamp: "00-00-01-12",
            fileTimeSeconds: 1.5
        )
        let section = FinalCutPro.FCPXML.RoleInventoryReportSection(
            selectedRoles: [shared, shared],
            roleSheets: [
                FinalCutPro.FCPXML.RoleSheet(sheetName: "Video", rows: [shared, otherCard])
            ],
            showsScreenshotsColumn: true
        )
        
        let workbookURL = root.appendingPathComponent("Report.xlsx")
        let folder = try #require(
            await FinalCutPro.FCPXML.RoleInventoryScreenshotFolder.write(
                roleInventory: section,
                beside: workbookURL
            )
        )
        
        let plain = folder.appendingPathComponent("A001C003-00-00-01-12.png")
        let suffixed = folder.appendingPathComponent("A001C003-00-00-01-12_1.png")
        #expect(FileManager.default.fileExists(atPath: plain.path))
        #expect(FileManager.default.fileExists(atPath: suffixed.path))
        
        let contents = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        #expect(contents.count == 2)
        #expect(try #require(imagePixelSize(Data(contentsOf: plain))) == (32, 18))
        #expect(try #require(imagePixelSize(Data(contentsOf: suffixed))) == (40, 20))
    }
    
    @Test("Excel export writes full-size PNGs beside the workbook")
    @MainActor
    func excelExportWritesFullSizePNGsBesideTheWorkbook() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        
        let media = root.appendingPathComponent("Interview.png")
        try writeSolidPNG(to: media, width: 640, height: 360)
        
        let report = FinalCutPro.FCPXML.Report(
            projectName: "Screenshot Export",
            roleInventory: FinalCutPro.FCPXML.RoleInventoryReportSection(
                selectedRoles: [
                    inventoryRow(
                        mediaURL: media,
                        sourceFileName: "Interview.mov",
                        stamp: "01-00-00-00",
                        fileTimeSeconds: 3600
                    )
                ],
                showsScreenshotsColumn: true
            )
        )
        
        let workbookURL = root.appendingPathComponent("Screenshot Export.xlsx")
        try await FinalCutPro.FCPXML.ReportExcelExport.export(report, to: workbookURL)
        
        let folder = FinalCutPro.FCPXML.ReportExcelExport.screenshotDirectory(beside: workbookURL)
        let pngURL = folder.appendingPathComponent("Interview-01-00-00-00.png")
        #expect(FileManager.default.fileExists(atPath: workbookURL.path))
        #expect(folder.lastPathComponent == "Screenshots")
        #expect(try #require(imagePixelSize(Data(contentsOf: pngURL))) == (640, 360))
    }
    
    private func inventoryRow(
        mediaURL: URL,
        sourceFileName: String,
        stamp: String,
        fileTimeSeconds: Double
    ) -> FinalCutPro.FCPXML.RoleClipReportRow {
        FinalCutPro.FCPXML.RoleClipReportRow(
            roleSubrole: "Video",
            clipName: "Clip",
            category: "Video",
            enabled: "✓",
            timelineIn: "00:00:00:00",
            timelineOut: "00:00:05:00",
            clipDuration: "00:00:05:00",
            sourceIn: "01:00:00:00",
            sourceOut: "01:00:05:00",
            sourceDuration: "00:00:05:00",
            screenshotMediaFileURL: mediaURL,
            screenshotFileTimeSeconds: fileTimeSeconds,
            screenshotFileTimecodeStamp: stamp,
            sourceFileName: sourceFileName
        )
    }
    
    private func writeSolidPNG(to url: URL, width: Int, height: Int) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw NSError(domain: "OFKScreenshotFolderTest", code: 1)
        }
        context.setFillColor(red: 0.1, green: 0.6, blue: 0.3, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw NSError(domain: "OFKScreenshotFolderTest", code: 2)
        }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw NSError(domain: "OFKScreenshotFolderTest", code: 3)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "OFKScreenshotFolderTest", code: 4)
        }
    }
    
    private func imagePixelSize(_ data: Data) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }
        return (width, height)
    }
}
