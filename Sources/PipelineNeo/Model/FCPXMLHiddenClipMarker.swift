//
//  FCPXMLHiddenClipMarker.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Hidden clip marker element (marker_item, FCPXML 1.13+). EMPTY; no attributes in DTD.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Hidden clip marker (marker_item). FCPXML 1.13+; stripped when converting to &lt; 1.13.
    ///
    /// DTD: `<!ELEMENT hidden-clip-marker EMPTY>`. No attributes. Used among clip annotations
    /// (marker_item) to denote a hidden marker.
    public struct HiddenClipMarker: FCPXMLElement {
        public let element: any PNXMLElement

        public let elementType: ElementType = .hiddenClipMarker

        public static let supportedElementTypes: Set<ElementType> = [.hiddenClipMarker]

        public init() {
            element = PNXMLDefaultFactory().makeElement(name: elementType.rawValue)
        }

        public init?(element: any PNXMLElement) {
            self.element = element
            guard _isElementTypeSupported(element: element) else { return nil }
        }
    }
}

// MARK: - Typing

extension PNXMLElement {
    /// FCPXML: Returns the element wrapped in a ``FinalCutPro/FCPXML/HiddenClipMarker`` model.
    /// Call this on a `hidden-clip-marker` element only.
    public var fcpAsHiddenClipMarker: FinalCutPro.FCPXML.HiddenClipMarker? {
        .init(element: self)
    }
}
