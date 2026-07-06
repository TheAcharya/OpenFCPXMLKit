//
//  FCPXMLMediaSummaryReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Builds the Media Summary report section from FCPXML.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Builds the Media Summary sheet: missing media file paths referenced by the project.
    enum MediaSummaryReportBuilder {
        static func build(
            document: any OFKXMLDocument,
            baseURL: URL?
        ) -> MediaSummaryReportSection {
            MediaSummaryReportSection(
                missingMediaPaths: missingMediaPaths(
                    in: document,
                    baseURL: baseURL
                )
            )
        }
        
        private static func missingMediaPaths(
            in document: any OFKXMLDocument,
            baseURL: URL?
        ) -> [String] {
            let extractor = MediaExtractor()
            let result = extractor.extractMediaReferences(from: document, baseURL: baseURL)
            let fileManager = FileManager.default
            
            var missingPaths: Set<String> = []
            
            for reference in result.references {
                guard let url = reference.url, url.isFileURL else { continue }
                let path = url.path
                guard !path.isEmpty else { continue }
                if !fileManager.fileExists(atPath: path) {
                    missingPaths.insert(path)
                }
            }
            
            return missingPaths.sorted()
        }
    }
}
