//
//  FCPXMLRoot.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Root fcpxml element model providing document-level access.
//

import Foundation
import SwiftExtensions

// MARK: - root/*

extension FinalCutPro.FCPXML {
    /// Root `fcpxml` element in a FCPXML document.
    ///
    /// > Note: This struct conforms to `Codable` for JSON/PLIST conversion, but cannot be `Sendable`
    /// > because it wraps `PNXMLElement` which is not `Sendable`. Use with caution in concurrent contexts.
    public struct Root: FCPXMLElement, Equatable, Hashable, Codable {
        public let element: any PNXMLElement

        public let elementType: ElementType = .fcpxml

        public static let supportedElementTypes: Set<ElementType> = [.fcpxml]

        public init() {
            element = PNXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any PNXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case xmlString
        }
        
        /// Encodes the root element to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            // Convert PNXMLElement to XML string
            let xmlString = element.xmlString
            try container.encode(xmlString, forKey: .xmlString)
        }
        
        /// Creates a root element from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode XML string
            let xmlString = try container.decode(String.self, forKey: .xmlString)
            
            // Convert XML string to PNXMLElement
            guard let xmlData = xmlString.data(using: .utf8) else {
                throw FCPXMLCodableError.xmlStringConversionFailed
            }

            do {
                let document = try PNXMLDefaultFactory().makeDocument(data: xmlData, options: [])
                guard let rootElement = document.rootElement() else {
                    throw FCPXMLCodableError.xmlStringConversionFailed
                }

                // Initialize self with the root element
                self.element = rootElement
                guard _isElementTypeSupported(element: rootElement) else {
                    throw FCPXMLCodableError.xmlStringConversionFailed
                }
            } catch {
                throw FCPXMLCodableError.xmlStringConversionFailed
            }
        }
    }
    
    public enum RootChildren: String {
        case fcpxml
    }
}

// MARK: - Structure

extension FinalCutPro.FCPXML.Root {
    public enum Attributes: String {
        case version
    }
    
    // must contain one `resources` container
    // may contain zero or one `import-options`
    // may contain zero or one `library`
    // may contain zero or more `event`
    // may contain zero or more `project`
    
    // AFAIK it's possible to have clips here too
}

// MARK: - Attributes

extension FinalCutPro.FCPXML.Root {
    /// Returns the FCPXML format version.
    public var version: FinalCutPro.FCPXML.Version {
        guard let verString = element.stringValue(forAttributeNamed: Attributes.version.rawValue),
              let ver = FinalCutPro.FCPXML.Version(rawValue: verString)
        else { return .latest }
        
        return ver
    }
}

// MARK: - Children

extension FinalCutPro.FCPXML.Root {
    /// Get or set the `resources` XML element.
    /// Exactly one of these elements is always required.
    public var resources: any PNXMLElement {
        get {
            element.firstDefaultedChildElement(whereFCPElementType: .resources, using: PNXMLDefaultFactory())
        }
        nonmutating set {
            element._updateFirstChildElement(
                ofType: .resources,
                withChild: newValue
            )
        }
    }
    
    /// Access the contents of the `resources` XML element as a dictionary of elements
    /// keyed by resource ID.
    public var resourcesDict: [String: any PNXMLElement] {
        get {
            resources
                .childElements
                .mapDictionary {
                    (key: $0.fcpID ?? "", value: $0)
                }
        }
        nonmutating set {
            let sortedElements = newValue.values.sorted(by: {
                ($0.fcpID ?? "")
                    .caseInsensitiveCompare(($1.fcpID ?? ""))
                    == .orderedAscending
            })

            let resourcesContainer = PNXMLDefaultFactory().makeElement(name: FinalCutPro.FCPXML.ElementType.resources.rawValue)
            sortedElements.forEach { resourcesContainer.addChild($0) }
            resources = resourcesContainer
        }
    }
    
    /// Utility:
    /// Returns the `fcpxml/library` element if it exists.
    /// One or zero of these elements may be present within the `fcpxml` element.
    public var library: FinalCutPro.FCPXML.Library? {
        element.firstChild(whereFCPElement: .library)
    }
    
    /// Returns child `event` elements.
    public var events: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Event> {
        element.children(whereFCPElement: .event)
    }
    
    /// Returns child `project` elements.
    public var projects: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Project> {
        element.children(whereFCPElement: .project)
    }
    
    /// Get or set the `import-options` element.
    /// Zero or one of these elements may be present within the `fcpxml` element.
    public var importOptions: FinalCutPro.FCPXML.ImportOptions? {
        get {
            guard let importOptionsElement = element.firstChildElement(named: "import-options") else {
                return nil
            }
            
            let options = Array(importOptionsElement
                .childElements
                .compactMap { optionElement -> FinalCutPro.FCPXML.ImportOption? in
                    guard let key = optionElement.stringValue(forAttributeNamed: "key"),
                          let value = optionElement.stringValue(forAttributeNamed: "value") else {
                        return nil
                    }
                    return FinalCutPro.FCPXML.ImportOption(key: key, value: value)
                })
            
            return FinalCutPro.FCPXML.ImportOptions(options: options.isEmpty ? nil : options)
        }
        nonmutating set {
            // Remove existing import-options element if present
            element.removeChildren { $0.name == "import-options" }

            // Add new import-options element if provided
            guard let importOptions = newValue, !importOptions.options.isEmpty else { return }

            let factory = PNXMLDefaultFactory()
            let importOptionsElement = factory.makeElement(name: "import-options")
            for option in importOptions.options {
                let optionElement = factory.makeElement(name: "option")
                optionElement.addAttribute(name: "key", value: option.key)
                optionElement.addAttribute(name: "value", value: option.value)
                importOptionsElement.addChild(optionElement)
            }

            // Insert import-options before resources (if resources exists) or at the beginning
            if let resourcesIndex = element.childElements.firstIndex(where: { $0.name == FinalCutPro.FCPXML.ElementType.resources.rawValue }) {
                element.insertChild(importOptionsElement, at: resourcesIndex)
            } else {
                element.insertChild(importOptionsElement, at: 0)
            }
        }
    }
}

// MARK: - Import Options Helpers

extension FinalCutPro.FCPXML.Root {
    /// Adds an import option specifying whether assets referenced in the imported XML should be copied or linked.
    /// - Parameter shouldCopyAssets: A Boolean value indicating whether assets should be copied (`true`) or linked (`false`).
    public mutating func setShouldCopyAssetsOnImport(_ shouldCopyAssets: Bool) {
        var currentOptions = importOptions?.options ?? []
        let copyAssetsOption = FinalCutPro.FCPXML.ImportOption.copyAssets(shouldCopyAssets)
        
        // Remove existing copy assets option if present
        currentOptions.removeAll { $0.key == "copy assets" }
        currentOptions.append(copyAssetsOption)
        
        importOptions = FinalCutPro.FCPXML.ImportOptions(options: currentOptions)
    }
    
    /// Adds an import option specifying whether or not warnings generated during import into Final Cut Pro should be suppressed.
    /// - Parameter shouldSuppressWarnings: A Boolean value indicating whether or not warnings should be suppressed.
    public mutating func setShouldSuppressWarningsOnImport(_ shouldSuppressWarnings: Bool) {
        var currentOptions = importOptions?.options ?? []
        let suppressWarningsOption = FinalCutPro.FCPXML.ImportOption.suppressWarnings(shouldSuppressWarnings)
        
        // Remove existing suppress warnings option if present
        currentOptions.removeAll { $0.key == "suppress warnings" }
        currentOptions.append(suppressWarningsOption)
        
        importOptions = FinalCutPro.FCPXML.ImportOptions(options: currentOptions)
    }
    
    /// Adds an import option specifying the location of the library into which events and projects should be imported.
    /// - Parameter location: The file URL of the library location. If the specified URL represents a directory,
    ///   the default library name is used. If no library exists at the location specified, a new library is created.
    public mutating func setLibraryLocationForImport(_ location: String) {
        var currentOptions = importOptions?.options ?? []
        let libraryLocationOption = FinalCutPro.FCPXML.ImportOption.libraryLocation(location)
        
        // Remove existing library location option if present
        currentOptions.removeAll { $0.key == "library location" }
        currentOptions.append(libraryLocationOption)
        
        importOptions = FinalCutPro.FCPXML.ImportOptions(options: currentOptions)
    }
    
    /// Adds an import option specifying the location of the library into which events and projects should be imported.
    /// - Parameter location: The file URL of the library location.
    public mutating func setLibraryLocationForImport(_ location: URL) {
        setLibraryLocationForImport(location.absoluteString)
    }
}

// MARK: - Typing

// `fcpxml`
extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/Root`` model object.
    /// Call this on a `fcpxml` element only.
    public var fcpAsRoot: FinalCutPro.FCPXML.Root? {
        .init(element: self)
    }
}
