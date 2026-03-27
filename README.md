<p align="center">
  <a href="https://github.com/TheAcharya/pipeline-neo"><img src="Assets/Pipeline Neo_Icon.png" height="200">
  <h1 align="center">Pipeline Neo (CLI & Library)</h1>
</p>

<p align="center"><a href="https://github.com/TheAcharya/pipeline-neo/blob/main/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat" alt="license"/></a>&nbsp;<a href="https://github.com/TheAcharya/pipeline-neo"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg?style=flat" alt="platform"/></a>&nbsp;<a href="https://github.com/TheAcharya/pipeline-neo/actions/workflows/build.yml"><img src="https://github.com/TheAcharya/pipeline-neo/actions/workflows/build.yml/badge.svg" alt="build"/></a>&nbsp;<a href="https://github.com/TheAcharya/pipeline-neo/actions/workflows/codeql.yml"><img src="https://github.com/TheAcharya/pipeline-neo/actions/workflows/codeql.yml/badge.svg" alt="CodeQL Advanced"/></a>&nbsp;<img src="https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat" alt="Swift"/>&nbsp;<img src="https://img.shields.io/badge/Xcode-16+-blue.svg?style=flat" alt="Xcode"/></p>

A modern Swift 6 framework for working with Final Cut Pro's FCPXML with full concurrency support and SwiftTimecode integration. Pipeline Neo is a spiritual successor to the original [Pipeline](https://github.com/reuelk/pipeline), modernised for Swift 6.0 and contemporary development practices. 

Pipeline Neo provides a comprehensive API for parsing, creating, and manipulating FCPXML files with advanced timecode operations, async/await patterns, and robust error handling. Built with Swift 6.0 and targeting **macOS 12+** and **iOS 15+**, it offers type-safe operations, comprehensive test coverage (686 tests), and seamless integration with SwiftTimecode for professional video editing workflows. A cross-platform XML abstraction layer (Foundation on macOS, AEXML on iOS) keeps the library usable on both platforms.

Pipeline Neo is currently in an experimental stage. It covers most core FCPXML attributes and parameters and provides a solid foundation for parsing, creation, and manipulation—with room for future expansion and additional feature coverage.

This codebase is developed using AI agents.

> [!IMPORTANT]
> Pipeline Neo has yet to be extensively tested in production environments, real-world workflows, or application integration. This library serves as a modernised foundation for AI-assisted development and experimentation with FCPXML processing capabilities.

## Table of Contents

- [Core Features](#core-features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Before CLI Usage](#before-cli-usage)
  - [Pre-Compiled CLI Binary](#pre-compiled-cli-binary)
  - [Using Homebrew](#using-homebrew)
  - [Pre-Compiled CLI Binary (macOS Installer)](#pre-compiled-cli-binary-macos-installer)
  - [Compiled From Source](#compiled-from-source)
- [CLI Usage](#cli-usage)
- [API Documentation](#api-documentation)
- [FCPXML Version Support](#fcpxml-version-support)
- [Modularity & Safety](#modularity--safety)
- [Architecture Overview](#architecture-overview)
- [Credits](#credits)
- [License](#license)
- [Reporting Bugs](#reporting-bugs)
- [Contribution](#contribution)

## Core Features

- **FCPXML I/O**: Read, create, modify documents (.fcpxml/.fcpxmld bundles); load via `FCPXMLFileLoader` (sync/async); create FCPXML from scratch with events, projects, resources, and clips.
- **Parsing & Validation**: Parse and validate against bundled DTDs (1.5–1.14); structural/reference and DTD schema validation (full DTD on macOS; cross-platform structural validation on iOS via `FCPXMLStructuralValidator`); 686 tests across 15+ FCPXML sample files (including empty timeline creation, project-creation export, AEXML parity, and validation suites).
- **Timecode Operations**: SwiftTimecode integration (`CMTime`, `Timecode`, FCPXML time strings); `FCPXMLTimecode` custom type (arithmetic, frame alignment, conversion); all FCP frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps).
- **Typed Models**: Resources, events, clips, projects, adjustments (Crop, Transform, Blend, Stabilization, Volume, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation), filters (VideoFilter, AudioFilter, VideoFilterMask with FilterParameter), transitions, multicam (Media.Multicam, Angle, MulticamSource, MCClip), captions/titles (Caption, Title with TextStyle/TextStyleDefinition), smart collections (SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), collections (CollectionFolder, KeywordCollection).
- **Timeline Operations**: Build `Timeline`; create valid projects with custom or preset dimensions and frame rate (via `TimelineFormat`); export to FCPXML/.fcpxmld (including zero-clip/empty timelines); optional event/project UIDs and library location (`FCPXMLUID`); ripple insert, auto lane assignment, clip queries (lane/time range/asset ID), lane range computation; metadata (markers, chapter markers, keywords, ratings, custom metadata, timestamps); secondary storylines; `TimelineFormat` presets and computed properties.
- **Media Operations**: Extract asset/locator URLs; copy with deduplication; MIME type detection (`UTType`/`AVFoundation`); asset validation (existence, lane compatibility); silence detection; duration measurement; parallel file I/O; still image asset support.
- **Analysis & Conversion**: Cut detection (edit points, transitions, gaps); typed element filtering (`FCPXMLElementType`); version conversion (strip elements, validate, save as .fcpxml/.fcpxmld); per-version DTD validation; element stripping based on target version DTDs.
- **Animation**: KeyframeAnimation, Keyframe with interpolation, FadeIn/FadeOut; integrated with FilterParameter; auxValue support (FCPXML 1.11+).
- **Extensions**: CMTime Codable (FCPXML time string encoding/decoding); CollectionFolder and KeywordCollection for organization; Live Drawing (FCPXML 1.11+); HiddenClipMarker (FCPXML 1.13+); Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps).
- **CLI**: `pipeline-neo` with `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--create-project` (new empty FCPXML project with width/height/rate/version), logging options (see CLI README).
- **Architecture**: Protocol-oriented, dependency-injected; sync/async APIs; Swift 6 concurrency-safe design; comprehensive test suite with file-based and logic tests.

## Requirements

- **macOS 12.0+** or **iOS 15.0+** (CLI is macOS-only; library supports both)
- Xcode 16.0+
- Swift 6.0+ (strict concurrency compliant; protocols and public types are `Sendable` where appropriate; `@unchecked Sendable` only where required for Foundation/ObjC interop)

## Installation

### Swift Package Manager

Add Pipeline Neo to your project in Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/TheAcharya/pipeline-neo`
3. Select the version you want to use
4. Click Add Package

Or add it to your `Package.swift`:

```swift
// swift-tools-version: 6.0
// Add Pipeline Neo as a dependency and link it to your target.
import PackageDescription

let package = Package(
    name: "MyPackage",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/TheAcharya/pipeline-neo", from: "2.5.2")
    ],
    targets: [
        .target(
            name: "MyTarget",
            dependencies: ["PipelineNeo"]
        )
    ]
)
```

## Before CLI Usage

First, ensure your system is configured to allow the tool to run:

<details><summary>Privacy & Security Settings</summary>
<p>

Navigate to the `Privacy & Security` settings and set your preference to `App Store and identified developers`.

<p align="center"> <img src="https://github.com/TheAcharya/pipeline-neo/blob/main/Assets/macOS-privacy.png?raw=true"> </p>

</p>
</details>

### Pre-Compiled CLI Binary

Download the latest release of the CLI universal binary [here](https://github.com/TheAcharya/pipeline-neo/releases).

Extract the `pipeline-neo-cli-portable-x.x.x.zip` file from the release.

### Using [Homebrew](https://brew.sh/)

```bash
$ brew install TheAcharya/homebrew-tap/pipeline-neo
```
```bash
$ brew uninstall --cask pipeline-neo
```

Upon completion, find the installed binary `pipeline-neo` located within `/usr/local/bin`. Since this is a standard directory part of the environment search path, it will allow running `pipeline-neo` from any directory like a standard command.

### Pre-Compiled CLI Binary (macOS Installer)

#### Install

Download the latest release of the CLI installer package [here](https://github.com/TheAcharya/pipeline-neo/releases).

Use the `pipeline-neo-cli.pkg` installer to install the command-line binary into your system. Upon completion, find the installed binary `pipeline-neo` located within `/usr/local/bin`. Since this is a standard directory part of the environment search path, it will allow running `pipeline-neo` from any directory like a standard command.

<p align="center"> <img src="https://github.com/TheAcharya/pipeline-neo/blob/main/Assets/macOS-installer.png?raw=true"> </p>

#### Uninstall

To uninstall, run this terminal command. It will require your account password.

```bash
sudo rm /usr/local/bin/pipeline-neo
```

### Compiled From Source

```shell
VERSION=2.5.2 # replace this with the git tag of the version you need
git clone https://github.com/TheAcharya/pipeline-neo.git
cd pipeline-neo
git checkout "tags/$VERSION"
swift build -c release
```

Once the build has finished, the `pipeline-neo` executable will be located at `.build/release/`.

## CLI Usage

```plain
$ pipeline-neo --help

OVERVIEW: Experimental tool to read and validate Final Cut Pro FCPXML/FCPXMLD.

https://github.com/TheAcharya/pipeline-neo

USAGE: [<options>] [<fcpxml-path>] [<output-dir>]

ARGUMENTS:
  <fcpxml-path>           Input FCPXML file / FCPXMLD bundle; or output directory when using --create-project.
  <output-dir>            Output directory (for --convert-version, --media-copy, etc.).

GENERAL:
  --check-version         Check and print FCPXML document version.
  --convert-version <version>
                          Convert FCPXML to the given version (e.g. 1.10, 1.14) and write to output-dir.
  --extension-type <extension-type>
                          Output format for --convert-version: fcpxmld (bundle) or fcpxml (single file).
                          Default: fcpxmld. For target versions 1.5–1.9, .fcpxml is used regardless. (values:
                          fcpxml, fcpxmld; default: fcpxmld)
  --validate              Perform robust check and validation of FCPXML/FCPXMLD (semantic + DTD).

TIMELINE:
  --create-project        Create a new empty FCPXML project (requires --width, --height, --rate, and
                          <output-dir> positional).
  --width <width>         Project width in pixels (used with --create-project).
  --height <height>       Project height in pixels (used with --create-project).
  --rate <rate>           Frame rate (e.g. 24, 25, 29.97) (used with --create-project).
  --project-version <project-version>
                          FCPXML version for the new project (e.g. 1.10, 1.14). Default: 1.14. (used with
                          --create-project).

EXTRACTION:
  --media-copy            Scan FCPXML/FCPXMLD and copy all referenced media files to output-dir.

LOG:
  --log <log>             Log file path.
  --log-level <log-level> Log level. (values: trace, debug, info, notice, warning, error, critical; default:
                          info) (default: info)
  --quiet                 Disable log.

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.
```

## API Documentation

Complete manual, usage guide, and examples are in the [Documentation](Documentation/) folder:

- [Manual](Documentation/Manual.md) — Full user manual: loading, modular operations, time conversions, logging, error handling, async/await, task groups, extensions, validation, version conversion, and step-by-step examples.
- [CLI](Sources/PipelineNeoCLI/README.md) — Experimental command-line interface: `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--create-project`, building and extending.

## FCPXML Version Support

Pipeline Neo supports FCPXML versions 1.5 through 1.14. All DTDs for these versions are included. You can validate a document against any version's schema (e.g. `document.validateFCPXMLAgainst(version: "1.14")`).
- Parsing: Any well-formed FCPXML document parses successfully; the full XML tree is available via the protocol-based XML layer (`PNXMLDocument`/`PNXMLElement` — Foundation-backed on macOS, AEXML-backed on iOS).
- Typed element types: Every element from the FCPXML DTDs (1.5–1.14) is represented in `FCPXMLElementType`, so you can identify and filter by any element (e.g. `locator`, `import-options`, `live-drawing`, `filter-video`, all `adjust-*`, smart-collection match rules, etc.). Structural types like multicam vs compound `media` are inferred from the first child.
- Typed attributes and helpers: The framework also provides typed properties and helpers for a subset of elements (e.g. `fcpxDuration`, `fcpxOffset`, event/project/clip APIs). Other elements are fully accessible via `element.name`, `element.attribute(forName:)`, and the shared `getElementAttribute` / `setElementAttribute` helpers.

## Modularity & Safety

- Protocol-oriented and dependency-injected: core behaviour (parsing, timecode, document ops, error handling) is behind protocols with default implementations you can replace. Inject when creating FCPXMLService or FCPXMLUtility or when using modular extension overloads.
- Extension APIs that can't take a parameter use a single shared instance (FCPXMLUtility.defaultForExtensions) for consistency and concurrency safety; use overloads with a `using:` parameter for custom pipelines.
- Built with Swift 6 and strict concurrency; Sendable where possible, no unsafe code. Dependencies ([SwiftTimecode](https://github.com/orchetect/swift-timecode) 3.0.0, [SwiftExtensions](https://github.com/orchetect/swift-extensions) 2.0.0+) are up to date.

## Architecture Overview

- Protocols define parsing, timecode conversion, document operations, error handling, MIME type detection, asset validation, silence detection, asset duration measurement, and parallel file I/O; each has a default implementation you can swap. FCPXMLService (and FCPXMLUtility) composes these and exposes sync and async APIs. ModularUtilities provides createPipeline, processFCPXML, validateDocument, convertTimecodes, and similar helpers.
- FCPXMLFileLoader handles .fcpxml and .fcpxmld (including bundle Info.fcpxml). FCPXMLValidator and FCPXMLDTDValidator handle structural and schema validation (full DTD on macOS; FCPXMLStructuralValidator on iOS when DTD is unavailable); DTDs for 1.5–1.14 are bundled.
- A cross-platform XML layer (`Sources/PipelineNeo/XML/`) provides protocol types (PNXMLNode, PNXMLElement, PNXMLDocument, PNXMLFactory) with Foundation and AEXML backends. Extensions on CMTime and the XML protocol types offer convenience APIs; use modular overloads with an explicit dependency to inject your own. Error types are explicit (FCPXMLError, FCPXMLLoadError, export and validation errors); you can inject a custom error handler.

See AGENT.md for a detailed breakdown for AI agents and contributors.

## Credits

Created by [Vigneswaran Rajkumar](https://bsky.app/profile/vigneswaranrajkumar.com)

Icon Design by [Bor Jen Goh](https://www.artstation.com/borjengoh)

## License

Licensed under the MIT license. See [LICENSE](https://github.com/TheAcharya/pipeline-neo/blob/main/LICENSE) for details.

## Reporting Bugs

For bug reports, feature requests and suggestions you can create a new [issue](https://github.com/TheAcharya/pipeline-neo/issues) to discuss.

## Contribution

Community contributions are welcome and appreciated. Developers are encouraged to fork the repository and submit pull requests to enhance functionality or introduce thoughtful improvements. However, a key requirement is that nothing should break—all existing features and behaviours and logic must remain fully functional and unchanged. Once reviewed and approved, updates will be merged into the main branch.

### AI Agent Development Collaboration

Pipeline Neo is developed using AI agents and we welcome developers who are interested in maintaining or contributing to the project using similar AI-assisted development approaches. If you're passionate about AI-driven development workflows and would like to collaborate on expanding Pipeline Neo's capabilities, we'd love to hear from you. 

Developers with experience in AI agent development and FCPXML processing are invited to get in touch. We can provide repository access and collaborate on advancing the framework's functionality.
