# OpenFCPXMLKit — User Manual

Complete manual and usage guide for OpenFCPXMLKit, a Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration.

---

## Structured manual (chapters)

The manual is organized into **chapters** for easier navigation and full API coverage with examples.

**→ [Manual Index (start here)](Manual/00-Index.md)**

From the index you can reach all chapters:

- **01** — Overview (architecture, entry points, protocols)
- **02** — Loading & Parsing (file loader, versions, element types)
- **03** — Timecode & Timing (SwiftTimecode, FCPXMLTimecode, CMTime)
- **04** — Service & Logging (FCPXMLService, ModularUtilities)
- **05** — Validation & Cut Detection
- **06** — Version Conversion & Export (`VersionFeatureGate`)
- **07** — Timeline & Export
- **08** — Detached Authoring (`FinalCutPro.FCPXML.Authoring`)
- **09** — Timeline Manipulation (ripple insert, auto lane, clip queries)
- **10** — Timeline Metadata (markers, keywords, ratings, timestamps)
- **11** — Extraction & Media (scope, presets, media copy)
- **12** — Timeline Projection (`TimelineProjector`, `MediaUsageWindow`, report project-once)
- **13** — Media Processing (MIME, asset validation, silence, duration, parallel I/O)
- **14** — Typed Models (adjustments incl. Corners/Panner, filters, captions, keyframes, collections)
- **15** — XML Extensions (OFKXMLDocument, OFKXMLElement)
- **16** — High-Level Model (FinalCutPro.FCPXML)
- **17** — Cross-Platform & iOS (OFKXML abstraction, Foundation vs AEXML)
- **18** — Errors & Utilities
- **19** — CLI (OpenFCPXMLKit-CLI)
- **20** — Reporting, Excel & PDF Export (Projection-first sections, ReportTimecodeFormat, ReportBuildPhase, XLKit workbook, CoreGraphics PDF)
- **21** — Examples (workflows and code)

---

## Quick links

- **Documentation index:** [README.md](README.md)
- **CLI reference:** [../Sources/OpenFCPXMLKitCLI/README.md](../Sources/OpenFCPXMLKitCLI/README.md)
- **Project README:** [../README.md](../README.md)
- **Tests:** [../Tests/README.md](../Tests/README.md) — **1114** listed tests (all Swift Testing)
