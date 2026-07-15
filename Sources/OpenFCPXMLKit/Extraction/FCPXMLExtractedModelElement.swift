//
//  FCPXMLExtractedModelElement.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol for extracted elements with concrete model types.
//

import Foundation
import SwiftTimecode

/// Protocol for extracted elements that adds contextual properties.
public protocol FCPXMLExtractedModelElement: FCPXMLExtractedElement {
    /// Concrete model type associated with the extracted element.
    associatedtype Model: FCPXMLElement
}

// MARK: - Default Implementation

extension FCPXMLExtractedModelElement {
    /// Returns the XML element wrapped in a model struct.
    public var model: Model {
        // this guard only necessary because this returns an Optional
        guard let model = Model(element: element) else {
            assertionFailure("Could not form \(Model.self) model struct.")
            return Model()
        }
        return model
    }
}
