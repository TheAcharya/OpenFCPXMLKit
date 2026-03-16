//
//  XMLElementExtensionTypes.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Enums and types formerly nested in the PNXMLElement extension.
//	Swift does not allow types to be nested in protocol extensions,
//	so they are declared at file scope and typealiased back.
//

import Foundation

// MARK: - FCPXMLElementError

/// Errors that can occur during FCPXML element operations.
enum FCPXMLElementError: Error, CustomStringConvertible, Sendable {
    case notAnEvent(elementName: String)
    case notAnAnnotatableItem(elementName: String)
    case notAnAnnotation(elementName: String)

    var description: String {
        switch self {
        case .notAnEvent(let elementName):
            return "The \"\(elementName)\" element is not an event."
        case .notAnAnnotatableItem(let elementName):
            return "The \"\(elementName)\" element cannot be annotated."
        case .notAnAnnotation(let elementName):
            return "The \"\(elementName)\" element is not an annotation."
        }
    }
}

// MARK: - PNXMLElementTimecodeFormat

/// Legacy timecode format enum used by the PNXMLElement extension.
/// Equivalent to `FinalCutPro.FCPXML.TimecodeFormat` but kept for
/// backward compatibility with the legacy XMLElement API surface.
public enum PNXMLElementTimecodeFormat: String, Sendable {
    case dropFrame = "DF"
    case nonDropFrame = "NDF"
}

// MARK: - PNXMLElementAudioLayout

/// Legacy audio layout enum used by the PNXMLElement extension.
public enum PNXMLElementAudioLayout: String, Sendable {
    case mono = "mono"
    case stereo = "stereo"
    case surround = "surround"
}

// MARK: - PNXMLElementAudioRate

/// Legacy audio rate enum used by the PNXMLElement extension.
/// Uses sequence-style raw values ("32k", "48k", etc.).
public enum PNXMLElementAudioRate: String, Sendable {
    case rate32kHz = "32k"
    case rate44_1kHz = "44.1k"
    case rate48kHz = "48k"
    case rate88_2kHz = "88.2k"
    case rate96kHz = "96k"
    case rate176_4kHz = "176.4k"
    case rate192kHz = "192k"
}

// MARK: - PNXMLElementRenderColorSpace

/// Legacy render color space for existing FCPXML project/sequence attributes.
///
/// For new export workflows, prefer ``ColorSpace`` which includes HDR variants
/// and provides `fcpxmlValue` for attribute serialisation.
public enum PNXMLElementRenderColorSpace: String, Sendable {
    case rec601NTSC = "Rec. 601 (NTSC)"
    case rec601PAL = "Rec. 601 (PAL)"
    case rec709 = "Rec. 709"
    case rec2020 = "Rec. 2020"
}

// MARK: - PNXMLElementMulticamSourceEnable

public enum PNXMLElementMulticamSourceEnable: String, Sendable {
    case audio = "audio"
    case video = "video"
    case all = "all"
    case none = "none"
}

// MARK: - PNXMLElementCaptionFormat

/// The caption format included in caption role attributes.
public enum PNXMLElementCaptionFormat: String, Sendable {
    case itt = "ITT"
    case cea608 = "CEA608"
}

// MARK: - PNXMLElementCaptionLanguage

/// RFC 5646 language tags for use in caption role attributes.
/// The languages included in this enum are those supported by FCPX.
public enum PNXMLElementCaptionLanguage: String, Sendable {
    case afrikaans = "af"
    case arabic = "ar"
    case bangla = "bn"
    case bulgarian = "bg"
    case catalan = "ca"
    case chineseCantonese = "yue-Hant"
    case chineseSimplified = "cmn-Hans"
    case chineseTraditional = "cmn-Hant"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case englishAustralia = "en-AU"
    case englishCanada = "en-CA"
    case englishUnitedKingdom = "en-GB"
    case englishUnitedStates = "en-US"
    case estonian = "et"
    case finnish = "fi"
    case frenchBelgium = "fr-BE"
    case frenchCanada = "fr-CA"
    case frenchFrance = "fr-FR"
    case frenchSwitzerland = "fr-CH"
    case german = "de"
    case germanAustria = "de-AT"
    case germanGermany = "de-DE"
    case germanSwitzerland = "de-CH"
    case greek = "el"
    case greekCyprus = "el-CY"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case icelandic = "is"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case kannada = "kn"
    case kazakh = "kk"
    case korean = "ko"
    case lao = "lo"
    case latvian = "lv"
    case lithuanian = "lt"
    case luxembourgish = "lb"
    case malay = "ms"
    case malayalam = "ml"
    case maltese = "mt"
    case marathi = "mr"
    case norwegian = "no"
    case polish = "pl"
    case portugueseBrazil = "pt-BR"
    case portuguesePortugal = "pt-PT"
    case punjabi = "pa"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case slovenian = "sl"
    case spanishLatinAmerica = "es-419"
    case spanishMexico = "es-MX"
    case spanishSpain = "es-ES"
    case swedish = "sv"
    case tagalog = "tl"
    case tamil = "ta"
    case telugu = "te"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case urdu = "ur"
    case vietnamese = "vi"
    case zulu = "zu"
}

// MARK: - PNXMLElementCEA608CaptionDisplayStyle

/// Caption display style for CEA-608 captions
public enum PNXMLElementCEA608CaptionDisplayStyle: String, Sendable {
    case popOn = "pop-on"
    case paintOn = "paint-on"
    case rollUp = "roll-up"
}

// MARK: - PNXMLElementITTCaptionPlacement

/// Caption placement for ITT captions.
public enum PNXMLElementITTCaptionPlacement: String, Sendable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
}

// MARK: - PNXMLElementCEA608CaptionAlignment

/// Caption alignment for CEA-608 captions.
public enum PNXMLElementCEA608CaptionAlignment: String, Sendable {
    case left = "left"
    case center = "center"
    case right = "right"
}

// MARK: - PNXMLElementCEA608Color

/// Color values for CEA-608 captions. The raw value is the color expressed as
/// "red green blue alpha" which is the way it is represented in FCPXML text style elements.
public enum PNXMLElementCEA608Color: String, Sendable {
    case red = "1 0 0 1"
    case yellow = "1 1 0 1"
    case green = "0 1 0 1"
    case cyan = "0 1 1 1"
    case blue = "0 0 1 1"
    case magenta = "1 0 1 1"
    case white = "1 1 1 1"
    case black = "0 0 0 1"
}

// MARK: - PNXMLElementStoryElementLocation

/// The location of a story element within its sequence or timeline.
///
/// - primaryStoryline: The story element exists on the primary storyline.
/// - attachedClip: The story element is attached to another clip that is on the primary storyline.
/// - secondaryStoryline: The story element is embedded in a secondary storyline.
public enum PNXMLElementStoryElementLocation: Sendable {
    case primaryStoryline
    case attachedClip
    case secondaryStoryline
}

// MARK: - PNXMLElement Typealiases

extension PNXMLElement {
    // These typealiases allow existing code to use e.g. `TimecodeFormat`
    // unqualified within PNXMLElement extension methods, preserving the
    // original API shape.

    typealias FCPXMLElementError = PipelineNeo.FCPXMLElementError
    public typealias TextAlignment = FinalCutPro.FCPXML.TextAlignment
    public typealias TimecodeFormat = PNXMLElementTimecodeFormat
    public typealias AudioLayout = PNXMLElementAudioLayout
    public typealias AudioRate = PNXMLElementAudioRate
    public typealias RenderColorSpace = PNXMLElementRenderColorSpace
    public typealias MulticamSourceEnable = PNXMLElementMulticamSourceEnable
    public typealias CaptionFormat = PNXMLElementCaptionFormat
    public typealias CaptionLanguage = PNXMLElementCaptionLanguage
    public typealias CEA608CaptionDisplayStyle = PNXMLElementCEA608CaptionDisplayStyle
    public typealias ITTCaptionPlacement = PNXMLElementITTCaptionPlacement
    public typealias CEA608CaptionAlignment = PNXMLElementCEA608CaptionAlignment
    public typealias CEA608Color = PNXMLElementCEA608Color
    public typealias StoryElementLocation = PNXMLElementStoryElementLocation
}
