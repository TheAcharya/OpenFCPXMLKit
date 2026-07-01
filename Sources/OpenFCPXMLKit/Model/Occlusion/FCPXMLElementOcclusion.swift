//
//  FCPXMLElementOcclusion.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Element occlusion enum (notOccluded, partially, fully).
//

import Foundation

extension FinalCutPro.FCPXML {
    public enum ElementOcclusion: Equatable, Hashable, CaseIterable, Sendable {
        /// The element is not occluded at all by its parent.
        case notOccluded
        
        /// The element is partially occluded by its parent.
        case partiallyOccluded
        
        /// The element is fully occluded by its parent.
        case fullyOccluded
    }
}

extension Set<FinalCutPro.FCPXML.ElementOcclusion> {
    public static let allCases: Self = Set(Element.allCases)
}
