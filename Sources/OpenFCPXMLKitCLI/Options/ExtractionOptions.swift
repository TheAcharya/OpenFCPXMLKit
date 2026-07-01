//
//  ExtractionOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Options for media copy (--media-copy).
//

import ArgumentParser

struct ExtractionOptions: ParsableArguments {
    @Flag(name: .long, help: "Scan FCPXML/FCPXMLD and copy all referenced media files to output-dir.")
    var mediaCopy: Bool = false
}
