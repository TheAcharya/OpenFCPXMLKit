//
//  FCPXMLRoleInventoryScreenshotFolder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Writes full-size Role Inventory screenshot PNGs beside an Excel workbook.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Writes one full-frame PNG per unique Source In grab into `Screenshots`
    /// next to the workbook. Excel cells keep the 480px JPEG thumbnail.
    enum RoleInventoryScreenshotFolder {
        static let directoryName = "Screenshots"
        
        /// Directory that sits beside ``workbookURL``.
        static func directory(beside workbookURL: URL) -> URL {
            workbookURL
                .deletingLastPathComponent()
                .appendingPathComponent(directoryName, isDirectory: true)
        }
        
        /// Writes PNGs for rows that have a screenshot target.
        ///
        /// The same resolved media and file time is written once. A different
        /// file that produces the same `SourceStem-HH-MM-SS-FF.png` name is
        /// saved as `_1`, `_2`, and so on. A file already at that path is
        /// replaced. Rows with no media, and grabs that cannot be decoded,
        /// do not create a file. Returns the folder URL when at least one PNG
        /// was written.
        static func write(
            roleInventory: RoleInventoryReportSection,
            beside workbookURL: URL
        ) async throws -> URL? {
            let folder = directory(beside: workbookURL)
            var usedNames: Set<String> = []
            var seenGrabs: Set<String> = []
            var didCreateFolder = false
            var wroteFile = false
            
            for row in rows(in: roleInventory) {
                let fileURLs = [
                    row.screenshotMediaFileURL,
                    row.screenshotFallbackMediaFileURL
                ].compactMap { $0 }
                guard !fileURLs.isEmpty else { continue }
                
                let fileTime = row.screenshotFileTimeSeconds ?? 0
                let identity = RoleInventoryScreenshotFileName.grabIdentity(
                    fileURLs: fileURLs,
                    fileTimeSeconds: fileTime
                )
                guard seenGrabs.insert(identity).inserted else { continue }
                
                guard let png = await RoleInventoryScreenshotGrabber.pngData(
                    fileURLs: fileURLs,
                    fileTimeSeconds: fileTime
                ) else {
                    continue
                }
                
                let stamp = row.screenshotFileTimecodeStamp
                    ?? RoleInventoryScreenshotFileName.timecodeStamp(
                        fileTimeSeconds: fileTime,
                        frameRate: .fps24
                    )
                let preferred = RoleInventoryScreenshotFileName.preferredFileName(
                    sourceFileName: row.sourceFileName,
                    timecodeStamp: stamp
                )
                let fileName = RoleInventoryScreenshotFileName.uniqueFileName(
                    preferred: preferred,
                    existing: usedNames
                )
                usedNames.insert(fileName)
                
                if !didCreateFolder {
                    try FileManager.default.createDirectory(
                        at: folder,
                        withIntermediateDirectories: true
                    )
                    didCreateFolder = true
                }
                
                let destination = folder.appendingPathComponent(fileName)
                try png.write(to: destination, options: .atomic)
                wroteFile = true
            }
            
            return wroteFile ? folder : nil
        }
        
        /// Selected Roles Inventory first, then each per-role sheet.
        /// The first successful grab keeps the unsuffixed file name.
        private static func rows(
            in roleInventory: RoleInventoryReportSection
        ) -> [RoleClipReportRow] {
            var rows = roleInventory.selectedRoles
            for sheet in roleInventory.roleSheets {
                rows.append(contentsOf: sheet.rows)
            }
            return rows
        }
    }
}
