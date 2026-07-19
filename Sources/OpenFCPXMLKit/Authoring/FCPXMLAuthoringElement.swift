//
//  FCPXMLAuthoringElement.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Protocol for detached authoring value types that encode into OFKXML.
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// A detached authoring value that can emit XML under a versioned context.
    ///
    /// Implementations must not retain live XML nodes. Encoding is explicit (no reflection).
    public protocol Element: Sendable {
        /// Versions that may include this element or field when encoding.
        var availability: FinalCutPro.FCPXML.VersionAvailability { get }

        /// Appends this value under `parent` when available for ``Context/version``.
        ///
        /// When unavailable, implementations must no-op (omit) without throwing.
        func encode(into parent: any OFKXMLElement, context: FinalCutPro.FCPXML.Authoring.Context) throws
    }
}

extension FinalCutPro.FCPXML.Authoring.Element {
    /// Default availability: all supported DTD versions.
    public var availability: FinalCutPro.FCPXML.VersionAvailability { .always }

    /// Encodes only when ``availability`` contains the context version.
    public func encodeIfAvailable(
        into parent: any OFKXMLElement,
        context: FinalCutPro.FCPXML.Authoring.Context
    ) throws {
        guard context.allows(availability) else { return }
        try encode(into: parent, context: context)
    }
}
