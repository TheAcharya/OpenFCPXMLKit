# OpenFCPXMLKit — Documentation

This folder contains the complete manual and reference for OpenFCPXMLKit.

---

## Manual (structured)

The manual is split into **chapters** for easier navigation and maintenance:

**[Manual Index (start here)](Manual/00-Index.md)** — Table of contents and links to all chapters.

| Chapter | Content |
|--------|---------|
| [01 — Overview](Manual/01-Overview.md) | Introduction, architecture, entry points, protocols and implementations |
| [02 — Loading & Parsing](Manual/02-Loading-Parsing.md) | File loader, bundle support, parsing, FCPXML versions, element types |
| [03 — Timecode & Timing](Manual/03-Timecode-Timing.md) | SwiftTimecode, FCPXMLTimecode, CMTime, conversions, frame alignment, Projection timing safety |
| [04 — Service & Logging](Manual/04-Service-Logging.md) | FCPXMLService, ModularUtilities, logging |
| [05 — Validation & Cut Detection](Manual/05-Validation-CutDetection.md) | Semantic and DTD validation, cut detection API |
| [06 — Version Conversion & Export](Manual/06-Version-Conversion-Export.md) | Version conversion, write honesty vs report reads, save as .fcpxml / .fcpxmld |
| [07 — Timeline & Export](Manual/07-Timeline-Export.md) | Timeline, TimelineClip, TimelineFormat, custom/preset dimensions and frame rate, zero-clip export, FCPXMLExporter options |
| [08 — Timeline Manipulation](Manual/08-Timeline-Manipulation.md) | Ripple insert, auto lane, clip queries, lane range |
| [09 — Timeline Metadata](Manual/09-Timeline-Metadata.md) | Markers, chapter markers, keywords, ratings, timestamps |
| [10 — Extraction & Media](Manual/10-Extraction-Media.md) | Extraction scope and presets, media extraction and copy |
| [11 — Timeline Projection](Manual/11-Timeline-Projection.md) | `TimelineProjector`, `MediaUsageWindow`, options, occupancy, report project-once |
| [12 — Media Processing](Manual/12-Media-Processing.md) | MIME type, asset validation, silence detection, duration, parallel I/O |
| [13 — Typed Models](Manual/13-Typed-Models.md) | Adjustments, filters, captions/titles, keyframe animation, Live Drawing, collections |
| [14 — XML Extensions](Manual/14-XML-Extensions.md) | OFKXMLDocument and OFKXMLElement FCPXML extensions (cross-platform) |
| [15 — High-Level Model](Manual/15-High-Level-Model.md) | FinalCutPro.FCPXML, Root, events, projects |
| [16 — Cross-Platform & iOS](Manual/16-Cross-Platform-iOS.md) | XML abstraction layer, Foundation vs AEXML, iOS support |
| [17 — Errors & Utilities](Manual/17-Errors-Utilities.md) | Error types, ErrorHandling, ProgressBar, FCPXMLUID |
| [18 — CLI](Manual/18-CLI.md) | Experimental command-line interface (OpenFCPXMLKit-CLI) |
| [19 — Reporting, Excel & PDF Export](Manual/19-Reporting.md) | Report builder, ReportOptions (`copyrightLabel`, `includeMarkersOutsideClipBoundaries`, `protectSheets`, …), Projection-first sections, Excel/PDF export |
| [20 — Examples](Manual/20-Examples.md) | End-to-end workflows and code examples |

The manual covers the **entire public API** with examples: core operations, async/await, file I/O, validation, timeline creation and manipulation, metadata, media processing, typed models, version conversion, **Timeline Projection**, reporting and Excel/PDF export, CLI, and utilities.

- **Chapter 11** — Projection (`MediaUsageWindow`, project-once for reports)
- **Chapter 16** — Cross-platform XML abstraction (OFKXML)
- **Chapter 19** — Reporting (Excel & PDF)

Architecture philosophy: [ARCHITECTURE.md](../ARCHITECTURE.md) §2.7. Hard constraints: [GUARDRAILS.md](../GUARDRAILS.md).

**Test count (keep in sync):** **1084** listed in `swift test list` — **1078** in `OpenFCPXMLKitTests` + **6** optional `ExcelReportTest` (all Swift Testing `@Test`); **60** sample `.fcpxml` files. Private user exports for local investigation: [Tests/Submitted FCPXML](../Tests/Submitted%20FCPXML/README.md) (gitignored; never commit to GitHub).

---

## Other references

- **[CLI](../Sources/OpenFCPXMLKitCLI/README.md)** — Full CLI usage, options, building, extending, and regenerating embedded DTDs (`Scripts/generate_embedded_dtds.sh` or `swift run GenerateEmbeddedDTDs`).
- **Project [README](../README.md)** — Installation, architecture, requirements.
- **[Tests/README.md](../Tests/README.md)** — Test suite layout and categories (including Submitted FCPXML).
- **[Submitted FCPXML](../Tests/Submitted%20FCPXML/README.md)** — Private inbox workflow for parsing / reporting edge cases (local only).
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** — Layer stack, Projection, reporting.
- **[GUARDRAILS.md](../GUARDRAILS.md)** — Must / must-not constraints (layers, naming, tests, reporting honesty).

