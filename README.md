<p align="center">
  <a href="https://github.com/TheAcharya/OpenFCPXMLKit"><img src="Assets/OpenFCPXMLKit_Icon.png" height="200">
  <h1 align="center">OpenFCPXMLKit (CLI & Library)</h1>
</p>

<p align="center"><a href="https://github.com/TheAcharya/OpenFCPXMLKit/blob/main/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat" alt="license"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg?style=flat" alt="platform"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/build.yml"><img src="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/build.yml/badge.svg" alt="build"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/codeql.yml"><img src="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/codeql.yml/badge.svg" alt="CodeQL Advanced"/></a>&nbsp;<img src="https://img.shields.io/badge/Swift-6.3-orange.svg?style=flat" alt="Swift"/>&nbsp;<img src="https://img.shields.io/badge/Xcode-26+-blue.svg?style=flat" alt="Xcode"/></p>

A modern Swift 6 framework for working with Final Cut Pro's FCPXML with full concurrency support, SwiftTimecode integration, and [XLKit](https://github.com/TheAcharya/XLKit) integration.

OpenFCPXMLKit provides a comprehensive API for parsing, creating, and manipulating FCPXML files with advanced timecode operations, async/await patterns, and robust error handling. Built with Swift 6.3 and targeting **macOS 26+** and **iOS 26+**, it offers type-safe operations, comprehensive test coverage (**960** tests listed in `swift test --list-tests`: **957** in `OpenFCPXMLKitTests`, plus **3** optional `ExcelReportTest` integration tests), and seamless integration with SwiftTimecode and XLKit for professional video editing workflows. A cross-platform XML abstraction layer (Foundation on macOS, AEXML on iOS) keeps the library usable on both platforms.

OpenFCPXMLKit is currently in an experimental stage. It covers most core FCPXML attributes and parameters and provides a solid foundation for parsing, creation, and manipulation, with room for future expansion and additional feature coverage.

This codebase is developed using AI agents.

> [!IMPORTANT]
> OpenFCPXMLKit is highly experimental and has not yet been extensively tested in production environments, real-world workflows, or application integration. Report generation, in particular, remains at a very early and experimental stage. This library serves as a modernised foundation for AI-assisted development and experimentation with FCPXML processing capabilities.

> [!CAUTION]
> The codebase's API is still evolving and may change without notice between versions. Please consult the documentation for API usage. Use with caution in any workflow you rely on.

> [!NOTE]
> This project is shared as is and is not under active or regular development.

## Table of Contents

- [Core Features](#core-features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
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
- [Utilised By](#utilised-by)
- [Credits](#credits)
- [License](#license)
- [Reporting Bugs](#reporting-bugs)
- [Contribution](#contribution)
  - [AI Agent Development](#ai-agent-development)
- [Legacy](#legacy)

## Core Features

- **FCPXML I/O**: Read, create, modify documents (.fcpxml/.fcpxmld bundles); load via `FCPXMLFileLoader` (sync/async); create FCPXML from scratch with events, projects, resources, and clips.
- **Parsing & Validation**: Parse and validate against bundled DTDs (1.5–1.14); structural/reference and DTD schema validation (full DTD on macOS; cross-platform structural validation on iOS via `FCPXMLStructuralValidator`); **960** tests (**957** in `OpenFCPXMLKitTests` + **3** optional Excel/PDF report integration tests) across 58 FCPXML sample files.
- **Timecode Operations**: SwiftTimecode integration (`CMTime`, `Timecode`, FCPXML time strings); `FCPXMLTimecode` custom type (arithmetic, frame alignment, conversion); all FCP frame rates (23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps).
- **Typed Models**: Resources, events, clips, projects, adjustments (Crop, Transform, Blend, Stabilization, Volume, Loudness, NoiseReduction, HumReduction, Equalization, MatchEqualization, Transform360, ColorConform, Stereo3D, VoiceIsolation), filters (VideoFilter, AudioFilter, VideoFilterMask with FilterParameter), transitions, multicam (Media.Multicam, Angle, MulticamSource, MCClip), captions/titles (Caption, Title with TextStyle/TextStyleDefinition), smart collections (SmartCollection with match-clip, match-media, match-ratings, match-text, match-usage, match-representation, match-markers, match-analysis-type), collections (CollectionFolder, KeywordCollection).
- **Timeline Operations**: Build `Timeline`; create valid projects with custom or preset dimensions and frame rate (via `TimelineFormat`); export to FCPXML/.fcpxmld (including zero-clip/empty timelines); optional event/project UIDs and library location (`FCPXMLUID`); ripple insert, auto lane assignment, clip queries (lane/time range/asset ID), lane range computation; metadata (markers, chapter markers, keywords, ratings, custom metadata, timestamps); secondary storylines; `TimelineFormat` presets and computed properties.
- **Media Operations**: Extract asset/locator URLs; copy with deduplication; MIME type detection (`UTType`/`AVFoundation`); asset validation (existence, lane compatibility); silence detection; duration measurement; parallel file I/O; still image asset support.
- **Analysis & Conversion**: Cut detection (edit points, transitions, gaps); typed element filtering (`FCPXMLElementType`); version conversion (strip elements, validate, save as .fcpxml/.fcpxmld); per-version DTD validation; element stripping based on target version DTDs.
- **Animation**: KeyframeAnimation, Keyframe with interpolation, FadeIn/FadeOut; integrated with FilterParameter; auxValue support (FCPXML 1.11+).
- **Extensions**: CMTime Codable (FCPXML time string encoding/decoding); CollectionFolder and KeywordCollection for organization; Live Drawing (FCPXML 1.11+); HiddenClipMarker (FCPXML 1.13+); Format/Asset 1.13+ (heroEye, heroEyeOverride, mediaReps).
- **Excel & PDF Reporting**: Build a `Report` once from an FCPXML/FCPXMLD via `FinalCutPro.FCPXML.buildReport(options:)`, then export to a multi-sheet `.xlsx` workbook (`ReportExcelExport`, XLKit-backed) and/or a multi-page `.pdf` (`ReportPDFExport`, CoreGraphics). Sheets/sections for Role Inventory (Selected Roles Inventory + per-role), Markers, Keywords, Titles & Generators, Transitions, Video & Audio Effects, Speed Change Effects, Summary (project metrics and role durations; Excel title in **B1**), and Media Summary (missing media paths); a 1-based **Row** column on all tabular sheets by default (`ensuringRowColumn` / `allowsInjectedRowColumn`; omit with `ReportColumn.row` / `--exclude-column Row`); configurable `ReportTimecodeFormat` (SMPTE frames with DF/NDF, Frames, Feet+Frames, HH:MM:SS; format-aware column headers); role exclusions, global column exclusion, disabled-clip filtering, project-name filtering; inventory-first `ReportBuildPhase` progress callbacks shared by API and CLI. PDF adds a cover page (black “About This PDF Export” + `info.circle`), dynamic table of contents with accent colour chips and content-tint washes keyed to each sheet’s colour index, remaining columns expanded to fill page width after exclusions, pagination, and shared row-colour rules with Excel.
- **CLI**: `OpenFCPXMLKit-CLI` with `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--create-project` (new empty FCPXML project with width/height/rate/version), `--report` (Excel report; `--report-full`, per-section flags, `--exclude-role`, `--exclude-column`, `--exclude-disabled-clips`, `--timecode-format`, `--label-copyright`, `--create-pdf`), logging options (see CLI README).
- **Architecture**: Protocol-oriented, dependency-injected; sync/async APIs; Swift 6 concurrency-safe design; comprehensive test suite with file-based and logic tests.

## Requirements

- **macOS 26.0+** or **iOS 26.0+** (CLI is macOS-only; library supports both)
- Xcode 26.0+
- Swift 6.3+ (strict concurrency compliant; protocols and public types are `Sendable` where appropriate; `@unchecked Sendable` only where required for Foundation/ObjC interop)

## Installation

### Swift Package Manager

Add OpenFCPXMLKit to your project in Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/TheAcharya/OpenFCPXMLKit`
3. Select the version you want to use
4. Click Add Package

Or add it to your `Package.swift`:

```swift
// swift-tools-version: 6.3
// Add OpenFCPXMLKit as a dependency and link it to your target.
import PackageDescription

let package = Package(
    name: "MyPackage",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/TheAcharya/OpenFCPXMLKit", from: "3.0.6")
    ],
    targets: [
        .target(
            name: "MyTarget",
            dependencies: ["OpenFCPXMLKit"]
        )
    ]
)
```

## Before CLI Usage

First, ensure your system is configured to allow the tool to run:

<details><summary>Privacy & Security Settings</summary>
<p>

Navigate to the `Privacy & Security` settings and set your preference to `App Store and identified developers`.

<p align="center"> <img src="https://github.com/TheAcharya/OpenFCPXMLKit/blob/main/Assets/macOS-privacy.png?raw=true"> </p>

</p>
</details>

### Pre-Compiled CLI Binary

Download the latest release of the CLI universal binary [here](https://github.com/TheAcharya/OpenFCPXMLKit/releases).

Extract the `OpenFCPXMLKit-CLI-portable-x.x.x.zip` file from the release.

### Using [Homebrew](https://brew.sh/)

```bash
$ brew install TheAcharya/homebrew-tap/OpenFCPXMLKit-CLI
```
```bash
$ brew uninstall --cask OpenFCPXMLKit-CLI
```

Upon completion, find the installed binary `OpenFCPXMLKit-CLI` located within `/usr/local/bin`. Since this is a standard directory part of the environment search path, it will allow running `OpenFCPXMLKit-CLI` from any directory like a standard command.

### Pre-Compiled CLI Binary (macOS Installer)

#### Install

Download the latest release of the CLI installer package [here](https://github.com/TheAcharya/OpenFCPXMLKit/releases).

Use the `OpenFCPXMLKit-CLI-<version>.pkg` installer to install the command-line binary into your system. Upon completion, find the installed binary `OpenFCPXMLKit-CLI` located within `/usr/local/bin`. Since this is a standard directory part of the environment search path, it will allow running `OpenFCPXMLKit-CLI` from any directory like a standard command.

<p align="center"> <img src="https://github.com/TheAcharya/OpenFCPXMLKit/blob/main/Assets/macOS-installer.png?raw=true"> </p>

#### Uninstall

To uninstall, run this terminal command. It will require your account password.

```bash
sudo rm /usr/local/bin/OpenFCPXMLKit-CLI
```

### Compiled From Source

```shell
VERSION=3.0.6 # replace this with the git tag of the version you need
git clone https://github.com/TheAcharya/OpenFCPXMLKit.git
cd OpenFCPXMLKit
git checkout "tags/$VERSION"
swift build -c release
```

Once the build has finished, the `OpenFCPXMLKit-CLI` executable will be located at `.build/release/`.

## CLI Usage

```plain
$ OpenFCPXMLKit-CLI --help

OVERVIEW: Experimental tool to read, validate and generate Excel/PDF reports from Final Cut Pro FCPXML/FCPXMLD.

https://github.com/TheAcharya/OpenFCPXMLKit

USAGE: [<options>] [<fcpxml-path>] [<output-dir>]

ARGUMENTS:
  <fcpxml-path>           Input FCPXML file / FCPXMLD bundle; or output directory when using --create-project.
  <output-dir>            Output directory (for --convert-version, --media-copy, etc.).

GENERAL:
  --check-version         Check and print FCPXML document version.
  --convert-version <version>
                          Convert FCPXML to the given version (e.g. 1.10, 1.14) and write to output-dir.
  --extension-type <extension-type>
                          Output format for --convert-version: fcpxmld (bundle) or fcpxml (single file). Default:
                          fcpxmld. For target versions 1.5–1.9, .fcpxml is used regardless. (values: fcpxml, fcpxmld;
                          default: fcpxmld)
  --validate              Perform robust check and validation of FCPXML/FCPXMLD (semantic + DTD).

TIMELINE:
  --create-project        Create a new empty FCPXML project (requires --width, --height, --rate, and <output-dir>
                          positional).
  --width <width>         Project width in pixels (used with --create-project).
  --height <height>       Project height in pixels (used with --create-project).
  --rate <rate>           Frame rate (e.g. 24, 25, 29.97) (used with --create-project).
  --project-version <project-version>
                          FCPXML version for the new project (e.g. 1.10, 1.14). Default: 1.14. (used with
                          --create-project).

EXTRACTION:
  --media-copy            Scan FCPXML/FCPXMLD and copy all referenced media files to output-dir.

REPORT:
  --report                Build an Excel report workbook from FCPXML (role inventory only; use --report-full for all
                          sheets).
  --report-full           Include every optional report sheet (with --report). Default --report exports role inventory
                          only.
  --report-markers        Include the Markers sheet (with --report).
  --report-keywords       Include the Keywords sheet (with --report).
  --report-titles-generators
                          Include the Titles & Generators sheet (with --report).
  --report-transitions    Include the Transitions sheet (with --report).
  --report-effects        Include the Video & Audio Effects sheet (with --report).
  --report-speed-change-effects
                          Include the Speed Change Effects sheet (with --report).
  --report-summary        Include the Summary sheet (project metrics and role-duration totals; with --report).
  --report-media-summary  Include the Media Summary sheet (missing media file paths; with --report).
  --create-pdf            Also write a PDF report alongside the Excel workbook (with --report). Includes the same
                          workbook sections, column exclusions, and timecode formatting when present.
  --report-project <report-project>
                          Timeline name filter: matches a <project> name or a standalone compound-clip / ref-clip name
                          when the document has more than one reportable timeline.
  --label-copyright <label-copyright>
                          Optional copyright / attribution line for Excel and PDF reports (with --report). Excel: cover
                          sheet cell A2 below the Created-by brand row. PDF: same subtitle style below Created-by on the
                          cover, and centred in the running footer (same footer font/size as the Created-by branding).
  --exclude-role <exclude-role>
                          Exclude a role or subrole from role inventory (repeatable). Excluding a main role also
                          excludes its subroles.
  --exclude-disabled-clips
                          Omit disabled clips (enabled="0") from all report sections (with --report).
  --exclude-column <exclude-column>
                          Exclude a report column from every applicable Excel/PDF sheet (repeatable; with --report).
                          Case-insensitive names include Row / Row Numbers (all tabular sheets + PDF Row injection),
                          Role Subrole, Clip Name, Frame Rate, Reel, Metadata (role inventory dynamic metadata keys),
                          and other shared column headers. Columns are removed wherever the sheet uses a matching
                          header.
  --timecode-format <timecode-format>
                          Timeline time display format for Excel and PDF report cells (with --report). Values:
                          HH:MM:SS:FF, Frames, Feet+Frames, HH:MM:SS. Default: HH:MM:SS:FF (SMPTE with frames;
                          semicolon before frames for drop-frame). (default: HH:MM:SS:FF)

LOG:
  --log <log>             Log file path.
  --log-level <log-level> Log level. (values: trace, debug, info, notice, warning, error, critical; default: info)
                          (default: info)
  --quiet                 Disable log.

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.
```

## API Documentation

Complete manual, usage guide, and examples are in the [Documentation](Documentation/) folder:

- [Manual](Documentation/Manual.md) — Full user manual: loading, modular operations, time conversions, logging, error handling, async/await, task groups, extensions, validation, version conversion, and step-by-step examples.
- [Reporting, Excel & PDF Export](Documentation/Manual/19-Reporting.md) — Build reports: `buildReport`, `ReportBuilder`, `ReportOptions`, `ReportTimecodeFormat`, `ReportBuildPhase` progress, `ReportColumn` exclusion (universal **Row** via `ensuringRowColumn`), disabled-clip filtering, Summary (Excel **B1** title) and Media Summary sheets, `ReportExcelExport`, `ReportPDFExport` (cover notes, TOC colour chips, column-width expansion after exclusions), and CLI integration (`--create-pdf`).
- [CLI](Sources/OpenFCPXMLKitCLI/README.md) — Experimental command-line interface: `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--create-project`, `--report` / `--timecode-format` / `--create-pdf`, building and extending.

## FCPXML Version Support

OpenFCPXMLKit supports FCPXML versions 1.5 through 1.14. All DTDs for these versions are included. You can validate a document against any version's schema (e.g. `document.validateFCPXMLAgainst(version: "1.14")`).
- Parsing: Any well-formed FCPXML document parses successfully; the full XML tree is available via the protocol-based XML layer (`OFKXMLDocument`/`OFKXMLElement` — Foundation-backed on macOS, AEXML-backed on iOS).
- Typed element types: Every element from the FCPXML DTDs (1.5–1.14) is represented in `FCPXMLElementType`, so you can identify and filter by any element (e.g. `locator`, `import-options`, `live-drawing`, `filter-video`, all `adjust-*`, smart-collection match rules, etc.). Structural types like multicam vs compound `media` are inferred from the first child.
- Typed attributes and helpers: The framework also provides typed properties and helpers for a subset of elements (e.g. `fcpxDuration`, `fcpxOffset`, event/project/clip APIs). Other elements are fully accessible via `element.name`, `element.attribute(forName:)`, and the shared `getElementAttribute` / `setElementAttribute` helpers.

## Modularity & Safety

- Protocol-oriented and dependency-injected: core behaviour (parsing, timecode, document ops, error handling) is behind protocols with default implementations you can replace. Inject when creating FCPXMLService or FCPXMLUtility or when using modular extension overloads.
- Extension APIs that can't take a parameter use a single shared instance (FCPXMLUtility.defaultForExtensions) for consistency and concurrency safety; use overloads with a `using:` parameter for custom services.
- Built with Swift 6 and strict concurrency; Sendable where possible, no unsafe code. Key dependencies: [SwiftTimecode](https://github.com/orchetect/swift-timecode), [SwiftExtensions](https://github.com/orchetect/swift-extensions), [swift-log](https://github.com/apple/swift-log), [AEXML](https://github.com/tadija/AEXML) (iOS XML backend), [XLKit](https://github.com/TheAcharya/XLKit) (Excel report export), CoreGraphics (PDF report export), and [swift-argument-parser](https://github.com/apple/swift-argument-parser) (CLI only). Minimum versions are defined in `Package.swift`.

## Architecture Overview

- Protocols define parsing, timecode conversion, document operations, error handling, MIME type detection, asset validation, silence detection, asset duration measurement, and parallel file I/O; each has a default implementation you can swap. FCPXMLService (and FCPXMLUtility) composes these and exposes sync and async APIs. ModularUtilities provides createService, processFCPXML, validateDocument, convertTimecodes, and similar helpers.
- FCPXMLFileLoader handles .fcpxml and .fcpxmld (including bundle Info.fcpxml). FCPXMLValidator and FCPXMLDTDValidator handle structural and schema validation (full DTD on macOS; FCPXMLStructuralValidator on iOS when DTD is unavailable); DTDs for 1.5–1.14 are bundled.
- A cross-platform XML layer (`Sources/OpenFCPXMLKit/XML/`) provides protocol types (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLFactory) with Foundation and AEXML backends. Extensions on CMTime and the XML protocol types offer convenience APIs; use modular overloads with an explicit dependency to inject your own. Error types are explicit (FCPXMLError, FCPXMLLoadError, export and validation errors); you can inject a custom error handler.
- The engine is layered bottom-up — `XML → Parsing → Model → Extraction → Reporting` — so the CLI, extraction presets, timeline tools, and reports share one foundation. The `Reporting/` layer (with `Reporting/Excel/` for XLKit workbook export and `Reporting/PDF/` for CoreGraphics PDF export) maps already-extracted facts into report rows and sheets/pages; it owns presentation only. See [ARCHITECTURE.md](ARCHITECTURE.md) for the full codebase map and layer boundaries.

See AGENT.md for a detailed breakdown for AI agents and contributors.

## Utilised By

### [Production Data](https://productiondata.theacharya.co)

<details><summary>Production Data's Main Window</summary>
<p>

<p align="center"> <img src="https://github.com/TheAcharya/ProductionData-Website/blob/main/docs/assets/pd-main.png?raw=true"> </p>

</p>
</details>

## Credits

Created by [Vigneswaran Rajkumar](https://bsky.app/profile/vigneswaranrajkumar.com)

Icon Design by [Bor Jen Goh](https://www.artstation.com/borjengoh)

## License

Licensed under the MIT license. See [LICENSE](https://github.com/TheAcharya/OpenFCPXMLKit/blob/main/LICENSE) for details.

## Reporting Bugs

For bug reports, feature requests and suggestions you can create a new [issue](https://github.com/TheAcharya/OpenFCPXMLKit/issues) to discuss.

## Contribution

Pull requests are accepted on a best effort basis. Contributions must not break existing functionality: all current features, behaviours and logic should remain fully functional and unchanged. Response times may be slow given the project's limited maintenance schedule.

### AI Agent Development

OpenFCPXMLKit is developed using AI agents as part of an ongoing exploration of AI-assisted development workflows. Contributions from developers interested in this approach are welcome via pull request.

## Legacy

This repository was formerly known as Pipeline Neo.