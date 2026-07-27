# 21 — Shot Extraction

[← Manual Index](00-Index.md)

---

Still-image **Shot Extraction** builds a shot dataset from the **primary timeline** only: one PNG per still-image clip (in timeline order), plus a CSV or Notion-compatible JSON manifest. Excel/PDF reporting is unrelated and unchanged.

## Requirements

- Primary spine video windows must reference **still-image** assets (`duration="0s"` / image files).
- Any **video** media on the primary spine aborts with `ShotExtractionError.containsVideoMedia`.
- Connected audio and secondary storylines are ignored.
- Reused stills are copied once per shot (distinct Shot IDs / PNG filenames).
- All images are written as **PNG** (pixel dimensions preserved).

## Library API

```swift
var options = FinalCutPro.FCPXML.ShotExtractionOptions(
    sceneNumber: "50",
    extractFormat: .csv,          // or .notion
    outputDir: outputDirectory,
    folderFormat: .medium,        // short | medium | long
                                  // medium → `Demo_V1-2026-07-27-09-14-21`
    resultFilePath: resultJSON,   // optional
    projectName: nil,
    mediaBaseURL: fcpxmlParent,
    icon: "🎬"                    // optional; fills Icon Image column
)
let result = try await fcpxml.extractShots(options: options)
// result.exportFolder, result.manifestPath, result.shots, result.imagePaths
```

Public types (under `FinalCutPro.FCPXML`):

| Type | Role |
|------|------|
| `ShotExtractor` / `extractShots(options:)` | Run extraction |
| `ShotExtractionOptions` | Scene number, format, folder style, icon, paths |
| `ShotExtractionResult` | Export folder, manifest path, shots, image paths |
| `ShotRecord` | One row (`shotID`, `shotNumber`, `sceneNumber`, `shotDuration`, `iconImage`, `imageFilename`, …) |
| `ShotExtractionFormat` | `.csv` \| `.notion` |
| `ShotExtractionFolderFormat` | `.short` \| `.medium` \| `.long` |
| `ShotExtractionError` | e.g. `containsVideoMedia` |

Shot IDs use three-digit padding: scene `50` with 30 shots → `50-001` … `50-030`.  
`Shot Duration` is floored whole seconds as `HH:MM:SS`.  
`Scene Number`, **Icon Image** (from `icon` / `--icon`), and **Image Filename** are filled automatically; other Shot Data columns are present but empty for Notion/spreadsheet templates. Column order ends with **Icon Image**, then **Image Filename**.

## Manifest formats

| `extractFormat` / `--extract-format` | Output |
|--------------------------------------|--------|
| `csv` (default) | UTF-8 CSV via [swift-textfile](https://github.com/orchetect/swift-textfile) (`TextFile`) |
| `notion` | Pretty-printed JSON **array** of string dictionaries (one object per shot) |

### Notion JSON (`--extract-format notion`)

The Notion JSON shape follows the [csv2notion-neo](https://github.com/TheAcharya/csv2notion-neo) JSON import convention: a top-level array of objects whose keys match the Shot Data column headers (including **Icon Image** and **Image Filename**). Empty template columns are present as empty strings so the file can be uploaded/merged into a Notion database with csv2notion-neo alongside the PNG files in the same export folder.

## CLI

```bash
OpenFCPXMLKit-CLI --extract-shots \
  --scene-number 50 \
  --extract-format notion \
  --folder-format medium \
  --icon "🎬" \
  --result-file-path /tmp/shots-result.json \
  /path/to/Scene.fcpxmld \
  /path/to/output-dir
```

| Flag | Notes |
|------|--------|
| `--extract-shots` | Enables Shot Extraction (exclusive with other modes) |
| `--scene-number` | **Required** |
| `--extract-format` | `csv` (default) or `notion` (JSON for [csv2notion-neo](https://github.com/TheAcharya/csv2notion-neo)) |
| `--folder-format` | `short` → `Demo_V1`<br>`medium` → `Demo_V1-2026-07-27-09-14-21` (default)<br>`long` → `Demo_V1-2026-07-27-09-14-21-[CSV]` / `…-[Notion]` |
| `--icon` | Optional emoji (or any text) for the **Icon Image** column on every row |
| `--result-file-path` | Optional JSON summary |
| `--extract-project` | Optional timeline name filter |

See also [19 — CLI](19-CLI.md) and [OpenFCPXMLKitCLI/README.md](../../Sources/OpenFCPXMLKitCLI/README.md).

## Implementation notes

- Shots come from ``TimelineProjector`` primary-spine video windows (clips between cuts).
- Independent of `Reporting/` (Excel/PDF); consumes Projection only.
- Dependency: [swift-textfile](https://github.com/orchetect/swift-textfile) (`TextFile`) for CSV encoding.

---

## Next

- [22 — Examples](22-Examples.md) — end-to-end workflows and code examples.
- [12 — Timeline Projection](12-Timeline-Projection.md) — windows and occupancy used by Shot Extraction.
- [19 — CLI](19-CLI.md) — full CLI option groups.

[← Manual Index](00-Index.md)
