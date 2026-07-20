# OpenFCPXMLKit — Manual Index

Complete manual and usage guide for **OpenFCPXMLKit**, a Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration.

---

## Table of Contents

| Chapter | Title |
|--------|--------|
| [01 — Overview](01-Overview.md) | Introduction, architecture, entry points, protocols and implementations |
| [02 — Loading & Parsing](02-Loading-Parsing.md) | File loader, bundle support, parsing, FCPXML versions, element types |
| [03 — Timecode & Timing](03-Timecode-Timing.md) | SwiftTimecode, FCPXMLTimecode, CMTime, conversions, frame alignment |
| [04 — Service & Logging](04-Service-Logging.md) | FCPXMLService, ModularUtilities, createService, logging |
| [05 — Validation & Cut Detection](05-Validation-CutDetection.md) | Semantic and DTD validation, cut detection API |
| [06 — Version Conversion & Export](06-Version-Conversion-Export.md) | Version conversion, `VersionFeatureGate`, save as .fcpxml / .fcpxmld |
| [07 — Timeline & Export](07-Timeline-Export.md) | Timeline, TimelineClip, TimelineFormat, FCPXMLExporter, bundle export |
| [08 — Detached Authoring](08-Detached-Authoring.md) | `FinalCutPro.FCPXML.Authoring` value graph, omit-on-write, spine compounds |
| [09 — Timeline Manipulation](09-Timeline-Manipulation.md) | Ripple insert, auto lane assignment, clip queries, lane range |
| [10 — Timeline Metadata](10-Timeline-Metadata.md) | Markers, chapter markers, keywords, ratings, timestamps |
| [11 — Extraction & Media](11-Extraction-Media.md) | Extraction scope and presets, media extraction and copy |
| [12 — Timeline Projection](12-Timeline-Projection.md) | `TimelineProjector`, `MediaUsageWindow`, options, occupancy, report project-once |
| [13 — Media Processing](13-Media-Processing.md) | MIME type, asset validation, silence detection, duration, parallel I/O |
| [14 — Typed Models](14-Typed-Models.md) | Adjustments (incl. Corners/Panner), filters, captions/titles, keyframes, collections |
| [15 — XML Extensions](15-XML-Extensions.md) | OFKXMLDocument and OFKXMLElement FCPXML extensions (cross-platform) |
| [16 — High-Level Model](16-High-Level-Model.md) | FinalCutPro.FCPXML, Root, events, projects |
| [17 — Cross-Platform & iOS](17-Cross-Platform-iOS.md) | XML abstraction layer, OFKXML protocols, Foundation vs AEXML backends, iOS support |
| [18 — Errors & Utilities](18-Errors-Utilities.md) | Error types, ErrorHandling, ProgressBar, FCPXMLUID |
| [19 — CLI](19-CLI.md) | Experimental command-line interface (OpenFCPXMLKit-CLI) |
| [20 — Reporting, Excel & PDF Export](20-Reporting.md) | Report builder, ReportOptions, ReportTimecodeFormat, ReportBuildPhase, Non-Std Effects & Templates, Duplicate Frames / Total footers, Projection-first sections, Excel + PDF |
| [21 — Examples](21-Examples.md) | End-to-end workflows and code examples |

---

## Quick links

- **Documentation hub:** [../README.md](../README.md)
- **Project README:** [../../README.md](../../README.md)
- **Architecture:** [../../ARCHITECTURE.md](../../ARCHITECTURE.md) — layers and codebase map
- **Coverage:** [../Coverage.md](../Coverage.md) — FCPXML element / layer matrices (Model · Authoring · Extraction · Projection · Reporting)
- **Guardrails:** [../../GUARDRAILS.md](../../GUARDRAILS.md) — must / must-not for contributors and agents
- **CLI reference:** [../../Sources/OpenFCPXMLKitCLI/README.md](../../Sources/OpenFCPXMLKitCLI/README.md)
- **Tests:** [../../Tests/README.md](../../Tests/README.md) — suite layout (**1124** listed tests, all Swift Testing); [Submitted FCPXML](../../Tests/Submitted%20FCPXML/README.md) for private local investigation (never commit private FCPXML)
- **FCPXML reference:** [fcp.cafe/developers/fcpxml](https://fcp.cafe/developers/fcpxml)

