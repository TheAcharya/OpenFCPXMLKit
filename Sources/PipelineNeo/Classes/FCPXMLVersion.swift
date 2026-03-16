//
//  FCPXMLVersion.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Type-safe FCPXML version handling for DTD validation and document creation.
//

import Foundation

/// Supported FCPXML document versions for DTD validation and document creation.
///
/// Each case corresponds to a DTD resource in the package. Use for validation and
/// document creation so the correct schema is used.
///
/// ## Version coverage
///
/// Pipeline Neo includes DTDs for versions 1.5 through 1.14. Use `FCPXMLVersion.default`
/// for the latest when creating new documents.
///
/// ## Relationship with FinalCutPro.FCPXML.Version
///
/// This enum is used for DTD validation and document creation (versions 1.5-1.14 with
/// bundled DTDs). The `FinalCutPro.FCPXML.Version` struct in the FinalCutPro layer
/// represents document versions (1.0-1.14) and is used for FCPXML parsing. They serve
/// complementary roles in the codebase.
///
/// ## Usage
///
/// ```swift
/// let doc = PNXMLDocument(resources: [], events: [], fcpxmlVersion: .default)
/// try doc.validateFCPXMLAgainst(version: .v1_14)
/// ```
@available(macOS 12.0, *)
public enum FCPXMLVersion: String, CaseIterable, Sendable {

    case v1_5 = "1.5"
    case v1_6 = "1.6"
    case v1_7 = "1.7"
    case v1_8 = "1.8"
    case v1_9 = "1.9"
    case v1_10 = "1.10"
    case v1_11 = "1.11"
    case v1_12 = "1.12"
    case v1_13 = "1.13"
    case v1_14 = "1.14"

    /// Default (latest) version for new documents.
    public static let `default`: FCPXMLVersion = .v1_14

    /// Version string for FCPXML document attribute (e.g. `"1.14"`).
    public var stringValue: String {
        rawValue
    }

    /// DTD resource name without extension, for Pipeline Neo DTDs (e.g. `Final_Cut_Pro_XML_DTD_version_1.14`).
    public var dtdResourceName: String {
        "Final_Cut_Pro_XML_DTD_version_\(rawValue)"
    }

    /// Creates an FCPXML version from a version string.
    ///
    /// - Parameter string: Version string (e.g. `"1.14"` or `"1_14"`).
    /// - Returns: Matching version or `nil`.
    public init?(string: String) {
        let normalized = string.replacingOccurrences(of: "_", with: ".")
        self.init(rawValue: normalized)
    }

    /// Returns `true` if this version is greater than or equal to `other`.
    public func isAtLeast(_ other: FCPXMLVersion) -> Bool {
        guard let selfIndex = FCPXMLVersion.allCases.firstIndex(of: self),
              let otherIndex = FCPXMLVersion.allCases.firstIndex(of: other) else {
            return false
        }
        return selfIndex >= otherIndex
    }

    /// Returns `true` if this version supports the .fcpxmld bundle format.
    /// FCPXML versions 1.5–1.9 support only single-file .fcpxml; 1.10 and later support .fcpxmld.
    public var supportsBundleFormat: Bool {
        isAtLeast(.v1_10)
    }

    // MARK: - Bridging to FinalCutPro.FCPXML.Version

    /// Converts this DTD version to the corresponding `FinalCutPro.FCPXML.Version` parsing type.
    ///
    /// This bridges the DTD validation layer (`FCPXMLVersion`, versions 1.5-1.14) to the
    /// parsing layer (`FinalCutPro.FCPXML.Version`, versions 1.0-1.14).
    public var fcpxmlVersion: FinalCutPro.FCPXML.Version {
        FinalCutPro.FCPXML.Version(rawValue: self.rawValue) ?? .ver1_14
    }

    /// Creates an FCPXMLVersion from a `FinalCutPro.FCPXML.Version`.
    ///
    /// Returns nil if the parsing version has no DTD equivalent (versions below 1.5).
    ///
    /// - Parameter version: A `FinalCutPro.FCPXML.Version` value.
    public init?(from version: FinalCutPro.FCPXML.Version) {
        self.init(rawValue: version.rawValue)
    }
}
