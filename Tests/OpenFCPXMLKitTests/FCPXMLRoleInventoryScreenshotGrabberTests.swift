//
//  FCPXMLRoleInventoryScreenshotGrabberTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Unit tests for Role Inventory screenshot JPEG grabs (stills).
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import OpenFCPXMLKit

@Suite("Role inventory screenshot grabber")
struct FCPXMLRoleInventoryScreenshotGrabberTests {
    @Test("Still image file yields JPEG thumbnail")
    func stillImageFileYieldsJPEGThumbnail() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        
        try writeSolidPNG(to: url, width: 64, height: 36)
        
        let data = try #require(
            await FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.jpegData(
                fileURL: url,
                fileTimeSeconds: 0
            )
        )
        #expect(data.count > 100)
        #expect(data.starts(with: [0xFF, 0xD8])) // JPEG SOI
    }
    
    @Test("Missing file returns nil")
    func missingFileReturnsNil() async {
        let url = URL(fileURLWithPath: "/tmp/ofk-does-not-exist-\(UUID().uuidString).mov")
        let data = await FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.jpegData(
            fileURL: url,
            fileTimeSeconds: 1
        )
        #expect(data == nil)
    }
    
    @Test("Multi-URL grab falls back to second existing still")
    func multiURLGrabFallsBackToSecondExistingStill() async throws {
        let missing = URL(fileURLWithPath: "/tmp/ofk-does-not-exist-\(UUID().uuidString).mov")
        let existing = FileManager.default.temporaryDirectory
            .appendingPathComponent("ofk-screenshot-fallback-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: existing) }
        try writeSolidPNG(to: existing, width: 48, height: 27)
        
        let data = try #require(
            await FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.jpegData(
                fileURLs: [missing, existing],
                fileTimeSeconds: 0
            )
        )
        #expect(data.starts(with: [0xFF, 0xD8]))
    }
    
    @Test("Multi-URL grab returns nil when every candidate is missing")
    func multiURLGrabReturnsNilWhenAllMissing() async {
        let first = URL(fileURLWithPath: "/tmp/ofk-missing-a-\(UUID().uuidString).mov")
        let second = URL(fileURLWithPath: "/tmp/ofk-missing-b-\(UUID().uuidString).mov")
        let data = await FinalCutPro.FCPXML.RoleInventoryScreenshotGrabber.jpegData(
            fileURLs: [first, second],
            fileTimeSeconds: 0
        )
        #expect(data == nil)
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
            throw NSError(domain: "OFKScreenshotTest", code: 1)
        }
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            throw NSError(domain: "OFKScreenshotTest", code: 2)
        }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw NSError(domain: "OFKScreenshotTest", code: 3)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "OFKScreenshotTest", code: 4)
        }
    }
}
