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
| [06 — Version Conversion & Export](Manual/06-Version-Conversion-Export.md) | Version conversion, `VersionFeatureGate`, write honesty vs report reads, save as .fcpxml / .fcpxmld |
| [07 — Timeline & Export](Manual/07-Timeline-Export.md) | Timeline, TimelineClip, TimelineFormat, custom/preset dimensions and frame rate, zero-clip export, FCPXMLExporter options |
| [08 — Detached Authoring](Manual/08-Detached-Authoring.md) | `FinalCutPro.FCPXML.Authoring` value graph, omit-on-write, spine compounds / media resources |
| [09 — Timeline Manipulation](Manual/09-Timeline-Manipulation.md) | Ripple insert, auto lane, clip queries, lane range |
| [10 — Timeline Metadata](Manual/10-Timeline-Metadata.md) | Markers, chapter markers, keywords, ratings, timestamps |
| [11 — Extraction & Media](Manual/11-Extraction-Media.md) | Extraction scope and presets, media extraction and copy |
| [12 — Timeline Projection](Manual/12-Timeline-Projection.md) | `TimelineProjector`, `MediaUsageWindow`, options, occupancy, report project-once |
| [13 — Media Processing](Manual/13-Media-Processing.md) | MIME type, asset validation, silence detection, duration, parallel I/O |
| [14 — Typed Models](Manual/14-Typed-Models.md) | Adjustments (incl. Corners/Panner), filters, captions/titles, keyframe animation, Live Drawing, collections |
| [15 — XML Extensions](Manual/15-XML-Extensions.md) | OFKXMLDocument and OFKXMLElement FCPXML extensions (cross-platform) |
| [16 — High-Level Model](Manual/16-High-Level-Model.md) | FinalCutPro.FCPXML, Root, events, projects |
| [17 — Cross-Platform & iOS](Manual/17-Cross-Platform-iOS.md) | XML abstraction layer, Foundation vs AEXML, iOS support |
| [18 — Errors & Utilities](Manual/18-Errors-Utilities.md) | Error types, ErrorHandling, ProgressBar, FCPXMLUID |
| [19 — CLI](Manual/19-CLI.md) | Experimental command-line interface (OpenFCPXMLKit-CLI) |
| [20 — Reporting, Excel & PDF Export](Manual/20-Reporting.md) | Report builder, ReportOptions (`includeNonStandardEffectsTemplates`, `includeChapterMarkersInMarkersReport` default on, `copyrightLabel`, `includeMarkersOutsideClipBoundaries`, `protectSheets`, …), inventory Total / Duplicate Frames, Projection-first sections, Excel/PDF export |
| [21 — Examples](Manual/21-Examples.md) | End-to-end workflows and code examples |

The manual covers the **entire public API** with examples: core operations, async/await, file I/O, validation, timeline creation and manipulation, **detached Authoring**, metadata, media processing, typed models, version conversion, **Timeline Projection**, reporting and Excel/PDF export, CLI, and utilities.

- **Chapter 08** — Detached Authoring (`Authoring.Document`, omit-on-write)
- **Chapter 12** — Projection (`MediaUsageWindow`, project-once for reports)
- **Chapter 17** — Cross-platform XML abstraction (OFKXML)
- **Chapter 20** — Reporting (Excel & PDF)

Architecture philosophy: [ARCHITECTURE.md](../ARCHITECTURE.md) §2.7. Hard constraints: [GUARDRAILS.md](../GUARDRAILS.md). **Element / layer inventory:** [Coverage.md](Coverage.md) (Model · Authoring · Extraction · Projection · Reporting matrices).

**Test count (keep in sync):** **1144** listed in `swift test list` — **1137** in `OpenFCPXMLKitTests` + **7** optional `ExcelReportTest` (all Swift Testing `@Test`); **60** sample `.fcpxml` files. Private user exports for local investigation: [Tests/Submitted FCPXML](../Tests/Submitted%20FCPXML/README.md) (gitignored; never commit to GitHub).

---

## Other references

- **[Coverage](Coverage.md)** — Detailed FCPXML coverage matrices (typed Model, Authoring, Extraction, Projection, Reporting, version gates).
- **[CLI](../Sources/OpenFCPXMLKitCLI/README.md)** — Full CLI usage, options, building, extending, and regenerating embedded DTDs (`Scripts/generate_embedded_dtds.sh` or `swift run GenerateEmbeddedDTDs`).
- **Project [README](../README.md)** — Installation, architecture, requirements.
- **[Tests/README.md](../Tests/README.md)** — Test suite layout and categories (including Submitted FCPXML).
- **[Submitted FCPXML](../Tests/Submitted%20FCPXML/README.md)** — Private inbox workflow for parsing / reporting edge cases (local only).
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** — Layer stack, Authoring, Projection, reporting.
- **[GUARDRAILS.md](../GUARDRAILS.md)** — Must / must-not constraints (layers, naming, tests, reporting honesty).

