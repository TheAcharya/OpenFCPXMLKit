# OpenFCPXMLKit CLI

Command-line interface for the OpenFCPXMLKit library. Use it to inspect and process Final Cut Pro FCPXML files and `.fcpxmld` bundles.

---

## Overview

- **Executable name:** `OpenFCPXMLKit-CLI`
- **Entry point:** `OpenFCPXMLKitCLI.swift` (root command; no subcommands)
- **Arguments:** `<fcpxml-path>` (required when not using `--create-project`), `<output-dir>` (optional for `--check-version` and `--validate`; required for `--convert-version`, `--media-copy`, and default process; when using `--create-project`, the single positional argument is the output directory).
- **Options:** Grouped under **GENERAL**, **TIMELINE**, **EXTRACTION**, **REPORT**, **LOG**, and standard **OPTIONS** (`--version`, `--help`)

---

## Usage

```bash
# Show help
OpenFCPXMLKit-CLI --help
OpenFCPXMLKit-CLI -h

# Show version
OpenFCPXMLKit-CLI --version

# Check and print FCPXML document version (output-dir not required)
OpenFCPXMLKit-CLI --check-version /path/to/project.fcpxml
OpenFCPXMLKit-CLI --check-version /path/to/project.fcpxmld

# Perform robust validation: semantic + DTD (progress indicator when not --quiet; output-dir not required)
OpenFCPXMLKit-CLI --validate /path/to/project.fcpxml
OpenFCPXMLKit-CLI --validate /path/to/project.fcpxmld

# Convert FCPXML to a target version (writes to output-dir)
# Default output: .fcpxmld bundle (1.10+); use --extension-type fcpxml for single file. Versions 1.5–1.9 always output .fcpxml.
OpenFCPXMLKit-CLI --convert-version 1.10 /path/to/project.fcpxml /path/to/output-dir
OpenFCPXMLKit-CLI --convert-version 1.14 --extension-type fcpxmld /path/to/project.fcpxmld /path/to/output-dir
OpenFCPXMLKit-CLI --convert-version 1.14 --extension-type fcpxml /path/to/project.fcpxml /path/to/output-dir

# Extract all media referenced in FCPXML/FCPXMLD to output-dir (progress bar when not --quiet; copied paths to stdout; summary to stderr)
OpenFCPXMLKit-CLI --media-copy /path/to/project.fcpxml /path/to/output-dir
OpenFCPXMLKit-CLI --media-copy /path/to/project.fcpxmld /path/to/output-dir

# Role inventory only (default --report)
OpenFCPXMLKit-CLI --report /path/to/project.fcpxmld /path/to/output-dir

# Full workbook: role inventory plus every optional report sheet
OpenFCPXMLKit-CLI --report --report-full /path/to/project.fcpxmld /path/to/output-dir

# Partial report: role inventory plus selected optional sheets only
OpenFCPXMLKit-CLI --report --report-markers --report-summary --report-media-summary /path/to/project.fcpxmld /path/to/output-dir

# Exclude roles from role inventory (repeatable; case-insensitive)
OpenFCPXMLKit-CLI --report --exclude-role Dialogue --exclude-role "SRT ▸ de-DE" /path/to/project.fcpxmld /path/to/output-dir

# Omit disabled clips (enabled="0") from all timeline-based report sections
OpenFCPXMLKit-CLI --report --report-full --exclude-disabled-clips /path/to/project.fcpxmld /path/to/output-dir

# Exclude columns globally from every applicable sheet (repeatable)
OpenFCPXMLKit-CLI --report \
  --exclude-column Reel \
  --exclude-column Metadata \
  --exclude-column "Source File Path" \
  /path/to/project.fcpxmld /path/to/output-dir

# Timeline timecode display format (default HH:MM:SS:FF; also Frames, Feet+Frames, HH:MM:SS)
OpenFCPXMLKit-CLI --report --report-full \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir

# Create a new empty FCPXML project (requires --width, --height, --rate; optional --project-version; output-dir as single positional)
# Project file name is derived from dimensions and rate (e.g. 1920x1080@25p.fcpxml). Output is DTD-validated before writing.
OpenFCPXMLKit-CLI --create-project --width 1920 --height 1080 --rate 25 /path/to/output-dir
OpenFCPXMLKit-CLI --create-project --width 640 --height 480 --rate 29.97 --project-version 1.13 /path/to/output-dir

# Process: input + output (output-dir required)
OpenFCPXMLKit-CLI /path/to/project.fcpxml /path/to/output-dir

# Logging: write to file and console (default level: info)
OpenFCPXMLKit-CLI --log /tmp/openfcpxmlkit.log --check-version /path/to/project.fcpxml
OpenFCPXMLKit-CLI --log-level debug --convert-version 1.10 /path/to/project.fcpxml /path/to/out

# Quiet: no log output
OpenFCPXMLKit-CLI --quiet --media-copy /path/to/project.fcpxml /path/to/media
```

**Validation:** Use only one of `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--report`, or `--create-project`. When using `--convert-version`, `--media-copy`, or `--report`, or when running the default process, you must provide `<output-dir>`. When using `--create-project`, you must provide `--width`, `--height`, `--rate`, and the output directory as the single positional argument. `--report-full`, REPORT section flags, `--exclude-role`, `--exclude-disabled-clips`, `--exclude-column`, and `--timecode-format` require `--report`. If `--log` is set and the file exists, it must be writable. Invalid `--log-level`, `--project-version` (for create-project), or `--timecode-format` values produce an error.

---

## GENERAL options (convert-version)

| Option | Description |
|--------|-------------|
| `--extension-type <fcpxml\|fcpxmld>` | Output format for `--convert-version`: `fcpxmld` (bundle, default) or `fcpxml` (single file). For target versions 1.5–1.9, `.fcpxml` is always used (bundles not supported). |

---

## REPORT options

| Option | Description |
|--------|-------------|
| `--report` | Build an Excel report workbook from FCPXML/FCPXMLD. Default: role inventory only (Selected Roles Inventory and per-role sheets). Writes `{project-name}.xlsx` to output-dir; prints the output path to stdout. |
| `--report-full` | Include every optional report sheet (requires `--report`). |
| `--report-markers` | Include the Markers sheet (requires `--report`). |
| `--report-keywords` | Include the Keywords sheet (requires `--report`). |
| `--report-titles-generators` | Include the Titles & Generators sheet (requires `--report`). |
| `--report-transitions` | Include the Transitions sheet (requires `--report`). |
| `--report-effects` | Include the Video & Audio Effects sheet (requires `--report`). |
| `--report-speed-change-effects` | Include the Speed Change Effects sheet (requires `--report`). |
| `--report-summary` | Include the Summary sheet (project metrics and role-duration totals; requires `--report`). |
| `--report-media-summary` | Include the Media Summary sheet (missing media file paths; requires `--report`). |
| `--report-project <name>` | Project name filter when the FCPXML contains multiple projects. |
| `--exclude-role <name>` | Exclude a role or subrole from role inventory (repeatable). Excluding a main role also excludes its subroles. Case-insensitive. |
| `--exclude-disabled-clips` | Omit disabled clips (`enabled="0"`) from all timeline-based report sections (requires `--report`). |
| `--exclude-column <column>` | Exclude a workbook column from every applicable report sheet (repeatable; requires `--report`). Case-insensitive; see [19 — Reporting](../../Documentation/Manual/19-Reporting.md#column-exclusion) for accepted names. |
| `--timecode-format <format>` | Timeline time display format for Excel report cells (requires `--report`). Values: `HH:MM:SS:FF` (default; SMPTE with frames; `;` before frames for drop-frame), `Frames`, `Feet+Frames`, `HH:MM:SS`. Non-default formats append a suffix to timecode column headers (e.g. `Timeline In (frames)`). See [19 — Reporting](../../Documentation/Manual/19-Reporting.md#timecode-display-format). |

When `--report` is used without `--report-full` or section flags, the CLI exports role inventory only. Use `--report-full` for every optional sheet, or set individual `--report-*` section flags for a partial export (role inventory is always included). `--report-full` takes precedence when combined with section flags.

Build progress follows **product / workbook order** (Selected Roles Inventory → Markers → Keywords → Titles & Generators → Transitions → Video & Audio Effects → Speed Change Effects → Summary → Media Summary). See [19 — Progress callbacks](../../Documentation/Manual/19-Reporting.md#progress-callbacks).

---

## LOG options

| Option | Description |
|--------|-------------|
| `--log <path>` | Append log output to this file. Also prints to the console unless `--quiet` is set. |
| `--log-level <level>` | Minimum log level: `trace`, `debug`, `info`, `notice`, `warning`, `error`, or `critical`. Default: `info`. |
| `--quiet` | Disable all log output (no file, no console). |

Log messages include parsing, version conversion, validation, save, and media extraction/copy. Use `--log-level debug` or `trace` for verbose output.

---

## Source layout

| Path | Purpose |
|------|--------|
| `OpenFCPXMLKitCLI.swift` | Root command: configuration, GENERAL, TIMELINE, EXTRACTION, REPORT, and LOG option groups, arguments, validation, and `run()` dispatch. |
| `Options/` | Option groups for help sections. `GeneralOptions` supplies **GENERAL** flags and `--extension-type`; `TimelineOptions` supplies **TIMELINE** options for `--create-project`; `ReportCLIOptions` supplies **REPORT** options; `LogOptions` supplies **LOG** options (`--log`, `--log-level`, `--quiet`). |
| `Commands/` | Feature modules. Each feature has its own subfolder and a `run(...)` entry point called from the root command (e.g. **CheckVersion** for `--check-version`). |
| `Commands/CheckVersion/` | Implements `--check-version`: loads FCPXML and prints the document version. |
| `Commands/ConvertVersion/` | Implements `--convert-version`: loads FCPXML, converts to target version (1.5–1.14), saves to output-dir as .fcpxmld (default) or .fcpxml per `--extension-type`; 1.5–1.9 always .fcpxml. |
| `Commands/Validate/` | Implements `--validate`: loads FCPXML/FCPXMLD and runs robust validation (semantic + DTD). |
| `Commands/ExtractMedia/` | Implements `--media-copy`: loads FCPXML/FCPXMLD and copies all referenced media files to output-dir. |
| `Commands/ExportReport/` | Implements `--report`: loads FCPXML/FCPXMLD, builds report sections, and writes an `.xlsx` workbook to output-dir. |
| `Commands/CreateProject/` | Implements `--create-project`: creates an empty FCPXML project with given width, height, frame rate, and version; runs DTD validation before writing; outputs FCP-style document (DOCTYPE, colorSpace, default smart collections). |
| `Options/TimelineOptions.swift` | **TIMELINE** option group: `--create-project`, `--width`, `--height`, `--rate`, `--project-version`. |
| `Generated/` | Generated source; `EmbeddedDTDs.swift` contains hardcoded DTD data (from `GenerateEmbeddedDTDs`). |

All Swift in `Sources/OpenFCPXMLKitCLI/` is a single module; no extra imports are needed between these files.

---

## Extending the CLI

**Add a new flag (e.g. under GENERAL):**

1. Add a property to `GeneralOptions` in `Options/GeneralOptions.swift` (e.g. `@Flag` or `@Option`).
2. In `OpenFCPXMLKitCLI.run()`, branch on that property and call the appropriate logic (existing module or inline).

**Add a new feature module (like CheckVersion):**

1. Create a folder under `Commands/`, e.g. `Commands/ExtractMedia/`.
2. Add a Swift file with a type (struct or enum) that exposes a static `run(...)` taking the needed parameters.
3. Add a flag or option (in `GeneralOptions` or a new option group) and, in `OpenFCPXMLKitCLI.run()`, call the new module when that option is set.

**Add subcommands later (optional):**

1. Define a `ParsableCommand` type under `Commands/...`.
2. In `OpenFCPXMLKitCLI`, set `subcommands: [YourCommand.self, ...]` (and optionally `defaultSubcommand`) in `CommandConfiguration`.

---

## Building and running

- **Swift PM:** From the package root, `swift build --target OpenFCPXMLKitCLI`; run with `swift run OpenFCPXMLKit-CLI --help` or use the built binary in `.build/debug/` or `.build/release/`.
- **Xcode:** Open the package, choose the **OpenFCPXMLKitCLI** or **OpenFCPXMLKit-Package** scheme, then Run or use the Product executable.

**Distributing the CLI:** The CLI is a **single binary**: the FCPXML DTDs (1.5–1.14) are hardcoded into the executable. Copy only **`OpenFCPXMLKit-CLI`** to any directory on the Mac or external storage; no resource bundle is required. The binary is produced in `.build/<arch>-apple-macosx/debug/` (or `release/`).

**Scripts:** Invoke the CLI directly (e.g. `"$TOOL_PATH" "$FCPXML_PATH" --validate`). Use a path to the binary with no trailing slash.

**Regenerating embedded DTDs:** If the FCPXML DTDs in `Sources/OpenFCPXMLKit/FCPXML DTDs/` change, run `./Scripts/generate_embedded_dtds.sh` or `swift run GenerateEmbeddedDTDs` from the package root to regenerate `Sources/OpenFCPXMLKitCLI/Generated/EmbeddedDTDs.swift`, then rebuild.
