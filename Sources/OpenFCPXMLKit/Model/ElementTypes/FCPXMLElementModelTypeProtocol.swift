//
//  FCPXMLElementModelTypeProtocol.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Protocol defining element model type with supported element types.
//

import Foundation

public protocol FCPXMLElementModelTypeProtocol<ModelType> 
where Self: Equatable, Self: Hashable, Self: Sendable
{
    associatedtype ModelType: FCPXMLElement
    var supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> { get }
}

extension FCPXMLElementModelTypeProtocol {
    public var supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> {
        ModelType.supportedElementTypes
    }
}
