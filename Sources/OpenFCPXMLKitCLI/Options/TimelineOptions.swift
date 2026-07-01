//
//  TimelineOptions.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Timeline-related flags and options (e.g. --create-project).
//

import ArgumentParser

struct TimelineOptions: ParsableArguments {
    @Flag(name: .long, help: "Create a new empty FCPXML project (requires --width, --height, --rate, and <output-dir> positional).")
    var createProject: Bool = false

    @Option(name: .long, help: "Project width in pixels (used with --create-project).")
    var width: Int?

    @Option(name: .long, help: "Project height in pixels (used with --create-project).")
    var height: Int?

    @Option(name: .long, help: "Frame rate (e.g. 24, 25, 29.97) (used with --create-project).")
    var rate: String?

    @Option(name: .customLong("project-version"), help: "FCPXML version for the new project (e.g. 1.10, 1.14). Default: 1.14. (used with --create-project).")
    var projectVersion: String?
}
