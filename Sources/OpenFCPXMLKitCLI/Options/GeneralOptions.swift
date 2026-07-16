//
//  GeneralOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//  General-purpose flags and options for the CLI.
//

import ArgumentParser

/// Output format for version conversion: single .fcpxml file or .fcpxmld bundle.
/// Versions 1.5–1.9 support only .fcpxml; when --extension-type is fcpxmld, the CLI uses .fcpxml for those versions.
enum OutputExtensionType: String, CaseIterable, ExpressibleByArgument, Sendable {
    case fcpxml
    case fcpxmld
}

struct GeneralOptions: ParsableArguments {
    @Flag(name: .long, help: "Check and print FCPXML document version.")
    var checkVersion: Bool = false

    @Option(name: .long, help: ArgumentHelp("Convert FCPXML to the given version (e.g. 1.10, 1.14) and write to output-dir.", valueName: "version"))
    var convertVersion: String?

    @Option(name: .long, help: "Output format for --convert-version: fcpxmld (bundle) or fcpxml (single file). Default: fcpxmld when converting. For target versions 1.5–1.9, .fcpxml is used regardless.")
    var extensionType: OutputExtensionType?

    @Flag(name: .long, help: "Perform robust check and validation of FCPXML/FCPXMLD (semantic + DTD).")
    var validate: Bool = false
}
