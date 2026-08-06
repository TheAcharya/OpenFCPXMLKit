//
// FCPXMLShotManifestSchema.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Shot Data / Notion column schema for Shot Extraction manifests.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Column headers matching the Shot Data / Notion-compatible sample export.
    enum ShotManifestSchema {
        static let columns: [String] = [
            "Shot ID",
            "Shot Number",
            "Scene Location",
            "Shot Duration",
            "Scene Number",
            "Scene Prefix",
            "Scene Time",
            "Scene Time Range",
            "Scene Set",
            "Script Page No.",
            "Scene Characters",
            "Scene Cast",
            "Scene Description",
            "Shot Size & Type",
            "Camera Movement",
            "Camera Angle",
            "Equipment",
            "Lens",
            "Lighting Notes",
            "VFX",
            "VFX Description",
            "SFX",
            "SFX Description",
            "Music Track",
            "Production Design",
            "Props",
            "Props Notes",
            "Wardrobe ID",
            "Wardrobe Notes",
            "Hair",
            "Make Up",
            "Flag",
            "User Notes 1",
            "User Notes 2",
            "Start Date",
            "End Date",
            "Days",
            "Icon Image",
            "Image Filename"
        ]

        static func rowValues(for shot: ShotRecord) -> [String] {
            columns.map { column in
                switch column {
                case "Shot ID":
                    return shot.shotID
                case "Shot Number":
                    return String(shot.shotNumber)
                case "Shot Duration":
                    return shot.shotDuration
                case "Scene Number":
                    return shot.sceneNumber
                case "Icon Image":
                    return shot.iconImage
                case "Image Filename":
                    return shot.imageFilename
                default:
                    return ""
                }
            }
        }

        /// Column / value pairs in ``columns`` order (CSV and Notion JSON key order).
        static func orderedFields(for shot: ShotRecord) -> [(key: String, value: String)] {
            zip(columns, rowValues(for: shot)).map { (key: $0, value: $1) }
        }
    }
}
