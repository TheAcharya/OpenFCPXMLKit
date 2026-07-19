//
//  FCPXMLAuthoredDocument.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Detached FCPXML document root for authoring round-trips.
//

import Foundation

extension FinalCutPro.FCPXML.Authoring {
    /// Independent FCPXML document value graph (no live XML ownership).
    ///
    /// Encode with ``makeXMLDocument(factory:)`` / ``xmlString(factory:)``. Decode a limited
    /// subset with ``init(xmlDocument:)``. Expand coverage incrementally; do not use this
    /// layer inside Reporting.
    public struct Document: Sendable, Hashable {
        /// Document version written on the root `fcpxml` element.
        public var version: FCPXMLVersion

        /// Detached resources.
        public var resources: Resources

        /// Detached library (optional for resource-only documents).
        public var library: Library?

        public init(
            version: FCPXMLVersion = .default,
            resources: Resources = Resources(),
            library: Library? = nil
        ) {
            self.version = version
            self.resources = resources
            self.library = library
        }

        /// Builds a convenience document with one format, one asset, and one project clip.
        public static func simpleProject(
            version: FCPXMLVersion = .default,
            projectName: String = "Untitled",
            eventName: String = "Event",
            format: Format,
            asset: Asset,
            clip: AssetClip,
            sequenceDuration: String
        ) -> Document {
            Document(
                version: version,
                resources: Resources(formats: [format], assets: [asset]),
                library: Library(
                    events: [
                        Event(
                            name: eventName,
                            projects: [
                                Project(
                                    name: projectName,
                                    sequence: Sequence(
                                        formatID: format.id,
                                        duration: sequenceDuration,
                                        spine: Spine(assetClips: [clip])
                                    )
                                )
                            ]
                        )
                    ]
                )
            )
        }

        /// Encodes this value graph into an ``OFKXMLDocument``.
        public func makeXMLDocument(
            factory: any OFKXMLFactory = OFKXMLDefaultFactory()
        ) throws -> any OFKXMLDocument {
            let context = Context(version: version, factory: factory)
            let root = context.makeElement(name: "fcpxml")
            root.addAttribute(name: "version", value: version.stringValue)
            try resources.encodeIfAvailable(into: root, context: context)
            if let library {
                try library.encodeIfAvailable(into: root, context: context)
            }
            let document = factory.makeDocument()
            document.setRootElement(root)
            return document
        }

        /// Serializes to an XML string.
        public func xmlString(
            factory: any OFKXMLFactory = OFKXMLDefaultFactory()
        ) throws -> String {
            let document = try makeXMLDocument(factory: factory)
            return document.xmlString
        }

        /// Decodes a limited authoring subset from a live XML document.
        public init(xmlDocument: any OFKXMLDocument) throws {
            guard let root = xmlDocument.rootElement() else {
                throw Error.missingRootElement
            }
            guard root.name == "fcpxml" else {
                throw Error.invalidRootName(root.name ?? "")
            }
            let versionString = root.stringValue(forAttributeNamed: "version")
            guard let versionString,
                  let version = FCPXMLVersion(string: versionString)
            else {
                throw Error.missingOrInvalidVersion(versionString)
            }
            guard let resourcesElement = root.firstChildElement(named: "resources"),
                  let resources = Resources.decode(from: resourcesElement)
            else {
                throw Error.missingResources
            }
            let library: Library?
            if let libraryElement = root.firstChildElement(named: "library") {
                library = try Library.decode(from: libraryElement)
            } else {
                library = nil
            }
            self.init(version: version, resources: resources, library: library)
        }
    }
}
