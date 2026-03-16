//
//  FCPXMLInit.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Initializers for creating FCPXML instances from file content.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Parse FCPXML/FCPXMLD file contents exported from Final Cut Pro.
    public init(fileContent data: Data) throws {
        let xmlDocument = try PNXMLDefaultFactory().makeDocument(data: data, options: [])
        self.init(fileContent: xmlDocument)
    }

    /// Initialize from FCPXML file that has been loaded into a `PNXMLDocument`.
    ///
    /// For fcpxml v1.10+ .fcpxmld bundles, load the .fcpxml file that is inside the bundle.
    public init(fileContent xml: any PNXMLDocument) {
        self.xml = xml
    }
    
    // Note: init for new empty FCPXML file not yet implemented.
}
