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
| [03 — Timecode & Timing](Manual/03-Timecode-Timing.md) | SwiftTimecode, FCPXMLTimecode, CMTime, conversions, frame alignment |
| [04 — Service & Logging](Manual/04-Service-Logging.md) | FCPXMLService, ModularUtilities, logging |
| [05 — Validation & Cut Detection](Manual/05-Validation-CutDetection.md) | Semantic and DTD validation, cut detection API |
| [06 — Version Conversion & Export](Manual/06-Version-Conversion-Export.md) | Version conversion, save as .fcpxml / .fcpxmld |
| [07 — Timeline & Export](Manual/07-Timeline-Export.md) | Timeline, TimelineClip, TimelineFormat, custom/preset dimensions and frame rate, zero-clip export, FCPXMLExporter options |
| [08 — Timeline Manipulation](Manual/08-Timeline-Manipulation.md) | Ripple insert, auto lane, clip queries, lane range |
| [09 — Timeline Metadata](Manual/09-Timeline-Metadata.md) | Markers, chapter markers, keywords, ratings, timestamps |
| [10 — Extraction & Media](Manual/10-Extraction-Media.md) | Extraction scope and presets, media extraction and copy |
| [11 — Media Processing](Manual/11-Media-Processing.md) | MIME type, asset validation, silence detection, duration, parallel I/O |
| [12 — Typed Models](Manual/12-Typed-Models.md) | Adjustments, filters, captions/titles, keyframe animation, Live Drawing, collections |
| [13 — XML Extensions](Manual/13-XML-Extensions.md) | OFKXMLDocument and OFKXMLElement FCPXML extensions (cross-platform) |
| [14 — High-Level Model](Manual/14-High-Level-Model.md) | FinalCutPro.FCPXML, Root, events, projects |
| [18 — Cross-Platform & iOS](Manual/18-Cross-Platform-iOS.md) | XML abstraction layer, Foundation vs AEXML, iOS support |
| [15 — Errors & Utilities](Manual/15-Errors-Utilities.md) | Error types, ErrorHandling, ProgressBar, FCPXMLUID |
| [16 — CLI](Manual/16-CLI.md) | Experimental command-line interface (OpenFCPXMLKit-CLI) |
| [17 — Examples](Manual/17-Examples.md) | End-to-end workflows and code examples |
| [19 — Reporting & Excel Export](Manual/19-Reporting.md) | Report builder, ReportOptions, ReportTimecodeFormat, ReportBuildPhase progress order, report sections, column/disabled-clip exclusion, RoleDisplayPreference, XLKit workbook export and cell formatting |

The manual covers the **entire public API** with examples: core operations, async/await, file I/O, validation, timeline creation and manipulation, metadata, media processing, typed models (including Live Drawing, HiddenClipMarker, SmartCollection match rules, Format/Asset 1.13+), version conversion, reporting and Excel export, CLI, and utilities. **Chapter 18** describes the cross-platform XML abstraction (OFKXML protocols, Foundation vs AEXML backends) and **iOS 26+** support. **Chapter 19** covers the reporting subsystem (report builder, sections, role inventory columns, Summary and Media Summary sheets, timecode display formats, inventory-first progress phases, global column and disabled-clip exclusion, XLKit `.xlsx` export, and workbook cell formatting).

---

## Other references

- **[CLI](../Sources/OpenFCPXMLKitCLI/README.md)** — Full CLI usage, options, building, extending, and regenerating embedded DTDs (`Scripts/generate_embedded_dtds.sh` or `swift run GenerateEmbeddedDTDs`).
- **Project [README](../README.md)** — Installation, architecture, requirements.
