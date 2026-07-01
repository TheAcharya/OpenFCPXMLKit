//
//  FCPXMLTestResources.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Path resolution utilities for test sample files.
//

import Foundation
import XCTest

/// Resolves the package root (directory containing Package.swift) from a file URL (e.g. `#file`).
func packageRoot(relativeToFile fileURL: URL = URL(fileURLWithPath: #file)) -> URL {
    var url = fileURL
    for _ in 0..<6 {
        url = url.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
            return url
        }
    }
    return url
}

/// Returns whether the directory appears to contain FCPXML samples (has at least one .fcpxml file).
private func directoryContainsFCPXMLSamples(_ dir: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: dir.path) else { return false }
    let probe = dir.appendingPathComponent("24.fcpxml")
    return FileManager.default.fileExists(atPath: probe.path)
}

/// Directory containing FCPXML sample files (Tests/FCPXML Samples/FCPXML).
/// Tries, in order: test bundle resource (several layouts), CI env (GITHUB_WORKSPACE), current directory, then #file-based package root.
func fcpxmlSamplesDirectory(relativeToFile fileURL: URL = URL(fileURLWithPath: #file)) -> URL {
    let samplesSubpath = ["Tests", "FCPXML Samples", "FCPXML"]
    func samplesDir(fromRoot root: URL) -> URL {
        samplesSubpath.reduce(root) { $0.appendingPathComponent($1, isDirectory: true) }
    }

    // 1. Test bundle (swift test / xcodebuild when resources are bundled)
    if let resourceURL = Bundle.module.resourceURL {
        let bundleCandidates: [URL] = [
            resourceURL.appendingPathComponent("FCPXML Samples", isDirectory: true).appendingPathComponent("FCPXML", isDirectory: true),
            resourceURL.appendingPathComponent("FCPXML", isDirectory: true),
            resourceURL,
        ]
        for dir in bundleCandidates {
            if directoryContainsFCPXMLSamples(dir) {
                return dir
            }
        }
    }

    // 2. CI: GitHub Actions sets GITHUB_WORKSPACE to the repo root
    if let workspace = ProcessInfo.processInfo.environment["GITHUB_WORKSPACE"], !workspace.isEmpty {
        let dir = samplesDir(fromRoot: URL(fileURLWithPath: workspace))
        if directoryContainsFCPXMLSamples(dir) {
            return dir
        }
    }

    // 3. Current working directory (e.g. swift test from package root; xcodebuild may use DerivedData)
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    if FileManager.default.fileExists(atPath: cwd.appendingPathComponent("Package.swift").path) {
        let dir = samplesDir(fromRoot: cwd)
        if directoryContainsFCPXMLSamples(dir) {
            return dir
        }
    }

    // 4. Walk up from #file (local Xcode / swift test from repo)
    return samplesDir(fromRoot: packageRoot(relativeToFile: fileURL))
}

/// URL for a named FCPXML sample (e.g. "24", "Complex") with extension .fcpxml.
func urlForFCPXMLSample(named name: String, relativeToFile fileURL: URL = URL(fileURLWithPath: #file)) -> URL {
    fcpxmlSamplesDirectory(relativeToFile: fileURL).appendingPathComponent("\(name).fcpxml")
}

/// Names of sample FCPXML files available in Tests/FCPXML Samples/FCPXML.
enum FCPXMLSampleName: String, CaseIterable {
    case frameRate23_98 = "23.98"
    case frameRate24 = "24"
    case frameRate24With25Media = "24With25Media"
    case frameRate25i = "25i"
    case frameRate29_97 = "29.97"
    case frameRate29_97d = "29.97d"
    case frameRate30 = "30"
    case frameRate50 = "50"
    case frameRate59_94 = "59.94"
    case frameRate60 = "60"
    case annotations = "Annotations"
    case audioOnly = "AudioOnly"
    case auditionMarkers = "AuditionMarkers"
    case auditionMarkers2 = "AuditionMarkers2"
    case auditionMarkers3 = "AuditionMarkers3"
    case basicMarkers = "BasicMarkers"
    case basicMarkers_1HourProjectStart = "BasicMarkers_1HourProjectStart"
    case clipMetadata = "ClipMetadata"
    case complex = "Complex"
    case compoundClips = "CompoundClips"
    case custom500x500 = "Custom500x500"
    case disabledClips = "DisabledClips"
    case empty1920x1080 = "1920x1080"
    case empty4096x2160 = "4096x2160"
    case empty5120x2160 = "5120x2160"
    case keywords = "Keywords"
    case multicamMarkers = "MulticamMarkers"
    case multicamMarkers2 = "MulticamMarkers2"
    case occlusion = "Occlusion"
    case occlusion2 = "Occlusion2"
    case occlusion3 = "Occlusion3"
    case rolesList = "RolesList"
    case standaloneAssetClip = "StandaloneAssetClip"
    case standaloneLibraryEventClip = "StandaloneLibraryEventClip"
    case standaloneRefClip = "StandaloneRefClip"
    case structure = "Structure"
    case syncClip = "SyncClip"
    case syncClipRoles = "SyncClipRoles"
    case syncClipRoles2 = "SyncClipRoles2"
    case titlesRoles = "TitlesRoles"
    case transitionMarkers1 = "TransitionMarkers1"
    case transitionMarkers2 = "TransitionMarkers2"
    case twoClipsMarkers = "TwoClipsMarkers"
}
