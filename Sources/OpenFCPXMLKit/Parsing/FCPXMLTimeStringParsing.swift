//
// FCPXMLTimeStringParsing.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//

//
//	Allocation-free parsing of FCPXML time value strings into `Fraction`.
//

import Foundation
import SwiftTimecode

extension Fraction {
    /// Initializes from an encoded Final Cut Pro FCPXML time value string, ie: `"60s"`,
    /// `"34900/2500s"` or `"-34900/2500s"`.
    ///
    /// Results are identical to `Fraction(fcpxmlString:)`. That initialiser compiles two
    /// `NSRegularExpression` instances on every call, which dominates document processing cost
    /// because time attributes are read millions of times while walking a large timeline. This
    /// scans UTF-8 bytes instead, and delegates to the regex initialiser for any input outside
    /// the ASCII grammar so that exotic values keep their existing behaviour.
    init?(fcpxmlTimeString string: String) {
        switch Fraction._fcpScanTimeString(string) {
        case let .parsed(fraction):
            self = fraction
        case .invalid:
            return nil
        case .outsideASCIIGrammar:
            guard let fraction = Fraction(fcpxmlString: string) else { return nil }
            self = fraction
        }
    }

    /// Outcome of scanning an FCPXML time value string.
    private enum TimeStringScan {
        /// The string matched the ASCII grammar.
        case parsed(Fraction)

        /// The string cannot match the grammar, so the regex initialiser would also fail.
        case invalid

        /// The string contains bytes the scanner does not handle (or a value that overflows
        /// `Int`), so the regex initialiser must decide.
        case outsideASCIIGrammar
    }

    /// Scans `-?<digits>s` or `-?<digits>/<digits>s`.
    private static func _fcpScanTimeString(_ string: String) -> TimeStringScan {
        var isNegative = false
        var numerator = 0
        var denominator = 0
        var numeratorDigits = 0
        var denominatorDigits = 0
        var sawSlash = false
        var sawSecondsSuffix = false

        for byte in string.utf8 {
            // FCPXML anchors the suffix at the end of the value.
            if sawSecondsSuffix { return .invalid }

            switch byte {
            case UInt8(ascii: "-"):
                guard !isNegative, numeratorDigits == 0, !sawSlash else { return .invalid }
                isNegative = true

            case UInt8(ascii: "0") ... UInt8(ascii: "9"):
                let digit = Int(byte - UInt8(ascii: "0"))
                if sawSlash {
                    guard let value = _fcpAppending(digit, to: denominator)
                    else { return .outsideASCIIGrammar }
                    denominator = value
                    denominatorDigits += 1
                } else {
                    guard let value = _fcpAppending(digit, to: numerator)
                    else { return .outsideASCIIGrammar }
                    numerator = value
                    numeratorDigits += 1
                }

            case UInt8(ascii: "/"):
                guard !sawSlash, numeratorDigits > 0 else { return .invalid }
                sawSlash = true

            case UInt8(ascii: "s"):
                sawSecondsSuffix = true

            default:
                return .outsideASCIIGrammar
            }
        }

        guard sawSecondsSuffix, numeratorDigits > 0 else { return .invalid }

        let signedNumerator = isNegative ? -numerator : numerator

        guard sawSlash else {
            // Matches the whole-seconds branch of `Fraction(fcpxmlString:)`, which marks the
            // value as reduced. Reducing `n/1` is a no-op, so the values are identical.
            return .parsed(Fraction(reducing: signedNumerator, 1))
        }

        guard denominatorDigits > 0 else { return .invalid }

        return .parsed(Fraction(signedNumerator, denominator))
    }

    /// Appends a decimal digit, returning `nil` on overflow.
    @inline(__always)
    private static func _fcpAppending(_ digit: Int, to value: Int) -> Int? {
        let (scaled, scaledOverflowed) = value.multipliedReportingOverflow(by: 10)
        guard !scaledOverflowed else { return nil }
        let (sum, sumOverflowed) = scaled.addingReportingOverflow(digit)
        guard !sumOverflowed else { return nil }
        return sum
    }
}
