//
//  FCPXMLElementType.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Strongly typed enum for all FCPXML element types defined in the DTD.
//

import Foundation

/// Defines the element types that can exist in FCPXML documents (FCPXML 1.5–1.14).
/// Every element defined in the FCPXML DTDs is represented here for typed filtering and identification.
@available(macOS 26.0, *)
public enum FCPXMLElementType: String, CaseIterable, Sendable {
	/// This element is not from an FCPXML document or is unrecognized.
	case none

	// MARK: - Document Root
	/// The root `<fcpxml>` element.
	case fcpxml = "fcpxml"

	// MARK: - Import & Document Structure
	/// The `<import-options>` element (FCPXML 1.14+).
	case importOptions = "import-options"
	/// The `<option>` element (import option key/value).
	case option = "option"
	/// The `<resources>` element in an FCPXML document.
	case resourceList = "resources"
	/// The `<library>` element in an FCPXML document.
	case library = "library"
	/// The `<event>` element.
	case event = "event"
	/// The `<project>` element.
	case project = "project"

	// MARK: - Resource Elements
	/// The `<asset>` resource element.
	case assetResource = "asset"
	/// The `<format>` resource element.
	case formatResource = "format"
	/// The `<media>` resource element (multicam or compound determined by first child).
	case mediaResource = "media"
	/// The `<effect>` resource element.
	case effectResource = "effect"
	/// The `<locator>` resource element (FCPXML 1.14+).
	case locator = "locator"
	/// Media resource whose first child is `<multicam>` (inferred from structure). Use `tagName` for the actual tag `"media"`.
	case multicamResource = "media@multicam"
	/// Media resource whose first child is `<sequence>` (inferred from structure). Use `tagName` for the actual tag `"media"`.
	case compoundResource = "media@sequence"
	/// The `<media-rep>` element (asset media representation).
	case mediaRep = "media-rep"
	/// The `<metadata>` container element.
	case metadata = "metadata"
	/// The `<md>` metadata key/value element.
	case md = "md"
	/// The `<bookmark>` element.
	case bookmark = "bookmark"

	// MARK: - Animation & Parameters
	/// The `<fadeIn>` element.
	case fadeIn = "fadeIn"
	/// The `<fadeOut>` element.
	case fadeOut = "fadeOut"
	/// The `<keyframeAnimation>` element.
	case keyframeAnimation = "keyframeAnimation"
	/// The `<keyframe>` element.
	case keyframe = "keyframe"
	/// The `<mute>` element.
	case mute = "mute"
	/// The `<param>` element (parameter key/value or animation).
	case param = "param"
	/// The `<data>` element (PCDATA content).
	case data = "data"

	// MARK: - Adjust / Transform Elements
	/// The `<crop-rect>` element.
	case cropRect = "crop-rect"
	/// The `<trim-rect>` element.
	case trimRect = "trim-rect"
	/// The `<pan-rect>` element.
	case panRect = "pan-rect"
	/// The `<adjust-crop>` element.
	case adjustCrop = "adjust-crop"
	/// The `<adjust-corners>` element.
	case adjustCorners = "adjust-corners"
	/// The `<adjust-conform>` element.
	case adjustConform = "adjust-conform"
	/// The `<adjust-transform>` element.
	case adjustTransform = "adjust-transform"
	/// The `<adjust-blend>` element.
	case adjustBlend = "adjust-blend"
	/// The `<adjust-stabilization>` element.
	case adjustStabilization = "adjust-stabilization"
	/// The `<adjust-rollingShutter>` element.
	case adjustRollingShutter = "adjust-rollingShutter"
	/// The `<adjust-360-transform>` element.
	case adjust360Transform = "adjust-360-transform"
	/// The `<adjust-reorient>` element.
	case adjustReorient = "adjust-reorient"
	/// The `<adjust-orientation>` element.
	case adjustOrientation = "adjust-orientation"
	/// The `<adjust-cinematic>` element.
	case adjustCinematic = "adjust-cinematic"
	/// The `<adjust-colorConform>` element.
	case adjustColorConform = "adjust-colorConform"
	/// The `<adjust-stereo-3D>` element.
	case adjustStereo3D = "adjust-stereo-3D"
	/// The `<adjust-loudness>` element.
	case adjustLoudness = "adjust-loudness"
	/// The `<adjust-noiseReduction>` element.
	case adjustNoiseReduction = "adjust-noiseReduction"
	/// The `<adjust-humReduction>` element.
	case adjustHumReduction = "adjust-humReduction"
	/// The `<adjust-EQ>` element.
	case adjustEQ = "adjust-EQ"
	/// The `<adjust-matchEQ>` element.
	case adjustMatchEQ = "adjust-matchEQ"
	/// The `<adjust-voiceIsolation>` element.
	case adjustVoiceIsolation = "adjust-voiceIsolation"
	/// The `<adjust-volume>` element.
	case adjustVolume = "adjust-volume"
	/// The `<adjust-panner>` element.
	case adjustPanner = "adjust-panner"

	// MARK: - Tracking
	/// The `<tracking-shape>` element.
	case trackingShape = "tracking-shape"
	/// The `<object-tracker>` element.
	case objectTracker = "object-tracker"

	// MARK: - Audio / Video Sources
	/// The `<audio-channel-source>` element.
	case audioChannelSource = "audio-channel-source"
	/// The `<audio-role-source>` element.
	case audioRoleSource = "audio-role-source"

	// MARK: - Story & Sequence Elements
	/// The `<sequence>` element.
	case sequence = "sequence"
	/// The `<spine>` element (primary or secondary storyline).
	case spine = "spine"
	/// The `<multicam>` element (inside media resource).
	case multicam = "multicam"
	/// The `<mc-angle>` element.
	case mcAngle = "mc-angle"
	/// The `<mc-clip>` multicam clip element.
	case multicamClip = "mc-clip"
	/// The `<mc-source>` element (multicam angle source).
	case mcSource = "mc-source"
	/// The `<clip>` element (video/audio clip).
	case clip = "clip"
	/// The `<ref-clip>` compound/reference clip element.
	case compoundClip = "ref-clip"
	/// The `<sync-clip>` synchronized clip element (FCPXML v1.6).
	case synchronizedClip = "sync-clip"
	/// The `<sync-source>` element.
	case syncSource = "sync-source"
	/// The `<asset-clip>` element (FCPXML v1.6).
	case assetClip = "asset-clip"
	/// The `<audio>` element.
	case audio = "audio"
	/// The `<video>` element.
	case video = "video"
	/// The `<live-drawing>` element (FCPXML 1.14+).
	case liveDrawing = "live-drawing"
	/// The `<audition>` element.
	case audition = "audition"
	/// The `<caption>` element (FCPXML v1.8).
	case caption = "caption"
	/// The `<gap>` element.
	case gap = "gap"
	/// The `<title>` element.
	case title = "title"
	/// The `<transition>` element.
	case transition = "transition"

	// MARK: - Text Elements
	/// The `<text>` element.
	case text = "text"
	/// The `<text-style-def>` element.
	case textStyleDef = "text-style-def"
	/// The `<text-style>` element.
	case textStyle = "text-style"

	// MARK: - Filters
	/// The `<filter-video>` element.
	case filterVideo = "filter-video"
	/// The `<filter-video-mask>` element.
	case filterVideoMask = "filter-video-mask"
	/// The `<mask-shape>` element.
	case maskShape = "mask-shape"
	/// The `<mask-isolation>` element.
	case maskIsolation = "mask-isolation"
	/// The `<filter-audio>` element.
	case filterAudio = "filter-audio"

	// MARK: - Time
	/// The `<conform-rate>` element.
	case conformRate = "conform-rate"
	/// The `<timeMap>` element.
	case timeMap = "timeMap"
	/// The `<timept>` element (time map point).
	case timept = "timept"

	// MARK: - Markers & Annotations
	/// The `<marker>` element.
	case marker = "marker"
	/// The `<rating>` element.
	case rating = "rating"
	/// The `<keyword>` element.
	case keyword = "keyword"
	/// The `<analysis-marker>` element.
	case analysisMarker = "analysis-marker"
	/// The `<hidden-clip-marker>` element.
	case hiddenClipMarker = "hidden-clip-marker"
	/// The `<chapter-marker>` element.
	case chapterMarker = "chapter-marker"
	/// The `<note>` element.
	case note = "note"

	// MARK: - Collections (Smart Collections & Folders)
	/// The `<keyword-collection>` element.
	case keywordCollection = "keyword-collection"
	/// The `<collection-folder>` element.
	case folder = "collection-folder"
	/// The `<smart-collection>` element.
	case smartCollection = "smart-collection"
	/// The `<match-text>` element (smart collection rule).
	case matchText = "match-text"
	/// The `<match-ratings>` element.
	case matchRatings = "match-ratings"
	/// The `<match-media>` element.
	case matchMedia = "match-media"
	/// The `<match-clip>` element.
	case matchClip = "match-clip"
	/// The `<match-stabilization>` element.
	case matchStabilization = "match-stabilization"
	/// The `<match-keywords>` element.
	case matchKeywords = "match-keywords"
	/// The `<keyword-name>` element.
	case keywordName = "keyword-name"
	/// The `<match-shot>` element.
	case matchShot = "match-shot"
	/// The `<shot-type>` element.
	case shotType = "shot-type"
	/// The `<stabilization-type>` element.
	case stabilizationType = "stabilization-type"
	/// The `<match-property>` element.
	case matchProperty = "match-property"
	/// The `<match-time>` element.
	case matchTime = "match-time"
	/// The `<match-timeRange>` element.
	case matchTimeRange = "match-timeRange"
	/// The `<match-roles>` element.
	case matchRoles = "match-roles"
	/// The `<role>` element (within match-roles).
	case role = "role"
	/// The `<match-usage>` element.
	case matchUsage = "match-usage"
	/// The `<match-representation>` element.
	case matchRepresentation = "match-representation"
	/// The `<match-markers>` element.
	case matchMarkers = "match-markers"
	/// The `<match-analysis-type>` element.
	case matchAnalysisType = "match-analysis-type"

	// MARK: - Generic / Reserved
	/// The `<reserved>` element.
	case reserved = "reserved"
	/// The `<array>` element (metadata array).
	case array = "array"
	/// The `<string>` element (metadata string).
	case string = "string"

	// MARK: - Public API

	/// The XML tag name for this element type. For inferred types (e.g. multicamResource), returns the underlying tag.
	public var tagName: String {
		switch self {
		case .none: return ""
		case .multicamResource: return "media"
		case .compoundResource: return "media"
		default: return rawValue
		}
	}

	/// Whether this type is inferred from structure (e.g. media + first child) rather than a direct tag match.
	public var isInferred: Bool {
		self == .multicamResource || self == .compoundResource
	}
}
