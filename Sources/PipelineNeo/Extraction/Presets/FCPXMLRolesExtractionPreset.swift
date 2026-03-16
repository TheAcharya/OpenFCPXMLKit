//
//  FCPXMLRolesExtractionPreset.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Extraction preset for roles within a scope.
//

import Foundation
import SwiftExtensions

extension FinalCutPro.FCPXML {
    /// FCPXML extraction preset that extracts roles within a specified scope.
    /// Results are sorted by type, then by name.
    public struct RolesExtractionPreset: FCPXMLExtractionPreset {
        public var roleTypes: Set<RoleType>
        
        public init(
            roleTypes: Set<RoleType>
        ) {
            self.roleTypes = roleTypes
        }
        
        public func perform(
            on extractable: any PNXMLElement,
            scope: FinalCutPro.FCPXML.ExtractionScope
        ) async -> [FinalCutPro.FCPXML.AnyRole] {
            // early return in case no types are specified
            guard !roleTypes.isEmpty else { return [] }
            
            let extracted = await extractable.fcpExtract(scope: scope) { element in
                element
                    .value(forContext: .inheritedRoles)
                    .filter(roleTypes: roleTypes)
                    .map(\.wrapped)
            }
            
            let output = extracted
                .flatMap { $0 }
                .removingDuplicates()
                .sortedByRoleTypeThenByName()
            
            return output
        }
    }
}

extension FCPXMLExtractionPreset where Self == FinalCutPro.FCPXML.RolesExtractionPreset {
    /// FCPXML extraction preset that extracts roles within a specified scope.
    /// Results are sorted by type, then by name.
    public static func roles(
        roleTypes: Set<FinalCutPro.FCPXML.RoleType> = .allCases
    ) -> FinalCutPro.FCPXML.RolesExtractionPreset {
        FinalCutPro.FCPXML.RolesExtractionPreset(
            roleTypes: roleTypes
        )
    }
}
