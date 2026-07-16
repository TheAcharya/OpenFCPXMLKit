# 03 — Timecode & Timing

[← Manual Index](00-Index.md)

---

## Time conversions with SwiftTimecode

Use **TimecodeConverter** (or **FCPXMLUtility** with injected converter) to convert between `CMTime`, SwiftTimecode **Timecode**, and FCPXML time strings:

```swift
import OpenFCPXMLKit
import SwiftTimecode

let timecodeConverter = TimecodeConverter()
let utility = FCPXMLUtility(timecodeConverter: timecodeConverter)

// CMTime → Timecode
let cmTime = CMTime(value: 3600, timescale: 1)
let timecode = utility.timecode(from: cmTime, frameRate: .fps24)

// Timecode → CMTime
let newTimecode = try Timecode(.realTime(seconds: 7200), at: .fps24)
let newCMTime = utility.cmTime(from: newTimecode)

// Conform to frame duration and FCPXML time string
let frameDuration = CMTime(value: 1, timescale: 24)
let conformed = cmTime.conformed(toFrameDuration: frameDuration, using: timecodeConverter)
let fcpxmlTime = cmTime.fcpxmlTime(using: timecodeConverter)
```

**Note:** Use SwiftTimecode's `Timecode(.realTime(seconds:), at:)` and frame rate cases `.fps23_976`, `.fps24`, `.fps25`, `.fps29_97`, `.fps30`, `.fps50`, `.fps59_94`, `.fps60` (not the legacy `._24`, `._25`, etc.).

---

## FCPXMLTimecode: custom timecode type

**FCPXMLTimecode** wraps SwiftTimecode's `Fraction` and provides FCPXML-oriented operations: arithmetic, frame alignment, CMTime conversion, and parsing of FCPXML time strings.

```swift
import OpenFCPXMLKit

// From seconds
let fiveSeconds = FCPXMLTimecode(seconds: 5.0)
print(fiveSeconds.fcpxmlString)  // "5s"

// From rational (value/timescale)
let oneFrame = FCPXMLTimecode(value: 1001, timescale: 30000)
print(oneFrame.fcpxmlString)    // "1001/30000s"

// From CMTime
let cmTime = CMTime(value: 1001, timescale: 30000)
let timecode = FCPXMLTimecode(cmTime: cmTime)

// From frames and frame rate
let tenFrames = FCPXMLTimecode(frames: 10, frameRate: .fps24)

// Parse FCPXML string
let parsed = FCPXMLTimecode(fcpxmlString: "1001/30000s")

// Arithmetic
let total = clip1Duration + clip2Duration
let doubled = clip1Duration * 2

// Comparison
print(time1 > time2)

// Convert to CMTime
let cm = timecode.toCMTime()

// Frame alignment
let aligned = FCPXMLTimecode.frameAligned(seconds: 0.6, frameRate: .fps24)
let alignedTC = timecode.aligned(to: .fps24)
```

---

## CMTime Codable extension

**CMTime** is extended to be **Codable** using FCPXML time string format (e.g. `"3000/600s"`):

```swift
import OpenFCPXMLKit
import CoreMedia

let time = CMTime(seconds: 5.0, preferredTimescale: 600)
let encoder = JSONEncoder()
let data = try encoder.encode(time)

let decoder = JSONDecoder()
let decoded = try decoder.decode(CMTime.self, from: data)
```

---

## Async time operations

All time conversion APIs have async variants on the service and on the converter:

```swift
let timecode = await service.timecode(from: time, frameRate: .fps24)
let cmTime = await service.cmTime(fromFCPXMLTime: "3600/60000")
let timeString = await service.fcpxmlTime(fromCMTime: cmTime)
let conformed = await service.conform(time: time, toFrameDuration: frameDuration)
```

---

## Projection and Double-safe composition

Timeline **Projection** (and any code that adds conform-scaled attribute fractions to literal FCPXML rationals) must compose via `ProjectionTiming.adding` / `subtracting` (Double intermediates → `Fraction` at 12 decimal places). Do not use SwiftTimecode `Fraction` operators for absolute timeline placement — they can trap on Int overflow when mixing conform-scaled values with literal rationals.

---

## Next

- [04 — Service & Logging](04-Service-Logging.md) — FCPXMLService, ModularUtilities, logging.
