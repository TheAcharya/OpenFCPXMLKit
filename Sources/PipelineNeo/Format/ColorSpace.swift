//
//  ColorSpace.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Color space definitions for FCPXML video formats.
//

import Foundation

/// Video color space for FCPXML format definitions.
///
/// Use with format resources and sequence/project color settings. For existing
/// `PNXMLElement.RenderColorSpace` (e.g. rec601NTSC, rec709) see `XMLElementExtension`.
@available(macOS 12.0, *)
public enum ColorSpace: String, Sendable, Equatable, Hashable, Codable, CaseIterable {

    /// Rec. 709 (HD).
    case rec709 = "rec709"

    /// Rec. 2020 (UHD/4K).
    case rec2020 = "rec2020"

    /// Rec. 2020 HLG (HDR).
    case rec2020HLG = "rec2020hlg"

    /// Rec. 2020 PQ (HDR).
    case rec2020PQ = "rec2020pq"

    /// sRGB (web).
    case sRGB = "srgb"

    /// FCPXML `renderColorSpace` / colorSpace attribute value.
    public var fcpxmlValue: String {
        switch self {
        case .rec709: return "1-1-1 (Rec. 709)"
        case .rec2020: return "9-18-9 (Rec. 2020)"
        case .rec2020HLG: return "9-18-9 (Rec. 2020 HLG)"
        case .rec2020PQ: return "9-18-9 (Rec. 2020 PQ)"
        case .sRGB: return "sRGB IEC61966-2.1"
        }
    }

    /// Whether this is an HDR color space.
    public var isHDR: Bool {
        switch self {
        case .rec2020HLG, .rec2020PQ: return true
        default: return false
        }
    }

    /// Whether this is wide color gamut.
    public var isWideGamut: Bool {
        switch self {
        case .rec2020, .rec2020HLG, .rec2020PQ: return true
        default: return false
        }
    }
}

@available(macOS 12.0, *)
extension ColorSpace: CustomStringConvertible {
    public var description: String {
        switch self {
        case .rec709: return "Rec. 709"
        case .rec2020: return "Rec. 2020"
        case .rec2020HLG: return "Rec. 2020 HLG"
        case .rec2020PQ: return "Rec. 2020 PQ"
        case .sRGB: return "sRGB"
        }
    }
}
