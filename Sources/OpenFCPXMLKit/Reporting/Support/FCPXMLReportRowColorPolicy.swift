//
//  FCPXMLReportRowColorPolicy.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Shared workbook row text colour rules for Excel and PDF report export.
//

import CoreGraphics
import Foundation

enum FCPXMLReportRowColorPolicy {
    /// Workbook sheet context for row text colour when Category is unavailable.
    enum Context {
        case roleInventory
        case keywords
        case titlesAndGenerators
        case effects
        case speedChangeEffects
        case transitions
    }
    
    enum Bucket {
        case videoOrSRT
        case titles
        case audio
        case gap
        
        var fontColorHex: String {
            switch self {
            case .videoOrSRT:
                return "#0066FF"
            case .titles:
                return "#9933FF"
            case .audio:
                return "#00AA44"
            case .gap:
                return "#808080"
            }
        }
    }
    
    static let roleSubroleColumnHeader = "Role ▸ Subrole"
    static let categoryColumnHeader = "Category"
    
    static func bucket(
        for roleSubrole: String,
        categoryLabel: String? = nil,
        context: Context = .roleInventory
    ) -> Bucket {
        switch context {
        case .keywords:
            return .videoOrSRT
        case .transitions:
            return .gap
        case .effects, .speedChangeEffects:
            return roleBucketFromRoleName(roleSubrole, titlesAsVideo: true)
        case .titlesAndGenerators:
            return roleBucketFromRoleName(roleSubrole, titlesAsVideo: false)
        case .roleInventory:
            if let categoryLabel,
               let category = FinalCutPro.FCPXML.ReportClipCategory.matchingWorkbookLabel(categoryLabel)
            {
                if category == .primaryGap {
                    return .gap
                }
                if category.isTitleCategory {
                    return .titles
                }
                if category.isVideoCategory || category.isCaptionCategory {
                    return .videoOrSRT
                }
                if category.isAudioCategory {
                    return .audio
                }
            }
            
            return roleBucketFromRoleName(roleSubrole, titlesAsVideo: false)
        }
    }
    
    static func markerFontColorHex(
        for markerType: FinalCutPro.FCPXML.MarkerReportType
    ) -> String {
        switch markerType {
        case .standard:
            return Bucket.videoOrSRT.fontColorHex
        case .incompleteToDo:
            return "#FF0000"
        case .completedToDo:
            return Bucket.audio.fontColorHex
        case .chapter:
            return "#FF8800"
        }
    }
    
    static func cgColor(fromHex hex: String) -> CGColor? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return nil
        }
        
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        
        return CGColor(
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            components: [red, green, blue, 1]
        )
    }
    
    static func cgColor(for bucket: Bucket) -> CGColor? {
        cgColor(fromHex: bucket.fontColorHex)
    }
    
    static func markerCGColor(
        for markerType: FinalCutPro.FCPXML.MarkerReportType
    ) -> CGColor? {
        cgColor(fromHex: markerFontColorHex(for: markerType))
    }
    
    static func textColor(
        forRowValues values: [String],
        headers: [String],
        context: Context,
        defaultColor: CGColor
    ) -> CGColor {
        guard let roleColumnIndex = headers.firstIndex(of: roleSubroleColumnHeader),
              values.indices.contains(roleColumnIndex)
        else {
            return defaultColor
        }
        
        let roleValue = values[roleColumnIndex]
        var categoryValue: String?
        if let categoryColumnIndex = headers.firstIndex(of: categoryColumnHeader),
           values.indices.contains(categoryColumnIndex)
        {
            categoryValue = values[categoryColumnIndex]
        }
        
        return cgColor(
            for: bucket(
                for: roleValue,
                categoryLabel: categoryValue,
                context: context
            )
        ) ?? defaultColor
    }
    
    private static func roleBucketFromRoleName(
        _ roleSubrole: String,
        titlesAsVideo: Bool
    ) -> Bucket {
        if roleSubrole.localizedCaseInsensitiveContains("gap") {
            return .gap
        }
        
        let mainRole = mainRoleName(in: roleSubrole).lowercased()
        
        if mainRole.isEmpty {
            return .videoOrSRT
        }
        
        if mainRole == "titles" || mainRole == "title" {
            return titlesAsVideo ? .videoOrSRT : .titles
        }
        
        if ["video", "srt", "vfx"].contains(mainRole) || mainRole.hasPrefix("vfx") {
            return .videoOrSRT
        }
        
        if ["dialogue", "effects", "music", "atmos", "score komponist", "sound mix"].contains(mainRole) {
            return .audio
        }
        
        if roleSubrole.localizedCaseInsensitiveContains("vfx")
            || roleSubrole.localizedCaseInsensitiveContains("scanline")
        {
            return .videoOrSRT
        }
        
        if roleSubrole.localizedCaseInsensitiveContains("title") {
            return titlesAsVideo ? .videoOrSRT : .titles
        }
        
        return .videoOrSRT
    }
    
    private static func mainRoleName(in roleSubrole: String) -> String {
        let trimmed = roleSubrole.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if let separatorIndex = trimmed.firstIndex(where: { ["▸", "•", "·"].contains(String($0)) }) {
            return String(trimmed[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let commaIndex = trimmed.firstIndex(of: ",") {
            return String(trimmed[..<commaIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return trimmed
    }
}
