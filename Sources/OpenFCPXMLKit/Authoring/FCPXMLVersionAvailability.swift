//
//  FCPXMLVersionAvailability.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Version range for detached authoring encode/omit decisions.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Declares which FCPXML document versions may emit an authored fact.
    ///
    /// Used by the detached ``Authoring`` layer so fields and elements introduced in later
    /// DTDs are omitted when encoding to an older target version (FCPXML 1.5 floor).
    /// Shared element/attribute introductions also live in ``VersionFeatureGate``.
    public struct VersionAvailability: Sendable, Hashable, Equatable {
        /// First version that may include the fact (`nil` = from the earliest supported DTD).
        public var introduced: FCPXMLVersion?

        /// Last version that may include the fact (`nil` = through the latest supported DTD).
        public var lastSupported: FCPXMLVersion?

        /// Available in every supported DTD version (1.5–1.14).
        public static let always = VersionAvailability(introduced: nil, lastSupported: nil)

        /// Available starting at `version` (inclusive) through the latest DTD.
        public static func from(_ version: FCPXMLVersion) -> VersionAvailability {
            VersionAvailability(introduced: version, lastSupported: nil)
        }

        /// Available from the earliest DTD through `version` (inclusive).
        public static func upTo(_ version: FCPXMLVersion) -> VersionAvailability {
            VersionAvailability(introduced: nil, lastSupported: version)
        }

        /// Available in the inclusive range `introduced`…`lastSupported`.
        public static func between(
            _ introduced: FCPXMLVersion,
            and lastSupported: FCPXMLVersion
        ) -> VersionAvailability {
            VersionAvailability(introduced: introduced, lastSupported: lastSupported)
        }

        public init(introduced: FCPXMLVersion? = nil, lastSupported: FCPXMLVersion? = nil) {
            self.introduced = introduced
            self.lastSupported = lastSupported
        }

        /// `true` when `version` lies inside this availability window.
        public func contains(_ version: FCPXMLVersion) -> Bool {
            if let introduced, !version.isAtLeast(introduced) {
                return false
            }
            if let lastSupported, version.isAtLeast(lastSupported), version != lastSupported {
                // version > lastSupported
                guard let lastIndex = FCPXMLVersion.allCases.firstIndex(of: lastSupported),
                      let versionIndex = FCPXMLVersion.allCases.firstIndex(of: version)
                else {
                    return false
                }
                if versionIndex > lastIndex { return false }
            }
            return true
        }
    }
}
