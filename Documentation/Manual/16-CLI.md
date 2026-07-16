# 16 — CLI

[← Manual Index](00-Index.md)

---

## Overview

The package includes an experimental command-line tool **OpenFCPXMLKit-CLI**. It is a **single binary**: FCPXML DTDs (1.5–1.14) are embedded, so you can copy the executable and run it without a resource bundle.

- **Build:** `swift build` (or OpenFCPXMLKitCLI scheme in Xcode)
- **Run:** `swift run OpenFCPXMLKit-CLI --help`

---

## Commands and options

Use **one** of: `--check-version`, `--convert-version`, `--validate`, `--media-copy`, `--report`, or `--create-project`. For `--convert-version`, `--media-copy`, `--report` (and default process), `<output-dir>` is required and is **created if missing**. For `--create-project`, the single positional argument is `<output-dir>` (also created if missing). `--extension-type` requires `--convert-version`. REPORT modifiers (`--report-full`, section flags, `--timecode-format`, `--media-resolution`, etc.) require `--report`.

### GENERAL

| Option | Description |
|--------|-------------|
| **--check-version** | Load FCPXML at path and print document version. No output-dir required. |
| **--convert-version &lt;VERSION&gt;** | Load, convert to target version (1.5–1.14) with element stripping and DTD validation, save to output-dir. Output format: **--extension-type** (default .fcpxmld for 1.10+; 1.5–1.9 always .fcpxml). |
| **--extension-type &lt;fcpxml\|fcpxmld&gt;** | Output format for convert only (requires `--convert-version`): `fcpxmld` (bundle, default when omitted) or `fcpxml` (single file). |
| **--validate** | Robust validation: semantic + DTD against declared version. Progress indicator unless `--quiet`. No output-dir required. |
| **--media-copy** | Extract media refs and copy files to output-dir. Progress bar unless `--quiet`. Paths to stdout; summary to stderr. |

### REPORT

Build an Excel (`.xlsx`) report workbook from FCPXML/FCPXMLD, with optional PDF (`.pdf`) export via `--create-pdf`. Works for normal project timelines and for standalone compound-clip exports (event `ref-clip` with no `<project>`). The workbook is written to `<output-dir>`; its file name is derived from the project or compound-clip name. See [19 — Reporting, Excel & PDF Export](19-Reporting.md) for the underlying API.

| Option | Description |
|--------|-------------|
| **--report** | Build a report workbook. Alone, exports the **role inventory only** (Selected Roles Inventory + per-role sheets). |
| **--report-full** | Include **every** optional sheet (with `--report`). |
| **--report-markers** | Include the Markers sheet (with `--report`). |
| **--report-keywords** | Include the Keywords sheet (with `--report`). |
| **--report-titles-generators** | Include the Titles & Generators sheet (with `--report`). |
| **--report-transitions** | Include the Transitions sheet (with `--report`). |
| **--report-effects** | Include the Video & Audio Effects sheet (with `--report`). |
| **--report-speed-change-effects** | Include the Speed Change Effects sheet (with `--report`). |
| **--report-summary** | Include the Summary sheet (project metrics and role-duration totals; with `--report`). |
| **--report-media-summary** | Include the Media Summary sheet (missing media file paths; with `--report`). |
| **--media-resolution &lt;mode&gt;** | Projection failure policy (`fail-soft` default, `fail-loud`; with `--report`). Missing files on disk still appear on Media Summary. |
| **--media-summary-distinguish-proxy** | Separate Missing Original / Missing Proxy columns on Media Summary (with `--report`). |
| **--create-pdf** | Also write a PDF report alongside the Excel workbook (with `--report`). Uses the same built `Report` — sections, column exclusions, timecode format, role/disabled-clip filtering. PDF adds cover/TOC (sheet colour chips), per-sheet tints, and column-width expansion after exclusions. Writes `{project-or-clip-name}.pdf` to output-dir; prints the PDF path after the `.xlsx` path. |
| **--report-project &lt;name&gt;** | Timeline name filter: matches a `<project>` name or a standalone compound-clip / `ref-clip` name when the document has more than one reportable timeline. |
| **--label-copyright &lt;text&gt;** | Optional copyright / attribution line (with `--report`). Excel cover sheet **A2** below Created-by; PDF cover below Created-by (same subtitle font/size); PDF running footer centre (same footer font/size). |
| **--exclude-role &lt;role&gt;** | Exclude a role or subrole from the role inventory (repeatable). Excluding a main role also excludes its subroles. |
| **--exclude-disabled-clips** | Omit disabled clips (`enabled="0"`) from all timeline-based report sections (with `--report`). |
| **--exclude-column &lt;column&gt;** | Exclude a workbook column from every applicable report sheet (repeatable; with `--report`). |
| **--timecode-format &lt;format&gt;** | Timeline time display format for report cells in Excel and PDF (with `--report`). Values: `HH:MM:SS:FF` (default; SMPTE with frames, `;` before frames for drop-frame), `Frames`, `Feet+Frames`, `HH:MM:SS`. |

When `--report` is used without `--report-full` or section flags, the CLI exports role inventory only. Use `--report-full` for every optional sheet, or set individual `--report-*` section flags for a partial export (role inventory is always included). `--report-full` takes precedence when combined with section flags.

Build progress follows **product / workbook order** (Selected Roles Inventory first, then Markers … Media Summary). See [19 — Reporting](19-Reporting.md#progress-callbacks).

All REPORT flags except `--report` itself require `--report`.

#### Role exclusion matching

`--exclude-role` matches on the **whole role name**, and matching is **case- and diacritic-insensitive**:

- **Single word, no quotes needed:** `--exclude-role Music` and `--exclude-role music` are equivalent.
- **Whole-name match (not substring):** `--exclude-role Music` matches the role `Music`, but not `Background Music`.
- **Main role includes its subroles:** `--exclude-role Music` also removes `Music ▸ Score`, `Music ▸ Underscore`, etc.
- **Subroles use the ` ▸ ` format:** to exclude a single subrole, pass the full path in quotes, e.g. `--exclude-role "Music ▸ Score"` (the separator is `▸`, U+25B8, with a space on each side).
- **Quote names with spaces or `▸`:** e.g. `--exclude-role "Sound Effects"` or `--exclude-role "SRT ▸ de-DE"`.
- **Repeatable:** pass the flag multiple times to exclude several roles.
- Leading/trailing whitespace is trimmed.

```bash
OpenFCPXMLKit-CLI --report --exclude-role Music --exclude-role Dialogue --exclude-role "SRT ▸ de-DE" /path/to/project.fcpxmld /path/to/output-dir
```

#### Disabled clip exclusion

`--exclude-disabled-clips` is a **boolean flag** (no value). Add it to any `--report` command to omit clips with `enabled="0"` from role inventory, markers, keywords, titles, transitions, effects, speed-change effects, and summary role durations.

Omit the flag to keep disabled clips in the workbook (they typically appear with **Enabled** shown as `✗`).

```bash
OpenFCPXMLKit-CLI --report --report-full --exclude-disabled-clips /path/to/project.fcpxmld /path/to/output-dir
```

#### Column exclusion matching

`--exclude-column` removes a logical column from **every applicable sheet** where a matching header exists. Matching is **case- and diacritic-insensitive**. Pass the flag once per column.

Common values:

| CLI value | Effect |
|-----------|--------|
| `Row` / `Row Numbers` | Removes the Row index column from **every** Excel and PDF tabular sheet, including PDF multi-page Row injection |
| `Role Subrole` | Removes Role ▸ Subrole |
| `Reel`, `Scene`, `Take` | Removes the named fixed column |
| `Metadata` | Removes all dynamic metadata key columns on role inventory sheets |
| `Source File Path` | Removes Source File Path (and Missing Media on Media Summary) |
| `Frame Rate` | Removes Frame Rate/Sample Rate (and related summary metric cells) |

Unknown column names are ignored. See [19 — Reporting, Excel & PDF Export](19-Reporting.md#column-exclusion) for the full **ReportColumn** list and aliases.

```bash
OpenFCPXMLKit-CLI --report \
  --exclude-column Reel \
  --exclude-column Notes \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir
```

#### Timecode display format

`--timecode-format` controls how timeline and source time columns are written in Excel and PDF exports (and appends a header suffix when not using default SMPTE frames). See [19 — Reporting, Excel & PDF Export](19-Reporting.md#timecode-display-format).

| Value | Cells | Example headers |
|-------|-------|-----------------|
| `HH:MM:SS:FF` (default) | SMPTE with frames (`:` NDF / `;` DF) | `Timeline In`, `Position` |
| `Frames` | Integer frame count | `Timeline In (frames)` |
| `Feet+Frames` | Film-style feet+frames | `Timeline In (feet+frames)` |
| `HH:MM:SS` | Hours:minutes:seconds only | `Timeline In (HH:MM:SS)` |

```bash
OpenFCPXMLKit-CLI --report --report-full \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir
```

### TIMELINE

| Option | Description |
|--------|-------------|
| **--create-project** | Create a new empty FCPXML project. Requires **--width**, **--height**, **--rate**, and one positional argument (output directory). Project name is derived from dimensions and rate (e.g. `1920x1080@25p.fcpxml`). Output is validated against the DTD before writing. |
| **--width &lt;n&gt;** | Project width in pixels (used with `--create-project`). |
| **--height &lt;n&gt;** | Project height in pixels (used with `--create-project`). |
| **--rate &lt;fps&gt;** | Frame rate, e.g. 24, 25, 29.97 (used with `--create-project`). |
| **--project-version &lt;ver&gt;** | FCPXML version for the new project (e.g. 1.10, 1.14). Default: 1.14 (used with `--create-project`). |

### LOG

| Option | Description |
|--------|-------------|
| **--log &lt;path&gt;** | Append log to file. When set, CLI commands write user-visible messages to the log. Also console unless `--quiet`. |
| **--log-level &lt;level&gt;** | Minimum level: trace, debug, info, notice, warning, error, critical. Default: info. |
| **--quiet** | No log output. |

---

## Examples

```bash
OpenFCPXMLKit-CLI --check-version /path/to/project.fcpxml
OpenFCPXMLKit-CLI --validate /path/to/project.fcpxmld
OpenFCPXMLKit-CLI --convert-version 1.10 /path/to/project.fcpxml /path/to/output-dir
OpenFCPXMLKit-CLI --convert-version 1.14 --extension-type fcpxmld /path/to/project.fcpxmld /path/to/output-dir
OpenFCPXMLKit-CLI --media-copy /path/to/project.fcpxmld /path/to/media-folder

# Build report workbooks (.xlsx written to output-dir)
OpenFCPXMLKit-CLI --report /path/to/project.fcpxmld /path/to/output-dir
OpenFCPXMLKit-CLI --report --report-full /path/to/project.fcpxmld /path/to/output-dir
OpenFCPXMLKit-CLI --report --report-markers --report-summary --report-media-summary /path/to/project.fcpxmld /path/to/output-dir

# Filter roles, disabled clips, and columns
OpenFCPXMLKit-CLI --report --report-full \
  --exclude-role Effects \
  --exclude-disabled-clips \
  --exclude-column Reel \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir

# Frame-count timecode columns
OpenFCPXMLKit-CLI --report --report-full \
  --timecode-format Frames \
  /path/to/project.fcpxmld /path/to/output-dir

# Excel workbook plus PDF (same report configuration)
OpenFCPXMLKit-CLI --report --report-full --create-pdf \
  --exclude-column Metadata \
  /path/to/project.fcpxmld /path/to/output-dir

# Create a new empty project (e.g. 1920×1080 at 25 fps), write to output-dir; project file name is 1920x1080@25p.fcpxml
OpenFCPXMLKit-CLI --create-project --width 1920 --height 1080 --rate 25 /path/to/output-dir
OpenFCPXMLKit-CLI --create-project --width 640 --height 480 --rate 29.97 --project-version 1.13 /path/to/output-dir

OpenFCPXMLKit-CLI --log /tmp/openfcpxmlkit.log --log-level debug --check-version /path/to/project.fcpxml
```

---

## Full CLI reference

For source layout, extending the CLI, and regenerating embedded DTDs, see **[OpenFCPXMLKitCLI/README.md](../../Sources/OpenFCPXMLKitCLI/README.md)**.

---

## Next

- [17 — Examples](17-Examples.md) — End-to-end workflows and code examples.
- [19 — Reporting, Excel & PDF Export](19-Reporting.md) — the reporting API behind `--report`.

[← Manual Index](00-Index.md)
