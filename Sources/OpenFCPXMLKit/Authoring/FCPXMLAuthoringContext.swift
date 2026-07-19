//
//  FCPXMLAuthoringContext.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Encode context for the detached authoring layer.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Namespace for detached (non-live) FCPXML document authoring value types.
    ///
    /// Authoring models do **not** wrap ``OFKXMLElement``. They are independent value
    /// graphs that encode into XML via ``Authoring/Document/makeXMLDocument(factory:)``
    /// and optionally decode a limited subset back. Live parse/edit remains in ``Model``.
    public enum Authoring {}
}

extension FinalCutPro.FCPXML.Authoring {
    /// Shared encode context: target document version and XML factory.
    public struct Context: Sendable {
        /// Target FCPXML version written on the root and used for omit-on-write.
        public var version: FCPXMLVersion

        /// Factory used to create elements and documents.
        public nonisolated(unsafe) var factory: any OFKXMLFactory

        public init(
            version: FCPXMLVersion = .default,
            factory: any OFKXMLFactory = OFKXMLDefaultFactory()
        ) {
            self.version = version
            self.factory = factory
        }

        /// `true` when `availability` allows emission at ``version``.
        public func allows(_ availability: FinalCutPro.FCPXML.VersionAvailability) -> Bool {
            availability.contains(version)
        }

        /// Creates an element with the given name.
        public func makeElement(name: String) -> any OFKXMLElement {
            factory.makeElement(name: name)
        }
    }
}
