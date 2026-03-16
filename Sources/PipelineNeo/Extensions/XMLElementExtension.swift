//
//  XMLElementExtension.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	PNXMLElement extensions for FCPXML element parsing and manipulation.
//

import Foundation
import CoreMedia
import SwiftExtensions

#if canImport(AppKit)
import AppKit
#endif

#if canImport(Logging)
import Logging
#endif


// MARK: - Safe Attribute Helper

extension PNXMLElement {
	/// Adds an attribute to this element safely.
	/// Delegates to the protocol's `addAttribute(name:value:)` method.
	public func addSafeAttribute(name: String, value: String) {
		addAttribute(name: name, value: value)
	}
}

// MARK: - XMLELEMENT EXTENSION -
extension PNXMLElement {
	
	// MARK: - Creating FCPXML Element Objects
	
	
	/// Creates a new event FCPXML element.
	///
	/// - Parameter name: The name of the event in Final Cut Pro X.
	/// - Returns: An element of the event.
	public func fcpxEvent(name: String) -> any PNXMLElement {
		let element = PNXMLDefaultFactory().makeElement(name: "event")
		element.fcpxName = name
		return element
	}

	
	/// Creates a new event FCPXML element and adds items to it.
	///
	/// - Parameters:
	///   - name: The name of the event in Final Cut Pro X.
	///   - items: Items to add to the event.
	/// - Returns: An element of the event.
	public func fcpxEvent(name: String, items: [any PNXMLElement]) -> any PNXMLElement {
		let element = self.fcpxEvent(name: name)
		do {
			try element.addToEvent(items: items)
		} catch {
			return element
		}
		return element
	}
	
	
	/// Creates a new project FCPXML element and adds clips to it.
	///
	/// - Parameters:
	///   - name: The name of the project in Final Cut Pro X.
	///   - formatRef: The reference ID for the format resource that matches this project.
	///   - duration: The duration of the clip as a CMTime value.
	///   - tcStart: The starting timecode of the project timeline as a CMTime value.
	///   - tcFormat: The TimecodeFormat enum value describing whether the project timecode is drop-frame or non-drop-frame.
	///   - audioLayout: The project audio channel layout as an AudioLayout enum value.
	///   - audioRate: The project audio sampling rate as an AudioRate enum value.
	///   - renderColorSpace: The project render color space as a RenderColorSpace enum value.
	///   - clips: Clip elements to add to the timeline of the project.
	/// - Returns: The element of the project.
	public func fcpxProject(name: String, formatRef: String, duration: CMTime, tcStart: CMTime, tcFormat: TimecodeFormat, audioLayout: AudioLayout, audioRate: AudioRate, renderColorSpace: RenderColorSpace, clips: [any PNXMLElement]) -> any PNXMLElement {

		let element = PNXMLDefaultFactory().makeElement(name: "project")
		element.fcpxName = name

		let sequence = PNXMLDefaultFactory().makeElement(name: "sequence")
		sequence.fcpxFormatRef = formatRef
		sequence.fcpxDuration = duration
		sequence.fcpxTCStart = tcStart
		sequence.fcpxTCFormat = tcFormat
		sequence.fcpxAudioLayout = audioLayout
		sequence.fcpxAudioRate = audioRate
		sequence.fcpxRenderColorSpace = renderColorSpace

		let spine = PNXMLDefaultFactory().makeElement(name: "spine")
		for clip in clips {
			spine.addChild(clip)
		}
		
		sequence.addChild(spine)
		element.addChild(sequence)
		
		return element
		
	}
	
	
	/// Creates a new ref-clip FCPXML element
	///
	/// - Parameters:
	///   - name: The name of the clip.
	///   - ref: The reference ID for the resource that this clip refers to.
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - duration: The duration of the clip as a CMTime value.
	///   - start: The start time of the clip's local timeline as a CMTime value.
	///   - useAudioSubroles: A boolean value indicating if the clip's audio subroles are accessible.
	/// - Returns: An element of the ref-clip.
	public func fcpxCompoundClip(name: String, ref: String, offset: CMTime?, duration: CMTime, start: CMTime?, useAudioSubroles: Bool) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "ref-clip")
		
		element.fcpxName = name
		element.fcpxRef = ref
		element.fcpxOffset = offset
		element.fcpxDuration = duration
		element.fcpxStart = start
		
		if useAudioSubroles {
			element.setElementAttribute("useAudioSubroles", value: "1")
		} else {
			element.setElementAttribute("useAudioSubroles", value: "0")
		}
		
		return element
	}
	
	
	
	/// Creates a new FCPXML multicam reference element.
	///
	/// - Parameters:
	///   - name: The name of the resource.
	///   - id: The unique reference ID of this resource.
	///   - formatRef: The reference ID of the format that this resource uses.
	///   - tcStart: The starting timecode value of this resource.
	///   - tcFormat: The timecode format as a TimecodeFormat enumeration value.
	///   - renderColorSpace: The color space of this multicam as a RenderColorSpace enumeration value.
	///   - angles: The mc-angle elements to embed in this multicam resource.
	/// - Returns: An element of the multicam <media> resource.
	public func fcpxMulticamResource(name: String, id: String, formatRef: String, tcStart: CMTime?, tcFormat: TimecodeFormat, renderColorSpace: RenderColorSpace, angles: [any PNXMLElement]) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "media")
		
		element.fcpxName = name
		element.fcpxID = id
		
		let multicamElement = PNXMLDefaultFactory().makeElement(name: "multicam")
		
		multicamElement.fcpxFormatRef = formatRef
		multicamElement.fcpxRenderColorSpace = renderColorSpace
		multicamElement.fcpxTCStart = tcStart
		multicamElement.fcpxTCFormat = tcFormat
		
		angles.forEach { (angle) in
			multicamElement.addChild(angle)
		}
		
		element.addChild(multicamElement)
		
		return element
	}
	
	
	/// Creates a new multicam event clip element.
	///
	/// - Parameters:
	///   - name: The name of the clip.
	///   - refID: The reference ID.
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - duration: The duration of the clip as a CMTime value.
	///   - mcSources: An array of mc-source elements to place in this element.
	/// - Returns: An element of the multicam <mc-clip> resource.
	public func fcpxMulticamClip(name: String, refID: String, offset: CMTime?, start: CMTime?, duration: CMTime, mcSources: [any PNXMLElement]) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "mc-clip")
		
		element.fcpxName = name
		element.fcpxRef = refID
		element.fcpxOffset = offset
		element.fcpxStart = start
		element.fcpxDuration = duration
		
		mcSources.forEach { (source) in
			element.addChild(source)
		}
		
		return element
	}
	
	
	
	/// Creates a new secondary storyline element.
	///
	/// - Parameters:
	///   - lane: The lane for the secondary storyline as an Int value.
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - formatRef: The reference ID of the format that this resource uses.
	///   - clips: An array of clip elements to be placed inside the secondary storyline.
	/// - Returns: An element of the secondary storyline <spine> element.
	public func fcpxSecondaryStoryline(lane: Int, offset: CMTime, formatRef: String?, clips: [any PNXMLElement]) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "spine")
		
		element.fcpxLane = lane
		element.fcpxOffset = offset
		element.fcpxFormatRef = formatRef
		
		clips.forEach { (clip) in
			element.addChild(clip)
		}
		
		return element
	}
	
	
	/// Creates a new gap to be used in a timeline.
	///
	/// - Parameters:
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - duration: The duration of the clip as a CMTime value.
	///   - start: The start time of the clip's local timeline as a CMTime value.
	/// - Returns: An element of the gap.
	public func fcpxGap(offset: CMTime?, duration: CMTime, start: CMTime?) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "gap")
		
		element.fcpxOffset = offset
		element.fcpxDuration = duration
		element.fcpxStart = start
		
		return element
	}
	
	
	#if canImport(AppKit)
	/// Creates a new title to be used in a timeline.
	/// - Note: The font, fontSize, fontFace, fontColor, strokeColor, strokeWidth, shadowColor, shadowDistance, shadowAngle, shadowBlurRadius, and alignment properties affect the text style only if the newTextStyle property is true.
	///
	/// - Parameters:
	///   - titleName: The name of the title clip on the timeline.
	///   - lane: The preferred timeline lane to place the clip into.
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - ref: The reference ID for the title effect resource that this clip refers to.
	///   - duration: The duration of the clip as a CMTime value.
	///   - start: The start time of the clip's local timeline as a CMTime value.
	///   - role: The role assigned to the clip.
	///   - titleText: The text displayed by this title clip.
	///   - textStyleID: The ID to assign to a newly generated text style definition or the ID to reference for an existing text style definition.
	///   - newTextStyle: True if this title clip should contain a newly generated text style definition.
	///   - font: The font family name to use for the title text.
	///   - fontSize: The font size.
	///   - fontFace: The font face.
	///   - fontColor: The color of the font.
	///   - strokeColor: The color of the stroke used on the title text.
	///   - strokeWidth: The width of the stroke.
	///   - shadowColor: The color of the shadow used underneath the title text.
	///   - shadowDistance: The distance of the shadow from the title text.
	///   - shadowAngle: The angle of the shadow offset.
	///   - shadowBlurRadius: The blur radius of the shadow.
	///   - alignment: The text paragraph alignment.
	///   - xPosition: The X position of the text on the screen.
	///   - yPosition: The Y position of the text on the screen.
	/// - Returns: An element of the title, which will contain the text style definition, if specified.
	public func fcpxTitle(titleName: String, lane: Int?, offset: CMTime, ref: String, duration: CMTime, start: CMTime, role: String?, titleText: String, textStyleID: Int, newTextStyle: Bool, font: String = "Helvetica", fontSize: CGFloat = 62, fontFace: String = "Regular", fontColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), strokeColor: NSColor? = nil, strokeWidth: Float = 2.0, shadowColor: NSColor? = nil, shadowDistance: Float = 5.0, shadowAngle: Float = 315.0, shadowBlurRadius: Float = 1.0, alignment: TextAlignment = TextAlignment.center, xPosition: Float = 0, yPosition: Float = 0) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "title")
		
		element.fcpxName = titleName
		element.fcpxLane = lane
		element.fcpxOffset = offset
		element.fcpxRef = ref
		element.fcpxDuration = duration
		element.fcpxStart = start
		element.fcpxRole = role
		
		let text = PNXMLDefaultFactory().makeElement(name: "text")
		let textTextStyle = PNXMLDefaultFactory().makeElement(name: "text-style", stringValue: titleText)
		
		
		// Add the text content and its style
		textTextStyle.fcpxRef = "ts\(textStyleID)"  // Reference the new text style definition reference number
		
		text.addChild(textTextStyle)
		element.addChild(text)
		
		// Text Style Definition
		if newTextStyle == true {  // If a new text style definition hasn't been created yet
			
			let textStyleDef = PNXMLDefaultFactory().makeElement(name: "text-style-def")
			
			textStyleDef.fcpxID = "ts\(textStyleID)"
			
			let textStyleDefTextStyle = PNXMLDefaultFactory().makeElement(name: "text-style")
			
			textStyleDefTextStyle.setElementAttribute("font", value: font)
			textStyleDefTextStyle.setElementAttribute("fontSize", value: String(describing: fontSize))
			textStyleDefTextStyle.setElementAttribute("fontFace", value: fontFace)
			textStyleDefTextStyle.setElementAttribute("fontColor", value: "\(fontColor.redComponent) \(fontColor.greenComponent) \(fontColor.blueComponent) \(fontColor.alphaComponent)")
			
			if let strokeColor = strokeColor {
				
				textStyleDefTextStyle.setElementAttribute("strokeColor", value: "\(strokeColor.redComponent) \(strokeColor.greenComponent) \(strokeColor.blueComponent) \(strokeColor.alphaComponent)")
				textStyleDefTextStyle.setElementAttribute("strokeWidth", value: String(strokeWidth))
			}
			
			if let shadowColor = shadowColor {
				
				textStyleDefTextStyle.setElementAttribute("shadowColor", value: "\(shadowColor.redComponent) \(shadowColor.greenComponent) \(shadowColor.blueComponent) \(shadowColor.alphaComponent)")
				textStyleDefTextStyle.setElementAttribute("shadowOffset", value: "\(shadowDistance) \(shadowAngle)")
				textStyleDefTextStyle.setElementAttribute("shadowBlurRadius", value: String(shadowBlurRadius))
			}
			
			textStyleDefTextStyle.setElementAttribute("alignment", value: alignment.rawValue)
			
			textStyleDef.addChild(textStyleDefTextStyle)
			
			element.addChild(textStyleDef)
		}
		
		// Add the transform
		let adjustTransform = PNXMLDefaultFactory().makeElement(name: "adjust-transform")
		
		adjustTransform.setElementAttribute("position", value: "\(xPosition) \(yPosition)")
		
		element.addChild(adjustTransform)
		
		return element
	}

	/// Creates a new caption to be used in a timeline.
	///
	/// - Parameters:
	///   - captionName: The name of the caption clip on the timeline.
	///   - lane: The preferred timeline lane to place the clip into.
	///   - offset: The clip's location in parent time as a CMTime value.
	///   - duration: The duration of the clip as a CMTime value.
	///   - start: The start time of the clip's local timeline as a CMTime value.
	///   - roleName: The role name assigned to the clip.
	///   - captionFormat: The format of the captions, either ITT or CEA-608, using the CaptionFormat enum.
	///   - language: The language of the caption text as a CaptionLanguage enum value.
	///   - captionText: The text displayed by this caption clip.
	///   - CEA_displayStyle: For CEA-608 captions, the display transition style of the text.
	///   - CEA_rollUpHeight: For CEA-608 captions using the roll-up display style, the number of rows to show concurrently. Valid values are 2 to 4.
	///   - CEA_xPosition: The starting X position of the text for CEA-608 captions. Valid values are 1 to 23.
	///   - CEA_yPosition: The starting Y position of the text for CEA-608 captions. Valid values are 1 to 15.
	///   - CEA_alignment: The alignment of the text for CEA-608 captions.
	///   - ITT_placement: The text placement for ITT captions.
	///   - textStyleID: The ID to assign to a newly generated text style definition or the ID to reference for an existing text style definition.
	///   - newTextStyle: True if this title clip should contain a newly generated text style definition.
	///   - bold: True if the text is styled bold.
	///   - italic: True if the text is styled italic.
	///   - underline: True if the text is styled underline.
	///   - fontColor: The color of the font as an NSColor value.
	///   - bgColor: The background color behind the text as an NSColor value. Includes alpha value for semi-transparent and transparent backgrounds for CEA-608 captions.
	/// - Returns: An element of the caption, which will contain the text style definition, if newTextStyle is true.
	public func fcpxCaption(captionName: String, lane: Int?, offset: CMTime, duration: CMTime, start: CMTime, roleName: String, captionFormat: CaptionFormat, language: CaptionLanguage, captionText: String, CEA_displayStyle: CEA608CaptionDisplayStyle?, CEA_rollUpHeight: Int?, CEA_xPosition: Int?, CEA_yPosition: Int?, CEA_alignment: CEA608CaptionAlignment?, ITT_placement: ITTCaptionPlacement?, textStyleID: Int, newTextStyle: Bool, bold: Bool, italic: Bool, underline: Bool, fontColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), bgColor: NSColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)) -> any PNXMLElement {
		
		let element = PNXMLDefaultFactory().makeElement(name: "caption")
		
		element.fcpxName = captionName
		element.fcpxLane = lane
		element.fcpxOffset = offset
		element.fcpxDuration = duration
		element.fcpxStart = start
		element.fcpxRole = "\(roleName)?captionFormat=\(captionFormat.rawValue).\(language.rawValue)"
		
		let text = PNXMLDefaultFactory().makeElement(name: "text")
		
		if captionFormat == .cea608 {
			text.fcpxCEACaptionDisplayStyle = CEA_displayStyle
			if CEA_displayStyle == CEA608CaptionDisplayStyle.rollUp {
				text.fcpxCEACaptionRollUpHeight = CEA_rollUpHeight
			}
			text.fcpxCEACaptionPositionX = CEA_xPosition
			text.fcpxCEACaptionPositionY = CEA_yPosition
			text.fcpxCEACaptionAlignment = CEA_alignment
		} else {
			text.fcpxITTCaptionPlacement = ITT_placement
		}
		
		let textTextStyle = PNXMLDefaultFactory().makeElement(name: "text-style", stringValue: captionText)
		
		
		// Add the text content and its style
		textTextStyle.fcpxRef = "ts\(textStyleID)"  // Reference the new text style definition reference number
		
		text.addChild(textTextStyle)
		element.addChild(text)
		
		// Text Style Definition
		if newTextStyle == true {  // If a new text style definition hasn't been created yet
			
			let textStyleDef = PNXMLDefaultFactory().makeElement(name: "text-style-def")
			
			textStyleDef.fcpxID = "ts\(textStyleID)"
			
			let textStyleDefTextStyle = PNXMLDefaultFactory().makeElement(name: "text-style")
			
			textStyleDefTextStyle.setElementAttribute("font", value: ".SF NS Text")
			textStyleDefTextStyle.setElementAttribute("fontSize", value: "13")
			
			textStyleDefTextStyle.setElementAttribute("fontColor", value: "\(fontColor.redComponent) \(fontColor.greenComponent) \(fontColor.blueComponent) \(fontColor.alphaComponent)")
			
			if bold == true {
				textStyleDefTextStyle.setElementAttribute("bold", value: "1")
			} else {
				textStyleDefTextStyle.removeAttribute(forName: "bold")
			}
			
			if italic == true {
				textStyleDefTextStyle.setElementAttribute("italic", value: "1")
			} else {
				textStyleDefTextStyle.removeAttribute(forName: "italic")
			}
			
			if underline == true {
				textStyleDefTextStyle.setElementAttribute("underline", value: "1")
			} else {
				textStyleDefTextStyle.removeAttribute(forName: "underline")
			}
			
			textStyleDefTextStyle.setElementAttribute("backgroundColor", value: "\(bgColor.redComponent) \(bgColor.greenComponent) \(bgColor.blueComponent) \(bgColor.alphaComponent)")
			
			textStyleDef.addChild(textStyleDefTextStyle)
			
			element.addChild(textStyleDef)
		}
		
		return element
	}
	#endif // canImport(AppKit)



	// MARK: - Properties for Attribute Nodes
	public var fcpxType: FCPXMLElementType {
		get {
			guard let elementName = self.name else {
				return FCPXMLElementType.none
			}
			
			// Structural inference: <media> with first child <multicam> or <sequence>
			if elementName == "media" {
				let firstChildName = self.childElements
					.first(where: { $0.name != nil })
					.flatMap(\.name)
				switch firstChildName {
				case "multicam": return .multicamResource
				case "sequence": return .compoundResource
				default: return .mediaResource
				}
			}

			if let type = FCPXMLElementType(rawValue: elementName) {
				// Skip rawValue "media@multicam" / "media@sequence" (structural-only)
				if type == .multicamResource || type == .compoundResource {
					return .none
				}
				return type
			}
			return .none
		}
	}
	
	
	public var fcpxName: String? {
		get {
			if let attributeString = getElementAttribute("name") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("name", value: value)
			} else {
				self.removeAttribute(forName: "name")
			}
		}
	}
	
	public var fcpxDuration: CMTime? {
		get {
			if let attributeString = getElementAttribute("duration") {
				return FCPXMLUtility.defaultForExtensions.cmTime(fromFCPXMLTime: attributeString)
			} else {
				return nil
			}
		} // Note: for compound/multicam resources or projects, should use the sequence element duration.
		
		set(value) {
			if let value = value {
				let valueAsString = FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime: value)
				setElementAttribute("duration", value: valueAsString)
			} else {
				self.removeAttribute(forName: "duration")
			}
		}
	}
	
	public var fcpxTCStart: CMTime? {
		get {
			if let attributeString = getElementAttribute("tcStart") {
				return FCPXMLUtility.defaultForExtensions.cmTime(fromFCPXMLTime: attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				let valueAsString = FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime: value)
				setElementAttribute("tcStart", value: valueAsString)
			} else {
				self.removeAttribute(forName: "tcStart")
			}
		}
	}
	
	public var fcpxStart: CMTime? {
		get {
			if let attributeString = getElementAttribute("start") {
				return FCPXMLUtility.defaultForExtensions.cmTime(fromFCPXMLTime: attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				let valueAsString = FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime: value)
				setElementAttribute("start", value: valueAsString)
			} else {
				self.removeAttribute(forName: "start")
			}
		}
	}
	
	
	/// If this element's fcpxStart property is nil, fcpxStartValue returns a CMTime value of zero. Otherwise, it returns the same value as fcpxStart. This property is used when you want the value of the "start" attribute whether or not it exists. Final Cut Pro X omits the "start" attribute when the element starts at 0.
	public var fcpxStartValue: CMTime {
		get {
			if let start = self.fcpxStart {
				return start
			} else {
				return CMTime.fcpxmlZero
			}
		}
	}
	
	public var fcpxOffset: CMTime? {
		get {
			if let attributeString = getElementAttribute("offset") {
				return FCPXMLUtility.defaultForExtensions.cmTime(fromFCPXMLTime: attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				let valueAsString = FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime: value)
				setElementAttribute("offset", value: valueAsString)
			} else {
				self.removeAttribute(forName: "offset")
			}
		}
	}
	
	public var fcpxTCFormat: TimecodeFormat? {
		get {
			if let attributeString = getElementAttribute("tcFormat") {
				switch attributeString {
				case TimecodeFormat.dropFrame.rawValue:
					return TimecodeFormat.dropFrame
				case TimecodeFormat.nonDropFrame.rawValue:
					return TimecodeFormat.nonDropFrame
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("tcFormat", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "tcFormat")
			}
		}
	}
	
	public var fcpxFormatRef: String? {
		get {
			if let attributeString = getElementAttribute("format") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("format", value: value)
			} else {
				self.removeAttribute(forName: "format")
			}
		}
	}
	
	public var fcpxRefOrID: String? { // Can be either a ref or an ID. Read-only.
		get {
			if let attributeString = getElementAttribute("ref") {
				return attributeString
			} else if let attributeString = getElementAttribute("id") {
				return attributeString
			} else {
				return nil
			}
		}
	}
	
	
	/// Returns and sets the "ref" attribute of an element. If the element fcpxType is FCPXMLElementType.clip, this will return or set its video or audio child element's "ref" attribute.
	public var fcpxRef: String? {
		get {
			
			if self.fcpxType == .clip {  // If the element type is "clip" then get the ref from a video or audio sub-element.
				return self.firstChildElement(named: "video")?.fcpxRef ?? self.firstChildElement(named: "audio")?.fcpxRef
			} else {
			
				if let attributeString = getElementAttribute("ref") {
					return attributeString
				} else {
					return nil
				}
			}
		}
		
		set(value) {
			if let value = value {
				
				if self.fcpxType == .clip {  // If the element type is "clip" then change the ref in a video or audio sub-element.
					let target = self.firstChildElement(named: "video") ?? self.firstChildElement(named: "audio")
					if let target = target {
						target.addAttribute(name: "ref", value: value)
					} else {
						setElementAttribute("ref", value: value)
					}
				} else {
				
					setElementAttribute("ref", value: value)
				}
				
			} else {
				
				if self.fcpxType == .clip {  // If the element type is "clip" then remove the ref from a video or audio sub-element.
					if let target = self.firstChildElement(named: "video") ?? self.firstChildElement(named: "audio") {
						target.removeAttribute(forName: "ref")
					} else {
						self.removeAttribute(forName: "ref")
					}
				} else {
					self.removeAttribute(forName: "ref")
				}
			}
		}
	}
	
	public var fcpxID: String? {
		get {
			if let attributeString = getElementAttribute("id") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("id", value: value)
			} else {
				self.removeAttribute(forName: "id")
			}
		}
	}
	
	
	/// This value indicates whether the clip is enabled or disabled. By default, the element attribute is not included in FCPXML exports when the clip is enabled.
	public var fcpxEnabled: Bool {
		get {
			if let attributeString = getElementAttribute("enabled") {
				if attributeString == "0" {
					return false
				} else {
					return true
				}
			} else {
				return true
			}
		}
		
		set(value) {
			if !value {
				setElementAttribute("enabled", value: "0")
			} else {
				setElementAttribute("enabled", value: "1")
			}
		}
	}
	
	public var fcpxRole: String? {
		get {
			if let attributeString = getElementAttribute("role") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("role", value: value)
			} else {
				self.removeAttribute(forName: "role")
			}
		}
	}
	
	public var fcpxLane: Int? {
		get {
			if let attributeString = getElementAttribute("lane") {
				return Int(attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("lane", value: String(value))
			} else {
				self.removeAttribute(forName: "lane")
			}
		}
	}
	
	public var fcpxNote: String? {
		get {
			if let attributeString = getElementAttribute("note") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("note", value: value)
			} else {
				self.removeAttribute(forName: "note")
			}
		}
	}
	
	public var fcpxValue: String? {
		get {
			if let attributeString = getElementAttribute("value") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("value", value: value)
			} else {
				self.removeAttribute(forName: "value")
			}
		}
	}
	
	public var fcpxSrc: URL? {
		get {
			if let attributeString = getElementAttribute("src") {
				return URL(string: attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("src", value: value.absoluteString)
			} else {
				self.removeAttribute(forName: "src")
			}
		}
	}
	
	public var fcpxFrameDuration: CMTime? {
		get {
			if let attributeString = getElementAttribute("frameDuration") {
				return FCPXMLUtility.defaultForExtensions.cmTime(fromFCPXMLTime: attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				let valueAsString = FCPXMLUtility.defaultForExtensions.fcpxmlTime(fromCMTime: value)
				setElementAttribute("frameDuration", value: valueAsString)
			} else {
				self.removeAttribute(forName: "frameDuration")
			}
		}
	}
	
	public var fcpxWidth: Int? {
		get {
			if let attributeString = getElementAttribute("width") {
				let attributeInt = Int(attributeString)
				if attributeInt != 0 {
					return Int(attributeString)
				} else {
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("width", value: value.description)
			} else {
				self.removeAttribute(forName: "width")
			}
		}
	}
	
	public var fcpxHeight: Int? {
		get {
			if let attributeString = getElementAttribute("height") {
				let attributeInt = Int(attributeString)
				if attributeInt != 0 {
					return Int(attributeString)
				} else {
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("height", value: value.description)
			} else {
				self.removeAttribute(forName: "height")
			}
		}
	}
	
	public var fcpxAudioLayout: AudioLayout? {
		get {
			if let attributeString = getElementAttribute("audioLayout") {
				switch attributeString {
				case AudioLayout.mono.rawValue:
					return AudioLayout.mono
				case AudioLayout.stereo.rawValue:
					return AudioLayout.stereo
				case AudioLayout.surround.rawValue:
					return AudioLayout.surround
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("audioLayout", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "audioLayout")
			}
		}
	}
	
	public var fcpxAudioRate: AudioRate? {
		get {
			if let attributeString = getElementAttribute("audioRate") {
				switch attributeString {
				case AudioRate.rate32kHz.rawValue:
					return AudioRate.rate32kHz
				case AudioRate.rate44_1kHz.rawValue:
					return AudioRate.rate44_1kHz
				case AudioRate.rate48kHz.rawValue:
					return AudioRate.rate48kHz
				case AudioRate.rate88_2kHz.rawValue:
					return AudioRate.rate88_2kHz
				case AudioRate.rate96kHz.rawValue:
					return AudioRate.rate96kHz
				case AudioRate.rate176_4kHz.rawValue:
					return AudioRate.rate176_4kHz
				case AudioRate.rate192kHz.rawValue:
					return AudioRate.rate192kHz
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("audioRate", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "audioRate")
			}
		}
	}
	
	public var fcpxRenderColorSpace: RenderColorSpace? {
		get {
			if let attributeString = getElementAttribute("renderColorSpace") {
				switch attributeString {
				case RenderColorSpace.rec601NTSC.rawValue:
					return RenderColorSpace.rec601NTSC
				case RenderColorSpace.rec601PAL.rawValue:
					return RenderColorSpace.rec601PAL
				case RenderColorSpace.rec709.rawValue:
					return RenderColorSpace.rec709
				case RenderColorSpace.rec2020.rawValue:
					return RenderColorSpace.rec2020

				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("renderColorSpace", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "renderColorSpace")
			}
		}
	}
	
	public var fcpxHasAudio: Bool? {
		get {
			if let attributeString = getElementAttribute("hasAudio") {
				if attributeString == "1" {
					return true
				} else {
					return false
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				if value == true {
					setElementAttribute("hasAudio", value: "1")
				} else {
					setElementAttribute("hasAudio", value: "0")
				}
			} else {
				self.removeAttribute(forName: "hasAudio")
			}
		}
	}
	
	public var fcpxHasVideo: Bool? {
		get {
			if let attributeString = getElementAttribute("hasVideo") {
				if attributeString == "1" {
					return true
				} else {
					return false
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				if value == true {
					setElementAttribute("hasVideo", value: "1")
				} else {
					setElementAttribute("hasVideo", value: "0")
				}
			} else {
				self.removeAttribute(forName: "hasVideo")
			}
		}
	}
	
	public var fcpxAngleID: String? {
		get {
			if let attributeString = getElementAttribute("angleID") {
				return attributeString
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("angleID", value: value)
			} else {
				self.removeAttribute(forName: "angleID")
			}
		}
	}
	
	
	/// The "srcEnable" attribute for "mc-source" multicam clip angles
	public var fcpxSrcEnable: MulticamSourceEnable? {
		get {
			if let attributeString = getElementAttribute("srcEnable") {
				switch attributeString {
				case MulticamSourceEnable.audio.rawValue:
					return MulticamSourceEnable.audio
				case MulticamSourceEnable.video.rawValue:
					return MulticamSourceEnable.video
				case MulticamSourceEnable.all.rawValue:
					return MulticamSourceEnable.all
				case MulticamSourceEnable.none.rawValue:
					return MulticamSourceEnable.none
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("srcEnable", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "srcEnable")
			}
		}
	}
	
	public var fcpxUID: String? {
		get {
			if let attributeString = getElementAttribute("uid") {
				return attributeString
			} else {
				return nil
			}
		}
        
        set(value) {
            if let value = value {
                setElementAttribute("uid", value: value)
            } else {
                self.removeAttribute(forName: "uid")
            }
        }
	}
	
	
	// MARK: - Timing Properties
	
	/// The start of this element on its parent timeline. For example, if this is a video clip on the primary storyline, this value would be the in point of the clip on the project timeline. If this is a clip on a secondary storyline, this value would be the in point of the clip on the secondary storyline's timeline.
	public var fcpxParentInPoint: CMTime? {
		get {
			guard let inPoint = self.fcpxOffset else {
				return nil
			}
			return inPoint
		}
		set(value) {
			if let value = value {
				self.fcpxOffset = value
			} else {
				self.fcpxOffset = nil
			}
		}
	}
	
	
	/// The end of this element on its parent timeline. For example, if this is a video clip on the primary storyline, this value would be the out point of the clip on the project timeline. If this is a clip on a secondary storyline, this value would be the out point of the clip on the secondary storyline's timeline.
	public var fcpxParentOutPoint: CMTime? {
		get {
			guard let inPoint = self.fcpxOffset else {
				return nil
			}
			guard let duration = self.fcpxDuration else {
				return nil
			}
			return CMTimeAdd(inPoint, duration)
		}
		
		set(value) {
			if let value = value {
				guard let inPoint = self.fcpxOffset else {
					self.fcpxDuration = nil
					return
				}
				let newDuration = CMTimeSubtract(value, inPoint)
				self.fcpxDuration = newDuration
				
			} else {
				self.fcpxDuration = nil
			}
		}
	}
	
	/// The start of this element's local timeline. For example, if this is a video clip, this value would be the in point of the clip's source footage.
	public var fcpxLocalInPoint: CMTime {
		get {
			return self.fcpxStartValue
		}
		set(value) {
			self.fcpxStart = value
		}
	}
	
	/// The end of this element's local timeline. For example, if this is a video clip, this value would be the out point of the clip's source footage. If this element has no duration, this property will return nil.
	public var fcpxLocalOutPoint: CMTime? {
		get {
			guard let duration = self.fcpxDuration else {
				return nil
			}
			return CMTimeAdd(self.fcpxStartValue, duration)
		}
		
		set(value) {
			if let value = value {
				guard let inPoint = self.fcpxStart else {
					self.fcpxDuration = nil
					return
				}
				let newDuration = CMTimeSubtract(value, inPoint)
				self.fcpxDuration = newDuration
				
			} else {
				self.fcpxDuration = nil
			}
		}
	}
	
	
	/// The start time of this element on the project timeline.
	public var fcpxTimelineInPoint: CMTime? {
		get {
			
			// If this element does not have an offset, it is not a clip element on the project timeline
			guard self.fcpxOffset != nil else {
				
				return nil
			}
			
			guard let parentElement = self.parentElement else {
				
				return nil
			}
			
			if parentElement.name == "spine" && parentElement.fcpxOffset == nil {  // This is a clip on the primary storyline.
				
				return self.fcpxOffset
				
			} else if parentElement.name == "spine" {  // This is a clip on a secondary storyline.
				
				let clipIn = self.fcpxOffset!
				
				guard let spineOffset = parentElement.fcpxOffset else {
					return nil
				}
				
				let secondaryStorylineIn = CMTimeAdd(clipIn, spineOffset)
				
				guard let primaryStorylineClip = parentElement.parentElement else {
					return nil
				}
				
				let inDifference = CMTimeSubtract(secondaryStorylineIn, primaryStorylineClip.fcpxLocalInPoint)
				
				guard let primaryStorylineClipIn = primaryStorylineClip.fcpxParentInPoint else {
					return nil
				}
				
				return CMTimeAdd(primaryStorylineClipIn, inDifference)
				
			} else {  // This is a connected clip.
				
				let clipIn = self.fcpxOffset!
				
				let startDifference = CMTimeSubtract(clipIn, parentElement.fcpxLocalInPoint)
				
				guard let clipParentStart = parentElement.fcpxParentInPoint else {
					return nil
				}
				
				return CMTimeAdd(clipParentStart, startDifference)
				
			}
		}
	}
	
	/// The end time of this element on the project timeline.
	public var fcpxTimelineOutPoint: CMTime? {
		get {
			
			// If this element does not have an offset, it is not a clip element on the project timeline
			guard self.fcpxOffset != nil else {
				return nil
			}
			
			guard let parentElement = self.parentElement else {
				return nil
			}
			
			if parentElement.name == "spine" && parentElement.fcpxOffset == nil {  // This is a clip on the primary storyline.
				
				return self.fcpxParentOutPoint
				
			} else if parentElement.name == "spine" {  // This is a clip on a secondary storyline.
				
				guard let clipOut = self.fcpxParentOutPoint else {
					return nil
				}
				
				guard let spineOffset = parentElement.fcpxOffset else {
					return nil
				}
				
				let secondaryStorylineOut = CMTimeAdd(clipOut, spineOffset)
				
				guard let primaryStorylineClip = parentElement.parentElement else {
					return nil
				}
				
				guard let primaryStorylineClipLocalOut = primaryStorylineClip.fcpxLocalOutPoint else {
					return nil
				}
				
				let outDifference = CMTimeSubtract(secondaryStorylineOut, primaryStorylineClipLocalOut)
				
				guard let primaryStorylineClipOut = primaryStorylineClip.fcpxParentOutPoint else {
					return nil
				}
				
				return CMTimeAdd(primaryStorylineClipOut, outDifference)
				
			} else {  // This is a connected clip.
				
				guard let clipOut = self.fcpxParentOutPoint else {
					return nil
				}
				
				let startDifference = CMTimeSubtract(clipOut, parentElement.fcpxLocalInPoint)
				
				guard let clipParentStart = parentElement.fcpxParentInPoint else {
					return nil
				}
				
				return CMTimeAdd(clipParentStart, startDifference)
				
			}
		}
	}
	
	// MARK: - Caption Element Properties
	
	/// The display style for CEA-608 formatted captions.
	public var fcpxCEACaptionDisplayStyle: CEA608CaptionDisplayStyle? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("display-style") {
				switch attributeString {
				case CEA608CaptionDisplayStyle.popOn.rawValue:
					return CEA608CaptionDisplayStyle.popOn
				case CEA608CaptionDisplayStyle.paintOn.rawValue:
					return CEA608CaptionDisplayStyle.paintOn
				case CEA608CaptionDisplayStyle.rollUp.rawValue:
					return CEA608CaptionDisplayStyle.rollUp
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("display-style", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "display-style")
			}
		}
	}
	
	/// The number of rows to show concurrently on the video when the CEA-608 display style is set to roll-up. Valid values are from 2 to 4.
	public var fcpxCEACaptionRollUpHeight: Int? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("roll-up-height") {
				return Int(attributeString)
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("roll-up-height", value: String(value))
			} else {
				self.removeAttribute(forName: "roll-up-height")
			}
		}
	}
	
	/// The X position for CEA-608 captions. Valid values are from 1 to 23. Setting this variable will retain the current Y value if it exists. If it does not, the Y value will default to 15.
	public var fcpxCEACaptionPositionX: Int? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("position") {
				let coordinates = Array(attributeString.split(separator: " "))
				guard let first = coordinates[safe: 0], let x = Int(first) else {
					return nil
				}
				return x
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				if let currentY = self.fcpxCEACaptionPositionY {
					setElementAttribute("position", value: "\(value) \(currentY)")
				} else {
					setElementAttribute("position", value: "\(value) 15")
				}
			} else {
				self.removeAttribute(forName: "position")
			}
		}
	}
	
	/// The Y position for CEA-608 captions. Valid values are from 1 to 15. Setting this variable will retain the current X value if it exists. If it does not, the X value will default to 1.
	public var fcpxCEACaptionPositionY: Int? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("position") {
				let coordinates = attributeString.split(separator: " ")
				guard coordinates.count == 2 else {
					return nil
				}
				return Int(coordinates[1])
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				if let currentX = self.fcpxCEACaptionPositionX {
					setElementAttribute("position", value: "\(currentX) \(value)")
				} else {
					setElementAttribute("position", value: "1 \(value)")
				}
			} else {
				self.removeAttribute(forName: "position")
			}
		}
	}
	
	/// The caption placement for ITT formatted captions.
	public var fcpxITTCaptionPlacement: ITTCaptionPlacement? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("placement") {
				switch attributeString {
				case ITTCaptionPlacement.top.rawValue:
					return ITTCaptionPlacement.top
				case ITTCaptionPlacement.bottom.rawValue:
					return ITTCaptionPlacement.bottom
				case ITTCaptionPlacement.left.rawValue:
					return ITTCaptionPlacement.left
				case ITTCaptionPlacement.right.rawValue:
					return ITTCaptionPlacement.right
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("placement", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "placement")
			}
		}
	}
	
	/// The alignment for CEA-608 formatted captions.
	public var fcpxCEACaptionAlignment: CEA608CaptionAlignment? {
		get {
			guard self.fcpxType == .text else {
				return nil
			}
			if let attributeString = getElementAttribute("alignment") {
				switch attributeString {
				case CEA608CaptionAlignment.left.rawValue:
					return CEA608CaptionAlignment.left
				case CEA608CaptionAlignment.center.rawValue:
					return CEA608CaptionAlignment.center
				case CEA608CaptionAlignment.right.rawValue:
					return CEA608CaptionAlignment.right
				default:
					return nil
				}
			} else {
				return nil
			}
		}
		
		set(value) {
			if let value = value {
				setElementAttribute("alignment", value: value.rawValue)
			} else {
				self.removeAttribute(forName: "alignment")
			}
		}
	}
	
	// MARK: - Element Identification
	
	/// True if this element is an event.
	public var isFCPXEvent: Bool {
		get {
			if self.name == "event" {
				return true
			} else {
				return false
			}
		}
	}
	
	/// True if this element is an item in an event, not a resource.
	public var isFCPXEventItem: Bool {
		get {
			if self.fcpxType == .assetClip ||
				self.fcpxType == .clip ||
				self.fcpxType == .multicamClip ||
				self.fcpxType == .compoundClip ||
				self.fcpxType == .synchronizedClip ||
				self.fcpxType == .project
			{
				return true
			} else {
				return false
			}
		}
	}
	
	/// True if this element is a resource, not an event item.
	public var isFCPXResource: Bool {
		get {
			if self.fcpxType == .assetResource ||
				self.fcpxType == .formatResource ||
				self.fcpxType == .mediaResource ||
				self.fcpxType == .multicamResource ||
				self.fcpxType == .compoundResource ||
				self.fcpxType == .effectResource ||
				self.fcpxType == .locator
			{
				return true
			} else {
				return false
			}
		}
	}
	
	/// True if this element can appear on a storyline.
	public var isFCPXStoryElement: Bool {
		get {
			if self.fcpxType == .assetClip ||
				self.fcpxType == .clip ||
				self.fcpxType == .video ||
				self.fcpxType == .audio ||
				self.fcpxType == .multicamClip ||
				self.fcpxType == .compoundClip ||
				self.fcpxType == .synchronizedClip ||
				self.fcpxType == .gap ||
				self.fcpxType == .transition ||
				self.fcpxType == .title ||
				self.fcpxType == .audition ||
				self.fcpxType == .liveDrawing
			{
				return true
			} else {
				return false
			}
		}
	}
	
	/// If this element is a story element or clip in a sequence, this property returns its location in the sequence.
	public var fcpxStoryElementLocation: StoryElementLocation? {
		get {
			
			guard self.isFCPXStoryElement == true else {
				return nil
			}
			
			guard let parent = self.parentElement else {
				return nil
			}
			
			if parent.fcpxType == .spine {
				
				guard let superParent = parent.parentElement else {
					return nil
				}
				
				if superParent.fcpxType == .sequence {
					// The clip is on a primary storyline
					return StoryElementLocation.primaryStoryline
				} else {
					// The clip is on a secondary storyline
					return StoryElementLocation.secondaryStoryline
				}
			} else if parent.fcpxType == .event {
				// The element is not a clip in a sequence.
				return nil
				
			} else {
				// The clip is attached to another clip
				return StoryElementLocation.attachedClip
			}
		}
	}
	
	
	// MARK: - Retrieving Related Elements
	
	/// If this is a project element, this returns its sequence element. Returns nil if there is no sequence element or if this is not a project element.
	public var fcpxProjectSequence: (any PNXMLElement)? {
		get {
			self.fcpxType == .project ? self.firstChildElement(named: "sequence") : nil
		}
	}

	/// If this is a project element, this returns the spine of the primary storyline. Returns nil if there is no spine or if this is not a project element.
	public var fcpxProjectSpine: (any PNXMLElement)? {
		get {
			guard self.fcpxType == .project, let sequence = self.fcpxProjectSequence else {
				return nil
			}
			return sequence.firstChildElement(named: "spine")
		}
	}

	/// If this is a project element, this returns the clips contained within the project. Returns an empty array if there are no clips or if this is not a valid project element.
	public var fcpxProjectClips: [any PNXMLElement] {
		get {
			if self.fcpxType == .project {

				guard let projectSequence = self.fcpxProjectSequence else {
					return []
				}

				return projectSequence.fcpxSequenceClips

			} else {
				return []
			}
		}
	}
	
	/// If this is a compound clip or compound resource element, this returns its resource's sequence element. Returns nil if there is no sequence element or if this is not a compound clip or resource element.
	public var fcpxCompoundResourceSequence: (any PNXMLElement)? {
		let resource: any PNXMLElement

		switch self.fcpxType {
		case .compoundClip:  // If this is a compound clip in a project timeline
			guard let res = self.fcpxResource else {
				return nil
			}
			resource = res

		case .compoundResource:  // If this is the resource of a compound clip
			resource = self

		default:
			return nil
		}

		return resource.firstChildElement(named: "sequence")
	}

	/// If this is a compound clip or compound resource element, this returns the spine of the primary storyline. Returns nil if there is no spine or if this is not a compound clip or resource element.
	public var fcpxCompoundResourceSpine: (any PNXMLElement)? {
		let resource: any PNXMLElement

		switch self.fcpxType {
		case .compoundClip:  // If this is a compound clip in a project timeline
			guard let res = self.fcpxResource else {
				return nil
			}
			resource = res

		case .compoundResource:  // If this is the resource of a compound clip
			resource = self

		default:
			return nil
		}

		guard let sequence = resource.firstChildElement(named: "sequence"),
		      let spine = sequence.firstChildElement(named: "spine") else {
			return nil
		}
		return spine
	}
	
	
	/// If this is a sequence element, this returns the clips contained within the primary storyline. Returns an empty array if there are no clips or if this is not a valid sequence element.
	public var fcpxSequenceClips: [any PNXMLElement] {
		get {

			guard self.name == "sequence" else {
				return []
			}

			guard let spine = self.firstChildElement(named: "spine") else {
				return []
			}

			var clips: [any PNXMLElement] = []
			for childElement in spine.childElements {
				if childElement.isFCPXStoryElement == true {
					clips.append(childElement)
				}
			}
			return clips

		}
	}
	
	/// If this is an event item, the event that contains it. Returns nil if it is not an event item.
	public var fcpxParentEvent: (any PNXMLElement)? {
		get {
			guard self.isFCPXEventItem == true else { // If this is a clip inside an event
				return nil
			}

			guard let parentNode = self.parent else {
				return nil
			}

			var current: any PNXMLElement = parentNode

			while current.name != "event" {
				// If the parent is the top of the document, return nil
				guard let nextParent = current.parent else {
					return nil
				}

				current = nextParent

			}
			return current
		}
	}
	
	
	/// If this is an event item, the element of its corresponding resource.
	public var fcpxResource: (any PNXMLElement)? {
		get {

			guard let referenceID = self.fcpxRef else {
				return nil
			}

			// Walk to root and find matching resource in the resources element
			guard let root = self.fcpRoot else {
				return nil
			}
			guard let resources = root.firstChildElement(named: "resources") else {
				return nil
			}
			return resources.childElements.first { $0.fcpxID == referenceID }
		}
	}
	
	/// An array of the annotation elements within this event item or resource.
	public var fcpxAnnotations: [any PNXMLElement] {
		get {
				var annotationElements: [any PNXMLElement] = []

				for subElement in self.childElements {

					if subElement.fcpxType == .keyword ||
						subElement.fcpxType == .rating ||
						subElement.fcpxType == .marker ||
						subElement.fcpxType == .chapterMarker ||
						subElement.fcpxType == .analysisMarker ||
						subElement.fcpxType == .hiddenClipMarker ||
						subElement.fcpxType == .note {

						annotationElements.append(subElement)
					}
				}

				return annotationElements
		}
	}
	
	
	
	/// An array of this element's metadata elements. Returns nil if this element is not a resource or event item.
	public var fcpxMetadata: [any PNXMLElement]? {
		
		guard self.isFCPXResource == true || self.isFCPXEventItem == true else {
			return nil
		}
		
		if self.isFCPXResource == true {
			
			switch self.fcpxType {
			case .multicamResource, .compoundResource:
				guard let sub = self.firstChildElement(named: "sequence") ?? self.firstChildElement(named: "multicam"),
				      let metadata = sub.firstChildElement(named: "metadata") else {
					return nil
				}
				return Array(metadata.elements(forName: "md"))
			default:
				guard let metadata = self.firstChildElement(named: "metadata") else {
					return []
				}
				return Array(metadata.elements(forName: "md"))
			}
			
		} else if self.isFCPXEventItem == true {
			guard let metadata = self.firstChildElement(named: "metadata") else {
				return []
			}
			return Array(metadata.elements(forName: "md"))
			
		} else {  // Not a resource or event item element
			
			return nil
		}
		
	}
	

	
	/// An array of mc-angle elements within a multicam media resource. Returns nil if this element is not a multicam media resource.
	public var fcpxMulticamAngles: [any PNXMLElement]? {
		get {
			guard self.fcpxType == FCPXMLElementType.multicamResource,
			      let multicam = self.firstChildElement(named: "multicam") else {
				return nil
			}
			return multicam.elements(forName: "mc-angle")
		}
	}
	
	
	/// Returns clips from an event that match this resource. If this method is called on an element that is not a resource, nil will be returned. If there are no matching clips in the event, an empty array will be returned.
	///
	/// - Parameter event: The event element to search.
	/// - Returns: An optional array of elements.
	public func referencingClips(inEvent event: any PNXMLElement) -> [any PNXMLElement]? {

		guard let resourceID = self.fcpxID else {
			return nil
		}

		let clips: [any PNXMLElement]
		do {
			clips = try event.eventClips(forResourceID: resourceID)
		} catch {
			return nil
		}

		return clips

	}
	
	// MARK: - Methods for FCPX Library Events
	
	/// Returns all items contained within this event. If this is not an event, the property will be nil. If the event is empty, the property will be an empty array.
	public var eventItems: [any PNXMLElement]? {
		get {
			guard self.fcpxType == .event else {
				return nil
			}

			return self.childElements
		}
	}
	
	
	/// Returns the projects contained within this event. If this is not an event, the property will be nil. If the event has no projects, the property will be an empty array.
	public var eventProjects: [any PNXMLElement]? {
		get {
			guard self.fcpxType == .event else {
				return nil
			}

			return self.childElements.filter { $0.fcpxType == .project }
		}
	}
	
	
	/// Returns the clips contained within this event, excluding the projects. If this is not an event, the property will be nil. If the event has no clips, the property will be an empty array.
	public var eventClips: [any PNXMLElement]? {
		get {
			guard self.fcpxType == .event else {
				return nil
			}

			let clipTypes: Set<FCPXMLElementType> = [.assetClip, .clip, .compoundClip, .multicamClip, .synchronizedClip]
			return self.childElements.filter { clipTypes.contains($0.fcpxType) }
		}
	}
	

	/// Returns all clips in an event that match the given resource ID. If this method is called on an element that is not an event, an error will be thrown. If there are no clips that match the resourceID, an empty array will be returned.
	///
	/// - Parameter resourceID: A string of the resourceID value.
	/// - Returns: An array of elements that refer to the matching clips. Note that multiple clips in an event can refer to a single resource ID.
	/// - Throws: An error if this element is not an event.
	public func eventClips(forResourceID resourceID: String) throws -> [any PNXMLElement] {

		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}

		var matchingClips: [any PNXMLElement] = []

		for clip in self.childElements {

			if clip.fcpxRef == resourceID {
				matchingClips.append(clip)
			}

		}

		return matchingClips
	}
	
	
	/// Searches for items in an event that match a given asset resource. This method will also search inside synchronized clips, multicams, and compound clips for matches, but not inside projects. If this element is not an event, the method will throw. Updated for FCPXML v1.6. ** NOTE: Currently only searches for matching video clips of all clip types.
	///
	/// - Parameter resource: The resource element to match with.
	/// - Returns: An array of elements of the event clip matching the asset.
	public func eventClips(containingResource resource: any PNXMLElement) throws -> [any PNXMLElement] {

		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}

		var matchingItems: [any PNXMLElement] = []

		guard let items = self.eventItems else {
			return matchingItems
		}

		// Helper: find resources from root
		let root = self.fcpRoot
		let resourcesElement = root?.firstChildElement(named: "resources")

		for item in items {

			switch item.fcpxType {

			case .assetClip:  // Check for matching regular clips

				if item.fcpxRef == resource.fcpxID { // Found regular clip
					matchingItems.append(item)

					debugLog("Matching asset clip found: \(item.fcpxName ?? "unnamed element")")
				}

			case .clip:  // Check for matching regular clips
				let videoElement = item.firstChildElement(named: "video")
				let audioElement = item.firstChildElement(named: "audio")
				let mediaElement = videoElement ?? audioElement
				guard let media = mediaElement, media.fcpxRef == resource.fcpxID else {
					continue
				}
				matchingItems.append(item)
				if videoElement != nil {
					debugLog("Matching video clip found: \(item.fcpxName ?? "unnamed element")")
				} else {
					debugLog("Matching audio clip found: \(item.fcpxName ?? "unnamed element")")
				}


			case .synchronizedClip:  // Check for matching synchronized clips

				for itemChildElement in item.childElements {

					// Find regular synchronized clips
					if itemChildElement.fcpxType == .assetClip || itemChildElement.fcpxType == .clip { // Normal synchronized clip

						if itemChildElement.fcpxRef == resource.fcpxID {  // Match found on a primary storyline clip
							debugLog("Matching synchronized clip found: \(item.fcpxName ?? "unnamed element")")

							matchingItems.append(item)

						} else {  // Check clips attached to this primary storyline clip

							for syncedClipChildElement in itemChildElement.childElements {

								if syncedClipChildElement.fcpxRef == resource.fcpxID {

									debugLog("Matching synchronized clip found: \(item.fcpxName ?? "unnamed element")")
									matchingItems.append(item)
								}
							}
						}

					} else if itemChildElement.fcpxType == .spine { // Found a synchronized clip with multiple clips inside
						// Handles sync-clip containing a spine with nested clips

						var foundMatch = false

						for spineChild in itemChildElement.childElements {

							for spineClipChildElement in spineChild.childElements {

								if spineClipChildElement.fcpxRef == resource.fcpxID {

									debugLog("Matching synchronized clip found: \(item.fcpxName ?? "unnamed element")")
									matchingItems.append(item)
									foundMatch = true
									break // Found match in this spineChild, no need to check further nested clips
								}
							}

							if foundMatch {
								break // Found match in spine, no need to check other spineChildren
							}
						}
					}
				}

			case .multicamClip:  // Check for matching multicam clips

				if item.fcpxRef == resource.fcpxID { // The asset ID matches this multicam so add it immediately to the matchingItems array.

					debugLog("Matching multicam found: \(item.fcpxName ?? "unnamed element")")
					matchingItems.append(item)

					continue

				} else {  // Search within the multicam for any asset matches

					// Scan list of multicams for the multicam asset that matches this event item
					let multicamResources = resourcesElement?.childElements.filter { $0.fcpxType == .multicamResource } ?? []

					for multicam in multicamResources {

						guard multicam.fcpxID == item.fcpxRef else { // This multicam asset matches the event item
							continue
						}

						// Get the <multicam> element within the <media> element
						guard let multicamElement = multicam.firstChildElement(named: "multicam") else {
							continue
						}
						let multicamAngles = multicamElement.elements(forName: "mc-angle")

						// See if there are any angles that match the asset
						for multicamAngle in multicamAngles {

							for multicamAngleChildElement in multicamAngle.childElements {

								guard multicamAngleChildElement.fcpxType == .assetClip || multicamAngleChildElement.fcpxType == .clip else {
									continue
								}

								if multicamAngleChildElement.fcpxRef == resource.fcpxID {

									debugLog("Matching multicam found: \(item.fcpxName ?? "unnamed element")")
									matchingItems.append(item)
									break
								}

							}


						}

					}
				}


			case .compoundClip:  // Check for matching compound clips

				// Use the reference to find the matching resource media
				// Check inside the media and see if the video references the matchingAsset
				let compoundResources = resourcesElement?.childElements.filter { $0.fcpxType == .compoundResource } ?? []

				for compound in compoundResources {
					if item.fcpxRef == compound.fcpxID {

						guard let sequence = compound.firstChildElement(named: "sequence"),
						  let spine = sequence.firstChildElement(named: "spine") else { continue }

						var foundMatchInCompound = false

						for childClipElement in spine.childElements {

							if childClipElement.fcpxRef == resource.fcpxID {  // Check primary storyline clip
								debugLog("Matching compound clip found: \(item.fcpxName ?? "unnamed element")")
								matchingItems.append(item)
								foundMatchInCompound = true
								break

							} else {  // Check clips attached to this primary storyline clip and secondary storylines

								for childElementAsXML in childClipElement.childElements {

									// Check if this is an attached clip (direct child clip)
									if childElementAsXML.fcpxRef == resource.fcpxID {
										debugLog("Matching compound clip found: \(item.fcpxName ?? "unnamed element")")
										matchingItems.append(item)
										foundMatchInCompound = true
										break
									}

									// Check if this is a secondary storyline (spine child)
									if childElementAsXML.fcpxType == .spine {

										for secondaryClipElement in childElementAsXML.childElements {

											if secondaryClipElement.fcpxRef == resource.fcpxID {
												debugLog("Matching compound clip found in secondary storyline: \(item.fcpxName ?? "unnamed element")")
												matchingItems.append(item)
												foundMatchInCompound = true
												break
											}

											// Also check nested clips within secondary storyline clips
											for nestedSecondaryClipElement in secondaryClipElement.childElements {

												if nestedSecondaryClipElement.fcpxRef == resource.fcpxID {
													debugLog("Matching compound clip found in nested secondary storyline clip: \(item.fcpxName ?? "unnamed element")")
													matchingItems.append(item)
													foundMatchInCompound = true
													break
												}
											}

											if foundMatchInCompound {
												break
											}
										}

										if foundMatchInCompound {
											break
										}
									}
								}

								if foundMatchInCompound {
									break // Found match, no need to check other primary storyline clips
								}

							}

						}

					}

				}

			default:
				continue

			} // End item type cases

		} // End item for-loop

		return matchingItems
	}
	

	
	/// Adds an item to this event. If this element is not an event, an error is thrown.
	///
	/// - Parameters:
	///   - item: The item to add.
	/// - Throws: FCPXMLElementError.notAnEvent if the element is not an event.
	public func addToEvent(item: any PNXMLElement) throws {

		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}

		self.addChild(item)

	}

	/// Adds multiple items to this event. If this element is not an event, an error is thrown.
	///
	/// - Parameters:
	///   - items: An array of items to add.
	/// - Throws: FCPXMLElementError.notAnEvent if the element is not an event.
	public func addToEvent(items: [any PNXMLElement]) throws {

		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}

		for item in items {
			self.addChild(item)
		}
	}
	
	
	/// Removes an item from this event. If this element is not an event, an error is thrown.
	///
	/// - Parameter itemIndex: The index of the child to remove.
	/// - Throws: FCPXMLElementError.notAnEvent if the element is not an event.
	public func removeFromEvent(itemIndex: Int) throws {
		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}
		
		self.removeChild(at: itemIndex)
	}
	
	/// Removes a group of items from this event. If this element is not an event, an error is thrown.
	///
	/// - Parameter itemIndexes: An array of the indexes of the elements to remove.
	/// - Throws: FCPXMLElementError.notAnEvent if the element is not an event.
	public func removeFromEvent(itemIndexes: [Int]) throws {
		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}
		
		for index in itemIndexes.sorted().reversed() {
			self.removeChild(at: index)
		}
	}
	
	
	/// Removes a group of items from this event. If this element is not an event, an error is thrown.
	///
	/// - Parameter items: An array of event item elements.
	/// - Throws: FCPXMLElementError.notAnEvent if the element is not an event.
	public func removeFromEvent(items: [any PNXMLElement]) throws {
		guard self.fcpxType == .event else {
			throw FCPXMLElementError.notAnEvent(elementName: self.name ?? "unnamed")
		}

		// Remove matching items by comparing xmlString (identity comparison fails with wrapper types)
		let itemXMLStrings = Set(items.map { $0.xmlString })
		self.removeChildren { child in
			itemXMLStrings.contains(child.xmlString)
		}
	}

	// MARK: - Methods for Event Clips
	
	/// Adds annotation elements to this item, maintaining the proper order of the DTD. Conforms to FCPXML DTD v1.6.
	///
	/// - Parameter annotationElements: The annotations to add as an array of elements.
	/// - Throws: Throws an error if an annotation cannot be added to this type of FCPXML element or if the element to add is not an annotation.
	public func addToClip(annotationElements elements: [any PNXMLElement]) throws {

		guard self.fcpxType == .project || self.fcpxType == .synchronizedClip || self.fcpxType == .compoundClip || self.fcpxType == .multicamClip || self.fcpxType == .assetClip || self.fcpxType == .clip else {
			throw FCPXMLElementError.notAnAnnotatableItem(elementName: self.name ?? "unnamed")
		}

		let postAnnotationNames: Set<String> = ["audio-role-source", "audio-channel-source", "filter-video", "filter-video-mask", "filter-audio", "metadata", "sync-source"]

		if let children = self.children {  // If there are children, insert the annotations at the appropriate point

			var insertIndex = 0

			for (idx, child) in children.enumerated() {
				// These elements should come AFTER annotation elements so if one is encountered, break the loop and use that as the insert point.
				if let childName = child.name, postAnnotationNames.contains(childName) {
					insertIndex = idx
					break
				}

				insertIndex = idx + 1
			}

			for element in elements {

				guard element.fcpxType == .note || element.fcpxType == .marker || element.fcpxType == .chapterMarker || element.fcpxType == .rating || element.fcpxType == .keyword || element.fcpxType == .analysisMarker || element.fcpxType == .hiddenClipMarker else {
					throw FCPXMLElementError.notAnAnnotation(elementName: element.name ?? "unnamed")
				}

				self.insertChild(element, at: insertIndex)
				insertIndex += 1
			}

		} else { // No children so just add to the clips.
			for element in elements {

				guard element.fcpxType == .note || element.fcpxType == .marker || element.fcpxType == .chapterMarker || element.fcpxType == .rating || element.fcpxType == .keyword || element.fcpxType == .analysisMarker || element.fcpxType == .hiddenClipMarker else {
					throw FCPXMLElementError.notAnAnnotation(elementName: element.name ?? "unnamed")
				}

				self.addChild(element)
			}
		}
	}
	
	
	// MARK: - Methods for Projects
	
	/// Returns an array of all roles used inside the project.
	///
	/// - Returns: An array of roles as String values.
	public func projectRoles() -> [String] {
		guard self.fcpxType == .project else {
			return []
		}
		
		var projectRoles = self.parseRoles(fromElement: self)
		
		let compoundClips = self.clips(forElementType: .compoundClip)
		
		var compoundClipRoles: [String] = []
		for clip in compoundClips {
			
			guard let resourceElement = clip.fcpxResource else {
				continue
			}
			
			let resourceElementRoles = self.parseRoles(fromElement: resourceElement)
			compoundClipRoles.append(contentsOf: resourceElementRoles)
		}
		
		for role in compoundClipRoles {
			if !projectRoles.contains(role) {
				projectRoles.append(role)
			}
		}
		
		return projectRoles
		
	}
	
	
	// MARK: - Retrieving Format Information
	
	/// Returns an element's associated format name, ID, frame duration, and frame size.
	///
	/// - Returns: A tuple with a formatID string, formatName string, frameDuration CMTime, and frameSize CGSize.
	public func formatValues() -> (formatID: String, formatName: String, frameDuration: CMTime?, frameSize: CGSize?)? {
		
		// Get the format's ID
		guard let formatID = self.formatID(forElement: self) else {
			debugLog("No format ID in the element.")
			return nil
		}
		
		// Get the format element
		guard let root = self.fcpRoot,
		      let resources = root.firstChildElement(named: "resources"),
		      let formatElement = resources.childElements.first(where: { $0.fcpxID == formatID }) else {
			debugLog("No format matching ID \(formatID).")
			return nil
		}
		
		// Get the format values from the element
		guard let values = self.formatValues(fromElement: formatElement) else {
			debugLog("Retrieving format values failed.")
			return nil
		}
		
		return values
		
	}
	

	/// Get's an element's corresponding format element ID. This function can obtain the format for resources, event clips, and projects.
	///
	/// - Parameter element: The element to search.
	/// - Returns: The element format's ID as a String, or nil if none is found.
	private func formatID(forElement element: any PNXMLElement) -> String? {

		switch element.fcpxType {
		case .assetResource, .assetClip, .clip, .synchronizedClip, .sequence:  // These elements will have the format reference ID in the top level element.

			return element.fcpxFormatRef

		case .project, .multicamResource, .compoundResource:  // These elements will have the format reference ID in the second level element.
			// Get the first child element (e.g. <sequence> or <multicam>)
			guard let firstChild = element.childElements.first else {
				return nil
			}

			return firstChild.fcpxFormatRef

		case .compoundClip, .multicamClip:  // These elements will have the format reference ID in their corresponding resource's second level element.

			guard let resource = element.fcpxResource else {
				return nil
			}

			// Get the formatID from the resource's second level element by running the resource through this method.
			let resourceFormatID = self.formatID(forElement: resource)

			return resourceFormatID

		default:
			return nil

		}

	}
	

	
	
	/// Takes a format resource element and returns its ID, name, frame duration, and frame size. When the format is FFVideoFormatRateUndefined, the frameDuration will be nil.
	///
	/// - Parameter element: The element of the format resource
	/// - Returns: A tuple with formatID string, formatName string, frameDuration CMTime, and frameSize CGSize. Or returns null of the element is not a format resource.
	private func formatValues(fromElement element: any PNXMLElement) -> (formatID: String, formatName: String, frameDuration: CMTime?, frameSize: CGSize?)? {
		
		guard let elementName = element.name,
			elementName == "format" else {
				return nil
		}
		
		var formatID = ""
		var formatName = ""
		var frameDuration: CMTime? = nil
		var frameSize: CGSize? = nil
		
		if let id = element.fcpxID {
			formatID = id
		}
		
		if let name = element.fcpxName {
			formatName = name
		}
		
		if let fd = element.fcpxFrameDuration {
			frameDuration = fd
		}
		
		if let w = element.fcpxWidth, let h = element.fcpxHeight {
			frameSize = CGSize(width: w, height: h)
		}
		
		return (formatID, formatName, frameDuration, frameSize)
	}
	
	
	// MARK: - Comparing Timing Between Clips
	
	/// Tests if this clip's in and out points include the given time value.
	///
	/// - Parameter time: A CMTime value
	/// - Returns: True if the time value is between the in and out points of the clip
	public func clipRangeIncludes(_ time: CMTime) -> Bool {
		
		guard let clipInPoint = self.fcpxParentInPoint else {
			return false
		}
		
		guard let clipOutPoint = self.fcpxParentOutPoint else {
			return false
		}
		
		if clipInPoint.seconds <= time.seconds && time.seconds <= clipOutPoint.seconds {
			
			return true
			
		} else {
			return false
		}
	}
	
	/// Tests if this clip's timing falls within the given in and out points.
	///
	/// - Parameters:
	///   - inPoint: The in point to test against.
	///   - outPoint: The out point to test against.
	/// - Returns: True if the clip's timing falls within the inPoint and outPoint values.
	public func clipRangeIsEnclosedBetween(_ inPoint: CMTime, outPoint: CMTime) -> Bool {
		guard let clipInPoint = self.fcpxParentInPoint else {
			return false
		}
		
		guard let clipOutPoint = self.fcpxParentOutPoint else {
			return false
		}
		
		if inPoint.seconds <= clipInPoint.seconds && clipOutPoint.seconds <= outPoint.seconds {
			return true
		} else {
			return false
		}
	}
	
	
	
	
	
	/// Returns whether the clip overlaps with a given time range specified by an in and out point.
	///
	/// - Parameters:
	///   - inPoint: The in point as a CMTime value.
	///   - outPoint: The out point as a CMTime value.
	/// - Returns: A tuple containing three boolean values. "Overlaps" indicates whether the clip overlaps at all with the in and out point range. "withClipInPoint" indicates whether the element's in point overlaps with the range. "withClipOutPoint" indicates whether the element's out point overlaps with the range.
	///
	/// - Example:\
	/// The following is a reference for how a clip could overlap. Below each case are resulting values for the "overlaps", "withClipInPoint", and "withClipOutPoint" tuple values.\
	/// `    [  comparisonClip ]         [ comparisonClip ]          [  comparisonClip  ]`\
	/// `[ clip1 ]         [ clip2 ]    [       clip       ]             [   clip   ]`\
	/// `(t,f,t)            (t,t,f)     (true, false, false)          (true, true, true)`\
	public func clipRangeOverlapsWith(_ inPoint: CMTime, outPoint: CMTime) -> (overlaps: Bool, withClipInPoint: Bool, withClipOutPoint: Bool) {
		
		var overlaps: Bool = false
		var withClipInPoint: Bool = false
		var withClipOutPoint: Bool = false
		
		guard let _ = self.fcpxParentInPoint else {
			return (overlaps, withClipInPoint, withClipOutPoint)
		}
		
		guard let _ = self.fcpxParentOutPoint else {
			return (overlaps, withClipInPoint, withClipOutPoint)
		}
		
		
		if self.clipRangeIsEnclosedBetween(inPoint, outPoint: outPoint) {
			
			overlaps = true
			withClipInPoint = true
			withClipOutPoint = true
			
		} else if self.clipRangeIncludes(inPoint) && self.clipRangeIncludes(outPoint) {
			
			overlaps = true
			withClipInPoint = false
			withClipOutPoint = false
			
		} else {
			
			if self.clipRangeIncludes(inPoint) {
				overlaps = true
				withClipOutPoint = true
			}
			
			if self.clipRangeIncludes(outPoint) {
				overlaps = true
				withClipInPoint = true
			}
		}
		
		return (overlaps, withClipInPoint, withClipOutPoint)
	}
	
	
	/// Returns child elements that fall within the specified in and out points.
	///
	/// - Parameters:
	///   - inPoint: The in point as a CMTime value.
	///   - outPoint: The out point as a CMTime value.
	///   - elementType: The element type. If nil, returns all matching child elements.
	/// - Returns: An array of tuples containing the element, whether it overlaps the in point, and whether it overlaps the out point.
	public func childElementsWithinRangeOf(_ inPoint: CMTime, outPoint: CMTime, elementType: FCPXMLElementType?) -> [(element: any PNXMLElement, overlapsInPoint: Bool, overlapsOutPoint: Bool)] {

		var elementsInRange: [(element: any PNXMLElement, overlapsInPoint: Bool, overlapsOutPoint: Bool)] = []

		var children: [any PNXMLElement] = []

		if elementType == nil { // If no type is specified

			children = self.childElements

		} else { // If a type is specified

			children = self.elements(forName: elementType!.rawValue)
		}

		// Check each child element for overlap with the specified time range
		// Note: Elements without timing attributes (offset/duration) will be silently skipped
		// as clipRangeOverlapsWith returns (false, false, false) when fcpxParentInPoint/OutPoint are nil
		for element in children {

			// Verify element has timing attributes before checking overlap
			guard element.fcpxOffset != nil, element.fcpxDuration != nil else {
				debugLog("Skipping element '\(element.fcpxName ?? "unnamed")' - missing timing attributes (offset or duration)")
				continue
			}

			let overlaps = element.clipRangeOverlapsWith(inPoint, outPoint: outPoint)

			if overlaps.overlaps == true {
				debugLog("\(element.fcpxName ?? "unnamed element") overlaps: inPoint=\(overlaps.withClipInPoint), outPoint=\(overlaps.withClipOutPoint)")

				elementsInRange.append((element: element, overlapsInPoint: overlaps.withClipInPoint, overlapsOutPoint: overlaps.withClipOutPoint))

			}

		}

		return elementsInRange
	}
	
	
	
	// MARK: - Miscellaneous
	
	/// The FCPXML document as a properly formatted string.
	public var fcpxmlString: String {
		// Use xmlString from the protocol which provides the element's XML representation
		return self.xmlString
	}
	
	
	/// Retrieves the URLs from the elements contained within this resource.
	///
	/// - Returns: An array of URLs.
	public func urls() -> [URL] {
		
		var URLs: [URL] = []
		
		// Get the references
		guard let references = self.allReferenceIDs() else {
			return []
		}
		
		// Get the reference and pull the URL
		let root = self.fcpRoot
		let resourcesElement = root?.firstChildElement(named: "resources")
		for ref in references {
			guard let resource = resourcesElement?.childElements.first(where: { $0.fcpxID == ref }) else {
				continue
			}
			
							let sourceParser = AttributeParserDelegate(element: resource, attribute: "src", inElementsWithName: nil)
			
					let values = sourceParser.values
		if values.count > 0 {
			for source in values {
					if let url = Foundation.URL(string: source) {
						URLs.append(url)
					}
				}
			}
		}
		
		return URLs
	}
	
	
	/// Searches this element and its sub-elements for references and returns them.
	///
	/// - Returns: The references as an array of strings, or nil if none found.
	public func allReferenceIDs() -> [String]? {
		let refParser = AttributeParserDelegate(element: self, attribute: "ref", inElementsWithName: nil)
				let references = refParser.values

		if references.count > 0 {
			return references
		} else {
			return nil
		}
	}
	
	
	/// Finds all sub-elements matching the given name, including within secondary storylines.
	///
	/// - Parameters:
	///   - name: The element name to match.
	///   - usingAbsoluteMatch: If true, names must match exactly; otherwise, partial matches are returned.
	/// - Returns: An array of matching elements.
	public func subelements(forName name: String, usingAbsoluteMatch: Bool) -> [any PNXMLElement] {
		
		return self.subelements(forName: name, inElement: self, usingAbsoluteMatch: usingAbsoluteMatch)
	}
	
	
	/// Recursively finds sub-elements matching the given name within the specified element.
	///
	/// - Parameters:
	///   - name: The name to match.
	///   - element: The element to recursively search.
	///   - usingAbsoluteMatch: If true, names must match exactly; otherwise, partial matches are returned.
	/// - Returns: An array of matching elements.
	private func subelements(forName name: String, inElement element: any PNXMLElement, usingAbsoluteMatch: Bool) -> [any PNXMLElement] {

		var matchingElements: [any PNXMLElement] = []

		for childElement in element.childElements {
			guard let childElementName = childElement.name else {
				continue
			}

			if usingAbsoluteMatch == true {

				if childElementName.uppercased() == name.uppercased() {

					matchingElements.append(childElement)

				}

			} else { // Looks for a match within the string

				if childElementName.uppercased().contains(name.uppercased()) == true {

					matchingElements.append(childElement)

				}
			}


			// Recurse through children
			if childElement.children != nil {

				let items = subelements(forName: name, inElement: childElement, usingAbsoluteMatch: usingAbsoluteMatch)

				matchingElements.append(contentsOf: items)
			}

		}

		return matchingElements

	}
	
	
	/// Returns all clips within this element and its sub-elements.
	///
	/// - Note: The clips in the resulting array are not ordered by document position.
	/// - Returns: An array of clip elements.
	public func clips() -> [any PNXMLElement] {

		let clipTypes: [FCPXMLElementType] = [.clip, .audio, .video, .gap, .transition, .title, .audition, .multicamClip, .compoundClip, .synchronizedClip, .assetClip, .liveDrawing]

		var matchingClips: [any PNXMLElement] = []

		for clipType in clipTypes {
			matchingClips.append(contentsOf: self.clips(forElementType: clipType))
		}

		return matchingClips
	}
	
	
	/// This function goes through the element and all its sub-elements, returning all clips that match the given FCPX clip name.
	///
	/// - Parameters:
	///   - fcpxName: A String of the clip name in FCPX to match with.
	///   - usingAbsoluteMatch: A boolean value of whether names must match absolutely or whether clip names containing the string will yield a match.
	/// - Returns: An array of matching clips as elements.
	public func clips(forFCPXName fcpxName: String, usingAbsoluteMatch: Bool) -> [any PNXMLElement] {
		
		let allClips = self.clips()
		
		var matchingClips: [any PNXMLElement] = []

		for clip in allClips {

			guard let clipName = clip.fcpxName else {
				continue
			}

			if usingAbsoluteMatch == true {

				if clipName.uppercased() == fcpxName.uppercased() {
					matchingClips.append(clip)
				}

			} else {

				if clipName.uppercased().contains(fcpxName.uppercased()) == true {
					matchingClips.append(clip)
				}
			}
		}

		return matchingClips
		
	}
	
	/// Finds clips matching the given element type within this element and its sub-elements.
	///
	/// - Parameter elementType: The FCPXML element type to match.
	/// - Returns: An array of matching clip elements.
	public func clips(forElementType elementType: FCPXMLElementType) -> [any PNXMLElement] {
		return self.clips(forElementType: elementType, inElement: self)
	}
	
	
	/// Recursively finds clips matching the given element type.
	///
	/// - Parameters:
	///   - elementType: The FCPXML element type to match.
	///   - element: The element to recursively search.
	/// - Returns: An array of matching clip elements.
	private func clips(forElementType elementType: FCPXMLElementType, inElement element: any PNXMLElement) -> [any PNXMLElement] {

		var matchingElements: [any PNXMLElement] = []

		for childElement in element.childElements {

			if let childElementName = childElement.name {

				if childElementName == elementType.rawValue {

					matchingElements.append(childElement)
				}

			}

			// Recurse through children
			if childElement.children != nil {

				let items = clips(forElementType: elementType, inElement: childElement)

				matchingElements.append(contentsOf: items)
			}

		}

		return matchingElements

	}
	
	
	
	
	
	// MARK: - Element Helper Properties and Methods
	public func getElementAttribute(_ name: String) -> String? {
		stringValue(forAttributeNamed: name)
	}
	
	
	public func setElementAttribute(_ name: String, value: String?) {

		if let value = value {

			self.addAttribute(name: name, value: value)

		} else {

			self.removeAttribute(forName: name)

		}

	}

	
	/// Returns the next sibling element in document order.
	///
	/// - Returns: An element or nil if there is no other element after the current one.
	public var nextElement: (any PNXMLElement)? {
		get {
			guard let parentEl = self.parent else {
				return nil
			}
			let siblings = parentEl.childElements
			guard let selfIndex = siblings.firstIndex(where: { $0 === self }) else {
				return nil
			}
			let nextIndex = siblings.index(after: selfIndex)
			guard nextIndex < siblings.endIndex else {
				return nil
			}
			return siblings[nextIndex]
		}
	}

	/// Returns all sub-elements of this element.
	///
	/// - Returns: An array of child elements.
	public func subElements() -> [any PNXMLElement] {
		return self.childElements
	}
    
    /// Returns the first sub-element with the given element name.
    ///
    /// - Parameter named: A string of the element name to match.
    /// - Returns: An element or nil if there was no match.
    public func subElement(named name: String) -> (any PNXMLElement)? {
        firstChildElement(named: name)
    }
	
	// parentElement: provided by PNXMLNode protocol default implementation

	/// Adds an element as a child to this element, placing it in proper order according to the DTD.
	///
	/// - Parameters:
	///   - element: The child element to insert.
	// Note: addChildConformingToDTD was removed (unimplemented stub).
	
	
	/// Converts a whitespace-only text value inside an element into a text node and inserts it as a child back into the element.
	///
	/// When text values consist of only whitespace characters, such as in title clips with adjusted kerning, Final Cut Pro X exports FCPXML files with the whitespace as is, not encoded into a valid XML whitespace character. This results in the XML parser ignoring the whitespace character and not initializing that into a node.
	///
	/// This method extracts the text value inside an _XML element string_, converts that into a text node, and inserts it back into the element.
	///
	/// For example, an element consisting of:
	/// ````
	/// <text-style ref="ts30"> </text-style>
	/// ````
	/// will have its single space character converted into a text node after being processed through this method.
	///
	/// - Note: If the element has a child node, the element will not be modified.
	public func convertWhitespaceText() {

		guard (self.children?.count ?? 0) == 0 else {
			return
		}

		guard let extractedText = self.extractTextFromXMLString(self.xmlString) else {
			return
		}

		// Set the string value directly on the element
		self.stringValue = extractedText

	}


	/// Extracts the text content inside an element's XML string representation.
	///
	/// When text values consist of only whitespace characters, such as in title clips with adjusted kerning, Final Cut Pro X exports FCPXML files with the whitespace as is, not encoded into a valid XML whitespace character. This results in the XML parser ignoring the whitespace character.
	///
	/// This function will extract the text value inside an _XML element string_.
	///
	/// For example, an element consisting of:
	/// ````
	/// <text-style ref="ts30"> </text-style>
	/// ````
	/// will return a single space character, which would normally be ignored when that XML string is read from a file.
	///
	/// - Parameter xmlString: A string representation of a single XML element.
	/// - Returns: The text content inside the element, or nil if none could be extracted.
	private func extractTextFromXMLString(_ xmlString: String) -> String? {
		// Find the text within the single element.

		guard let rangeOfEndTag = xmlString.range(of: "</") else {
			return nil
		}
		let beginning = xmlString.prefix(upTo: rangeOfEndTag.lowerBound)

		guard let rangeOfBeginningTag = beginning.range(of: ">") else {
			return nil
		}
		let text = beginning.suffix(from: rangeOfBeginningTag.upperBound)

		guard text != "" else {
			return nil
		}

		return String(text)
	}
	
	
	// MARK: - Parsing Methods
	
	/// Parses roles from the given element. This would typically be used on a project element.
	func parseRoles(fromElement element: any PNXMLElement) -> [String]{
		debugLog("Parsing Roles...")
		
		guard let data = element.xmlString.data(using: .utf8) else {
			debugLog("Error converting XML to Data")
			return []
		}
		let xmlParser = XMLParser(data: data)
		let parserDelegate = FCPXMLParserDelegate()
		xmlParser.delegate = parserDelegate
		
		// Parse the attributes using XMLParserDelegate
		xmlParser.parse()
		
		return parserDelegate.roles
		
	}

	// MARK: - Constants
	// Enum definitions moved to XMLElementExtensionTypes.swift.
	// Typealiases back into PNXMLElement are declared there.

#if canImport(Logging)
	private func debugLog(_ message: String) {
		_pnxmlElementLogger.debug("\(message)")
	}
#else
	private func debugLog(_ message: String) {
		print(message)
	}
#endif
}

#if canImport(Logging)
private let _pnxmlElementLogger = Logger(label: "PipelineNeo.PNXMLElement")
#endif
