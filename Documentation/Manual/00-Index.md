# Pipeline Neo — Manual Index

Complete manual and usage guide for **Pipeline Neo**, a Swift 6 framework for Final Cut Pro FCPXML processing with SwiftTimecode integration.

---

## Table of Contents

| Chapter | Title |
|--------|--------|
| [01 — Overview](01-Overview.md) | Introduction, architecture, entry points, protocols and implementations |
| [02 — Loading & Parsing](02-Loading-Parsing.md) | File loader, bundle support, parsing, FCPXML versions, element types |
| [03 — Timecode & Timing](03-Timecode-Timing.md) | SwiftTimecode, FCPXMLTimecode, CMTime, conversions, frame alignment |
| [04 — Pipeline & Logging](04-Pipeline-Logging.md) | FCPXMLService, ModularUtilities, createPipeline, logging |
| [05 — Validation & Cut Detection](05-Validation-CutDetection.md) | Semantic and DTD validation, cut detection API |
| [06 — Version Conversion & Export](06-Version-Conversion-Export.md) | Version conversion, save as .fcpxml / .fcpxmld, exporters |
| [07 — Timeline & Export](07-Timeline-Export.md) | Timeline, TimelineClip, TimelineFormat, FCPXMLExporter, bundle export |
| [08 — Timeline Manipulation](08-Timeline-Manipulation.md) | Ripple insert, auto lane assignment, clip queries, lane range |
| [09 — Timeline Metadata](09-Timeline-Metadata.md) | Markers, chapter markers, keywords, ratings, timestamps |
| [10 — Extraction & Media](10-Extraction-Media.md) | Extraction scope and presets, media extraction and copy |
| [11 — Media Processing](11-Media-Processing.md) | MIME type, asset validation, silence detection, duration, parallel I/O |
| [12 — Typed Models](12-Typed-Models.md) | Adjustments, filters, captions/titles, keyframe animation, Live Drawing, collections |
| [13 — XML Extensions](13-XML-Extensions.md) | XMLDocument and XMLElement FCPXML extensions |
| [14 — High-Level Model](14-High-Level-Model.md) | FinalCutPro.FCPXML, Root, events, projects |
| [15 — Errors & Utilities](15-Errors-Utilities.md) | Error types, ErrorHandling, ProgressBar, FCPXMLUID |
| [16 — CLI](16-CLI.md) | Experimental command-line interface (pipeline-neo) |
| [17 — Examples](17-Examples.md) | End-to-end workflows and code examples |
| [18 — Cross-Platform & iOS](18-Cross-Platform-iOS.md) | XML abstraction layer, PNXML protocols, Foundation vs AEXML backends, iOS support |

---

## Quick links

- **Project README:** [../README.md](../README.md) (repository root)
- **CLI reference:** [../Sources/PipelineNeoCLI/README.md](../Sources/PipelineNeoCLI/README.md)
- **FCPXML reference:** [fcp.cafe/developers/fcpxml](https://fcp.cafe/developers/fcpxml)
