<p align="center">
  <a href="https://github.com/TheAcharya/OpenFCPXMLKit"><img src="Assets/OpenFCPXMLKit_Icon.png" height="200">
  <h1 align="center">OpenFCPXMLKit (CLI & Library)</h1>
</p>

<p align="center"><a href="https://github.com/TheAcharya/OpenFCPXMLKit/blob/main/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat" alt="license"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg?style=flat" alt="platform"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/build.yml"><img src="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/build.yml/badge.svg" alt="build"/></a>&nbsp;<a href="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/codeql.yml"><img src="https://github.com/TheAcharya/OpenFCPXMLKit/actions/workflows/codeql.yml/badge.svg" alt="CodeQL Advanced"/></a>&nbsp;<img src="https://img.shields.io/badge/Swift-6.3-orange.svg?style=flat" alt="Swift"/>&nbsp;<img src="https://img.shields.io/badge/Xcode-26+-blue.svg?style=flat" alt="Xcode"/></p>

A modern Swift 6 framework for working with Final Cut Pro's FCPXML with full concurrency support, SwiftTimecode integration, and [XLKit](https://github.com/TheAcharya/XLKit) integration.

OpenFCPXMLKit provides a type-safe API for parsing, creating, and manipulating FCPXML with async/await, SwiftTimecode, and Excel/PDF reporting. Targets **macOS 26+** and **iOS 26+** (Foundation XML on macOS; AEXML on iOS).

**Tests:** **1137** listed in `swift test list` — **1130** in `OpenFCPXMLKitTests` + **7** optional `ExcelReportTest` (all Swift Testing) — across **60** sample `.fcpxml` files. Private local investigation inbox: [`Tests/Submitted FCPXML/`](Tests/Submitted%20FCPXML/README.md) (gitignored; never commit private FCPXML).

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
  - [Documents & validation](#documents--validation)
  - [Timecode & timing](#timecode--timing)
  - [Typed models](#typed-models)
  - [Timeline](#timeline)
  - [Detached Authoring](#detached-authoring)
  - [Extraction & media](#extraction--media)
  - [Timeline Projection](#timeline-projection)
  - [Excel & PDF reporting](#excel--pdf-reporting)
  - [CLI](#cli)
  - [Architecture](#architecture)
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

### Documents & validation
- Read / create / modify `.fcpxml` and `.fcpxmld` bundles (`FCPXMLFileLoader`, sync & async)
- FCPXML **1.5–1.14** DTDs; semantic + DTD validation (full DTD on macOS; structural on iOS)
- Version convert with automatic element stripping for the target DTD
- Cut detection (edit points, transitions, gaps); typed element filtering (`FCPXMLElementType`)

### Timecode & timing
- SwiftTimecode: `CMTime`, `Timecode`, FCPXML time strings
- `FCPXMLTimecode` (arithmetic, frame alignment, conversion)
- Frame rates: 23.976, 24, 25, 29.97, 30, 50, 59.94, 60 fps

### Typed models
- Resources, events, clips, projects, transitions, multicam
- Adjustments (crop, corners, transform, volume, panner, EQ, 360, stereo 3D, …)
- Filters, captions/titles (`TextStyle`), smart collections, keyword folders
- Keyframe animation, Live Drawing (1.11+), HiddenClipMarker / heroEye / mediaReps (1.13+)

### Timeline
- Build and export `Timeline` / `TimelineFormat` (presets, empty projects)
- Ripple insert, auto lane, clip queries, secondary storylines
- Markers, keywords, ratings, custom metadata, timestamps

### Detached Authoring
- `FinalCutPro.FCPXML.Authoring` value graph (no live XML ownership)
- Encode/decode limited subset; omit-on-write via `VersionAvailability` / `VersionFeatureGate`
- Spine: asset-clip, gap, title, transition, video/audio, caption, sync/ref/mc-clip, audition
- Resources: format, asset, effect, media (compound + multicam)
- See [Manual 08 — Detached Authoring](Documentation/Manual/08-Detached-Authoring.md)

### Extraction & media
- Extraction presets (Captions, Markers, Roles, Titles, Effects, FrameData)
- Media extract / copy; MIME detection; asset validation; silence; duration; parallel I/O

### Timeline Projection
- Mid-layer between Extraction and Reporting: `TimelineProjector` → `MediaUsageWindow`
- Channels, lanes, `timeMap` / conform retiming, multicam / ref-clip / audition unfold
- `RetimingSegment` compose/clip; `TimelineOccupancyIndex` overlap; `.trackAnalysis` options preset
- Reports project **once** per timeline; Markers / Keywords / Titles / Transitions / Effects are Projection-first (Extraction fallback)
- See [Manual 12 — Timeline Projection](Documentation/Manual/12-Timeline-Projection.md)

### Excel & PDF reporting
- Build once with `buildReport(options:)`, then export `.xlsx` (XLKit) and/or `.pdf` (CoreGraphics)
- Sheets: Role Inventory, Markers, Keywords, Titles, Transitions, Non-Std Effects & Templates, Effects, Speed Change, Summary, Media Summary
  - Role inventory: **26** fixed columns (Duplicate Frames, Codecs, Ingest Date, Frame Size / Audio Config, …) + per-role **Total:** footers
- Filters: roles, columns (incl. **Row**), disabled clips, project name, timecode format, copyright label
- Markers: default omits out-of-bounds starts; `--include-markers-outside-clip-boundaries` adds them + **Hidden** column
- Excel: `--protect-sheets` / `protectSheets` applies worksheet edit locks (not encryption; PDF unaffected)
- CLI: `--report`, `--report-full`, `--report-non-standard-effects`, `--create-pdf`, `--media-resolution`, `--timecode-format`, `--protect-sheets`, …
- See [Manual 20 — Reporting](Documentation/Manual/20-Reporting.md)

### CLI
- `OpenFCPXMLKit-CLI`: check / convert / validate / media-copy / create-project / report
- Single portable binary with embedded DTDs — [CLI README](Sources/OpenFCPXMLKitCLI/README.md)

### Architecture
- Protocol-oriented + dependency injection; sync and async APIs
- Layer stack: `XML → Parsing → Model → Extraction → Projection → Reporting`
- Swift 6 strict concurrency; cross-platform OFKXML (Foundation / AEXML)
- See [ARCHITECTURE.md](ARCHITECTURE.md) and [GUARDRAILS.md](GUARDRAILS.md)

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
        .package(url: "https://github.com/TheAcharya/OpenFCPXMLKit", from: "3.2.3")
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
VERSION=3.2.3 # replace this with the git tag of the version you need
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
                          fcpxmld when converting. For target versions 1.5–1.9, .fcpxml is used regardless. (values:
                          fcpxml, fcpxmld)
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
  --report-non-standard-effects
                          Include the Non-Std Effects & Templates sheet (with --report).
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
                          Optional copyright / attribution line for Excel and PDF reports (with --report). Excel:
                          cover sheet cell A2 below the Created-by brand row. PDF: same subtitle style below
                          Created-by on the cover, and centred in the running footer (same footer font/size as the
                          Created-by branding).
  --exclude-role <exclude-role>
                          Exclude a role or subrole from role inventory (repeatable). Excluding a main role also
                          excludes its subroles.
  --exclude-disabled-clips
                          Omit disabled clips (enabled="0") from all report sections (with --report).
  --include-markers-outside-clip-boundaries
                          Include markers whose start is outside the host clip’s media range (hidden in FCP
                          timeline/Tags) and add a Hidden column (✓/✗) on the Markers sheet (with --report /
                          --report-markers). Default omits those markers and does not show Hidden.
  --protect-sheets        Protect every sheet in the Excel workbook against casual edits (with --report). Applies to
                          the cover sheet and all content sheets. This is an edit lock, not file-open encryption —
                          Excel can still open the file, and anyone can turn protection off. PDF export is unaffected
                          (use Preview’s Encrypt to password-protect a PDF).
  --exclude-column <exclude-column>
                          Exclude a report column from every applicable Excel/PDF sheet (repeatable; with --report).
                          Case-insensitive names include Row / Row Numbers (all tabular sheets + PDF Row injection),
                          Role Subrole, Clip Name, Frame Rate, Reel, Metadata (role inventory dynamic metadata keys),
                          and other shared column headers. Columns are removed wherever the sheet uses a matching
                          header.
  --timecode-format <timecode-format>
                          Timeline time display format for Excel and PDF report cells (with --report). Values:
                          HH:MM:SS:FF, Frames, Feet+Frames, HH:MM:SS. Default when omitted: HH:MM:SS:FF (SMPTE with
                          frames; semicolon before frames for drop-frame).
  --media-resolution <media-resolution>
                          How report building treats timeline projection failures (with --report). Values: fail-soft,
                          fail-loud. Default when omitted: fail-soft (continue with empty projection windows).
                          fail-loud aborts with an error. Missing files on disk still appear on Media Summary.
  --media-summary-distinguish-proxy
                          On Media Summary, emit separate Missing Original and Missing Proxy columns instead of a
                          single Missing Media column (with --report / --report-media-summary).

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

- **[Manual Index](Documentation/Manual/00-Index.md)** — Full chapter list and navigation (start here)
- **[Documentation hub](Documentation/README.md)** — Manual overview
- **[Coverage](Documentation/Coverage.md)** — Detailed FCPXML coverage matrices (typed Model, Authoring, Extraction, Projection, Reporting)
- **[CLI](Sources/OpenFCPXMLKitCLI/README.md)** — Flags, examples, building and extending
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Layer stack, codebase map, Mermaid diagrams
- **[GUARDRAILS.md](GUARDRAILS.md)** — Must / must-not constraints for contributors and agents
- **[Tests/README.md](Tests/README.md)** — Test suite layout (**1137** listed; all Swift Testing)
- **[AGENT.md](AGENT.md)** — AI agent / contributor briefing

## FCPXML Version Support

OpenFCPXMLKit supports FCPXML versions 1.5 through 1.14. All DTDs for these versions are included. You can validate a document against any version's schema (e.g. `document.validateFCPXMLAgainst(version: "1.14")`).
- Parsing: Any well-formed FCPXML document parses successfully; the full XML tree is available via the protocol-based XML layer (`OFKXMLDocument`/`OFKXMLElement` — Foundation-backed on macOS, AEXML-backed on iOS).
- Typed element types: Every element from the FCPXML DTDs (1.5–1.14) is represented in `FCPXMLElementType`, so you can identify and filter by any element (e.g. `locator`, `import-options`, `live-drawing`, `filter-video`, all `adjust-*`, smart-collection match rules, etc.). Structural types like multicam vs compound `media` are inferred from the first child.
- Typed attributes and helpers: The framework also provides typed properties and helpers for a subset of elements (e.g. `fcpxDuration`, `fcpxOffset`, event/project/clip APIs). Other elements are fully accessible via `element.name`, `element.attribute(forName:)`, and the shared `getElementAttribute` / `setElementAttribute` helpers.

## Modularity & Safety

- Protocol-oriented and dependency-injected: core behaviour (parsing, timecode, document ops, error handling) is behind protocols with default implementations you can replace. Inject when creating FCPXMLService or FCPXMLUtility or when using modular extension overloads.
- Extension APIs that can't take a parameter use a single shared instance (FCPXMLUtility.defaultForExtensions) for consistency and concurrency safety; use overloads with a `using:` parameter for custom services.
- Built with Swift 6 and strict concurrency; Sendable where possible, no unsafe code. Key dependencies: [SwiftTimecode](https://github.com/orchetect/swift-timecode), [SwiftExtensions](https://github.com/orchetect/swift-extensions) 3.0+, [SwiftSemanticVersion](https://github.com/orchetect/swift-semantic-version), [swift-log](https://github.com/apple/swift-log), [AEXML](https://github.com/tadija/AEXML) (iOS XML backend), [XLKit](https://github.com/TheAcharya/XLKit) (Excel report export), CoreGraphics (PDF report export), and [swift-argument-parser](https://github.com/apple/swift-argument-parser) (CLI only). Minimum versions are defined in `Package.swift`.

## Architecture Overview

- Protocols define parsing, timecode conversion, document operations, error handling, MIME type detection, asset validation, silence detection, asset duration measurement, and parallel file I/O; each has a default implementation you can swap. FCPXMLService (and FCPXMLUtility) composes these and exposes sync and async APIs. ModularUtilities provides createService, processFCPXML, validateDocument, convertTimecodes, and similar helpers.
- FCPXMLFileLoader handles .fcpxml and .fcpxmld (including bundle Info.fcpxml). FCPXMLValidator and FCPXMLDTDValidator handle structural and schema validation (full DTD on macOS; FCPXMLStructuralValidator on iOS when DTD is unavailable); DTDs for 1.5–1.14 are bundled.
- A cross-platform XML layer (`Sources/OpenFCPXMLKit/XML/`) provides protocol types (OFKXMLNode, OFKXMLElement, OFKXMLDocument, OFKXMLFactory) with Foundation and AEXML backends. Extensions on CMTime and the XML protocol types offer convenience APIs; use modular overloads with an explicit dependency to inject your own. Error types are explicit (FCPXMLError, FCPXMLLoadError, export and validation errors); you can inject a custom error handler.
- The engine is layered bottom-up — `XML → Parsing → Model → Extraction → Projection → Reporting` — so the CLI, extraction presets, timeline tools, and reports share one foundation. **Authoring** is a parallel detached create path (not in the Reporting stack). **Projection** emits playable `MediaUsageWindow`s; **Reporting** (Excel via XLKit, PDF via CoreGraphics) maps Projection + Extraction facts into sheets and owns presentation only. See [ARCHITECTURE.md](ARCHITECTURE.md) for the full codebase map and layer boundaries, and [GUARDRAILS.md](GUARDRAILS.md) for hard must / must-not constraints on those layers.

See [AGENT.md](AGENT.md) for a detailed breakdown for AI agents and contributors, and [GUARDRAILS.md](GUARDRAILS.md) for hard must / must-not constraints.

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
