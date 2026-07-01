//
//  FCPXMLUID.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Generates valid FCPXML-style UIDs (uppercase UUID with hyphens).
//

import Foundation

/// Generates and validates FCPXML-style unique identifiers.
///
/// Final Cut Pro uses uppercase hexadecimal UUIDs with hyphens (e.g. `D71600AB-2F01-4850-8DBD-E9F0594BD004`)
/// for elements such as `event` and `project`. Use these when creating new FCPXML documents so they match
/// FCP export and open correctly in Final Cut Pro.
@available(macOS 26.0, *)
public enum FCPXMLUID: Sendable {

    /// Generates a new FCPXML-style UID (uppercase UUID with hyphens).
    ///
    /// Example: `"D71600AB-2F01-4850-8DBD-E9F0594BD004"`
    /// - Returns: A new unique identifier string suitable for `event` and `project` `uid` attributes.
    public static func random() -> String {
        UUID().uuidString
    }

    /// Returns whether the string is a valid FCPXML-style UID (36 characters, uppercase hex and hyphens in UUID format).
    ///
    /// - Parameter string: The string to validate.
    /// - Returns: `true` if the string matches the pattern `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` with valid hex digits.
    public static func isValid(_ string: String) -> Bool {
        guard string.count == 36 else { return false }
        let hex = CharacterSet(charactersIn: "0123456789ABCDEF")
        let components = string.split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 5,
              components[0].count == 8,
              components[1].count == 4,
              components[2].count == 4,
              components[3].count == 4,
              components[4].count == 12
        else { return false }
        let combined = components.joined()
        return combined.unicodeScalars.allSatisfy { hex.contains($0) }
    }
}
