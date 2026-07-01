//
//  FCPXMLAnyElementModelType.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Type-erased wrapper for FCPXML element model type protocol.
//

import Foundation

// MARK: - AnyElementModelType

extension FinalCutPro.FCPXML {
    public struct AnyElementModelType: Sendable {
        public let base: any FCPXMLElementModelTypeProtocol
        
        public var supportedElementTypes: Set<FinalCutPro.FCPXML.ElementType> {
            base.supportedElementTypes
        }
        
        public init<T: FCPXMLElementModelTypeProtocol>(base: T) {
            self.base = base
        }
    }
}
