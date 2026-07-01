//
//  FCPXMLRoleType.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Role type enum (audio, video, caption).
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Role type/classification.
    public enum RoleType: String, Equatable, Hashable, CaseIterable, Sendable {
        /// Audio role.
        case audio
        
        /// Video role.
        case video
        
        /// Closed caption role.
        case caption
    }
}

extension Set<FinalCutPro.FCPXML.RoleType> {
    public static let allCases: Self = Set(Element.allCases)
}
