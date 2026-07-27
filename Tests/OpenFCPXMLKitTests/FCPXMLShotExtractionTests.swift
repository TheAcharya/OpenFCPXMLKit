//
// FCPXMLShotExtractionTests.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Still-image Shot Extraction library tests.
//

import Foundation
import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import OpenFCPXMLKit

@Suite("Shot Extraction")
struct FCPXMLShotExtractionTests {

    @Test("Shot ID uses three-digit padding from scene number")
    func shotIDUsesThreeDigitPaddingFromSceneNumber() {
        #expect(
            FinalCutPro.FCPXML.ShotRecord.makeShotID(sceneNumber: "50", shotNumber: 1)
                == "50-001"
        )
        #expect(
            FinalCutPro.FCPXML.ShotRecord.makeShotID(sceneNumber: "50", shotNumber: 30)
                == "50-030"
        )
    }

    @Test("Shot duration floors to HH:MM:SS")
    func shotDurationFloorsToHHMMSS() {
        #expect(
            FinalCutPro.FCPXML.ShotRecord.formatDurationHHMMSS(seconds: 2.583)
                == "00:00:02"
        )
        #expect(
            FinalCutPro.FCPXML.ShotRecord.formatDurationHHMMSS(seconds: 0.166)
                == "00:00:00"
        )
        #expect(
            FinalCutPro.FCPXML.ShotRecord.formatDurationHHMMSS(seconds: 3661.9)
                == "01:01:01"
        )
    }

    @Test("Folder format medium uses hyphenated timestamp layout")
    func folderFormatMediumUsesHyphenatedTimestampLayout() throws {
        let components = DateComponents(
            calendar: .current,
            timeZone: .current,
            year: 2026,
            month: 7,
            day: 27,
            hour: 9,
            minute: 14,
            second: 21
        )
        let date = try #require(components.date)
        let medium = FinalCutPro.FCPXML.ShotExtractionFolderFormat.medium.folderName(
            timelineName: "Demo_V1",
            format: .csv,
            now: date
        )
        #expect(medium == "Demo_V1-2026-07-27-09-14-21")

        let long = FinalCutPro.FCPXML.ShotExtractionFolderFormat.long.folderName(
            timelineName: "Demo_V1",
            format: .notion,
            now: date
        )
        #expect(long == "Demo_V1-2026-07-27-09-14-21-[Notion]")
    }

    @Test("Extracts reused stills as distinct PNG shot IDs with CSV")
    func extractsReusedStillsAsDistinctPNGShotIDsWithCSV() async throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace.root) }

        let pngA = try writeSolidPNG(to: workspace.mediaDir.appendingPathComponent("a.png"), seed: 1)
        let pngB = try writeSolidPNG(to: workspace.mediaDir.appendingPathComponent("b.jpg"), seed: 2)

        let xml = stillTimelineXML(
            projectName: "Scene 50",
            clips: [
                ("r2", pngA, "0s", "5s"),
                ("r3", pngB, "5s", "2s"),
                ("r2", pngA, "7s", "3s"),
            ]
        )
        let fcpxmlURL = workspace.root.appendingPathComponent("Scene50.fcpxml")
        try xml.write(to: fcpxmlURL, atomically: true, encoding: .utf8)

        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
        let fixedNow = Date(timeIntervalSince1970: 1_658_552_940) // 2022-07-23 01:09 UTC-ish; folder uses local calendar
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: "50",
            extractFormat: .csv,
            outputDir: workspace.outputDir,
            folderFormat: .short,
            mediaBaseURL: workspace.mediaDir,
            now: fixedNow
        )

        let result = try await fcpxml.extractShots(options: options)

        #expect(result.shots.count == 3)
        #expect(result.shots.map(\.shotID) == ["50-001", "50-002", "50-003"])
        #expect(result.shots.map(\.shotNumber) == [1, 2, 3])
        #expect(result.shots.map(\.sceneNumber) == ["50", "50", "50"])
        #expect(result.shots.map(\.imageFilename) == ["50-001.png", "50-002.png", "50-003.png"])
        #expect(result.shots[0].shotDuration == "00:00:05")
        #expect(result.shots[1].shotDuration == "00:00:02")
        #expect(result.shots[2].shotDuration == "00:00:03")

        for path in result.imagePaths {
            #expect(FileManager.default.fileExists(atPath: path.path))
            #expect(path.pathExtension.lowercased() == "png")
        }

        let csv = try String(contentsOf: result.manifestPath, encoding: .utf8)
        #expect(csv.contains("Shot ID"))
        #expect(csv.contains("50-001"))
        #expect(csv.contains("50-003.png"))
        #expect(csv.contains("Icon Image"))
        #expect(csv.contains("Image Filename"))
        #expect(csv.contains("Icon Image,Image Filename"))
        #expect(result.shots.allSatisfy { $0.iconImage.isEmpty })
    }

    @Test("Icon option fills Icon Image column before Image Filename")
    func iconOptionFillsIconImageColumnBeforeImageFilename() async throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace.root) }

        let png = try writeSolidPNG(to: workspace.mediaDir.appendingPathComponent("still.png"), seed: 9)
        let xml = stillTimelineXML(
            projectName: "Icon Scene",
            clips: [("r2", png, "0s", "2s")]
        )
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: "9",
            extractFormat: .csv,
            outputDir: workspace.outputDir,
            folderFormat: .short,
            mediaBaseURL: workspace.mediaDir,
            icon: "🎬"
        )

        let result = try await fcpxml.extractShots(options: options)
        #expect(result.shots.count == 1)
        #expect(result.shots[0].iconImage == "🎬")

        let csv = try String(contentsOf: result.manifestPath, encoding: .utf8)
        #expect(csv.contains("Icon Image,Image Filename"))
        #expect(csv.contains("🎬"))
    }

    @Test("Notion format writes JSON array with shot fields")
    func notionFormatWritesJSONArrayWithShotFields() async throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace.root) }

        let png = try writeSolidPNG(to: workspace.mediaDir.appendingPathComponent("only.png"), seed: 3)
        let xml = stillTimelineXML(
            projectName: "Scene 7",
            clips: [("r2", png, "0s", "1s")]
        )
        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: "7",
            extractFormat: .notion,
            outputDir: workspace.outputDir,
            folderFormat: .short,
            mediaBaseURL: workspace.mediaDir
        )

        let result = try await fcpxml.extractShots(options: options)
        #expect(result.manifestPath.pathExtension == "json")

        let data = try Data(contentsOf: result.manifestPath)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(json.count == 1)
        #expect(json[0]["Shot ID"] as? String == "7-001")
        #expect(json[0]["Shot Number"] as? String == "1")
        #expect(json[0]["Scene Number"] as? String == "7")
        #expect(json[0]["Icon Image"] as? String == "")
        #expect(json[0]["Image Filename"] as? String == "7-001.png")
    }

    @Test("Rejects primary timeline that contains video media")
    func rejectsPrimaryTimelineThatContainsVideoMedia() async throws {
        let workspace = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace.root) }

        let videoURL = workspace.mediaDir.appendingPathComponent("clip.mov")
        try Data([0, 1, 2, 3]).write(to: videoURL)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
                <asset id="r2" name="Clip" uid="VID1" start="0s" duration="10s" hasVideo="1" format="r1" videoSources="1">
                    <media-rep kind="original-media" src="\(videoURL.absoluteString)"/>
                </asset>
            </resources>
            <library>
                <event name="Event">
                    <project name="Video Project">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                <asset-clip ref="r2" offset="0s" name="Clip" duration="10s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """

        let fcpxml = try FinalCutPro.FCPXML(fileContent: Data(xml.utf8))
        let options = FinalCutPro.FCPXML.ShotExtractionOptions(
            sceneNumber: "1",
            extractFormat: .csv,
            outputDir: workspace.outputDir,
            folderFormat: .short,
            mediaBaseURL: workspace.mediaDir
        )

        await #expect(throws: FinalCutPro.FCPXML.ShotExtractionError.self) {
            _ = try await fcpxml.extractShots(options: options)
        }
    }

    // MARK: - Helpers

    private struct Workspace {
        var root: URL
        var mediaDir: URL
        var outputDir: URL
    }

    private func makeWorkspace() throws -> Workspace {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OFK-ShotExtraction-\(UUID().uuidString)", isDirectory: true)
        let mediaDir = root.appendingPathComponent("Media", isDirectory: true)
        let outputDir = root.appendingPathComponent("Output", isDirectory: true)
        try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        return Workspace(root: root, mediaDir: mediaDir, outputDir: outputDir)
    }

    private func writeSolidPNG(to url: URL, seed: Int) throws -> URL {
        let width = 8
        let height = 8
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for index in 0 ..< (width * height) {
            let offset = index * 4
            pixels[offset] = UInt8((seed * 40) % 255)
            pixels[offset + 1] = UInt8((seed * 80) % 255)
            pixels[offset + 2] = UInt8((seed * 120) % 255)
            pixels[offset + 3] = 255
        }

        let data = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw TestCancelError("Could not create PNG destination")
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            throw TestCancelError("Could not create CGImage")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw TestCancelError("Could not finalize PNG")
        }
        try (data as Data).write(to: url)
        return url
    }

    private func stillTimelineXML(
        projectName: String,
        clips: [(id: String, url: URL, offset: String, duration: String)]
    ) -> String {
        var resources = """
        <format id="r1" frameDuration="100/2400s" width="1920" height="1080"/>
        """
        var seen = Set<String>()
        for clip in clips where !seen.contains(clip.id) {
            seen.insert(clip.id)
            resources += """
            <asset id="\(clip.id)" name="\(clip.url.deletingPathExtension().lastPathComponent)" uid="\(clip.id.uppercased())" start="0s" duration="0s" hasVideo="1" format="r1" videoSources="1">
                <media-rep kind="original-media" src="\(clip.url.absoluteString)"/>
            </asset>
            """
        }

        var spine = ""
        for clip in clips {
            spine += """
            <video ref="\(clip.id)" offset="\(clip.offset)" name="\(clip.url.deletingPathExtension().lastPathComponent)" start="0s" duration="\(clip.duration)"/>
            """
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.14">
            <resources>
                \(resources)
            </resources>
            <library>
                <event name="Event">
                    <project name="\(projectName)">
                        <sequence format="r1" duration="10s" tcStart="0s" tcFormat="NDF">
                            <spine>
                                \(spine)
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}

private struct TestCancelError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
