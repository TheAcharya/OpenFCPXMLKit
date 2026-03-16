//
//  FCPXMLUtility.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Utility methods for FCPXML processing; single injection point for extension APIs.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Contains miscellaneous utility methods for processing FCPXML data with modern Swift concurrency support.
@available(macOS 12.0, *)
public final class FCPXMLUtility: Sendable {
	
	// MARK: - Dependencies

	private let parser: FCPXMLParsing & FCPXMLElementFiltering
	private let timecodeConverter: TimecodeConversion & FCPXMLTimeStringConversion & TimeConforming
	private let documentManager: XMLDocumentOperations & XMLElementOperations
	private let errorHandler: ErrorHandling
	private let logger: PipelineLogger
	private let cutDetector: CutDetection
	private let versionConverter: FCPXMLVersionConverting
	private let mediaExtractor: MediaExtraction
	private let semanticValidator: FCPXMLValidator
	private let dtdValidator: FCPXMLDTDValidator

	// MARK: - Initializing

	/// Initializer with dependency injection
	public init(
		parser: FCPXMLParsing & FCPXMLElementFiltering = FCPXMLParser(),
		timecodeConverter: TimecodeConversion & FCPXMLTimeStringConversion & TimeConforming = TimecodeConverter(),
		documentManager: XMLDocumentOperations & XMLElementOperations = XMLDocumentManager(),
		errorHandler: ErrorHandling = ErrorHandler(),
		cutDetector: CutDetection = CutDetector(),
		versionConverter: FCPXMLVersionConverting = FCPXMLVersionConverter(),
		mediaExtractor: MediaExtraction = MediaExtractor(),
		semanticValidator: FCPXMLValidator = FCPXMLValidator(),
		dtdValidator: FCPXMLDTDValidator = FCPXMLDTDValidator(),
		logger: PipelineLogger = NoOpPipelineLogger()
	) {
		self.parser = parser
		self.timecodeConverter = timecodeConverter
		self.documentManager = documentManager
		self.errorHandler = errorHandler
		self.cutDetector = cutDetector
		self.versionConverter = versionConverter
		self.mediaExtractor = mediaExtractor
		self.semanticValidator = semanticValidator
		self.dtdValidator = dtdValidator
		self.logger = logger
	}

	// MARK: - Default for Extension APIs

	/// Default instance used by extension APIs (e.g. `PNXMLElement.fcpxDuration`, `PNXMLDocument.fcpxAssetResources`) that cannot receive dependency injection. Concurrency-safe (immutable). For custom implementations use the modular API: inject dependencies into `FCPXMLService` / `FCPXMLUtility` and use the `+Modular` extensions (e.g. `element.setAttribute(name:value:using: documentManager)`) or service methods.
	public static let defaultForExtensions: FCPXMLUtility = FCPXMLUtility()
	
	// MARK: - Retrieval Methods
	
	/// Returns an array of elements that match specified FCPXML element types.
	///
	/// - Parameters:
	///   - elements: An array of PNXMLElement objects
	///   - types: An array of FCPXMLElementType enumeration values
	/// - Returns: A filtered array of PNXMLElement objects
	public func filter(fcpxElements elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement] {
		return parser.filter(elements: elements, ofTypes: types)
	}

	/// Filters elements by FCPXML element types (alias for `filter(fcpxElements:ofTypes:)` for API consistency).
	///
	/// - Parameters:
	///   - elements: An array of PNXMLElement objects
	///   - types: An array of FCPXMLElementType enumeration values
	/// - Returns: A filtered array of PNXMLElement objects
	public func filterElements(_ elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement] {
		return filter(fcpxElements: elements, ofTypes: types)
	}
	
	// MARK: - Time Conversion Methods
	
	/// Creates a CMTime value that represents real time from timecode values.
	///
	/// - Parameters:
	///   - timecodeHours: The hours element of the timecode value.
	///   - timecodeMinutes: The minutes element of the timecode value.
	///   - timecodeSeconds: The seconds element of the timecode value.
	///   - timecodeFrames: The frames element of the timecode value.
	///   - frameDuration: The duration of a single frame as a CMTime value.
	/// - Returns: A CMTime value equivalent to the timecode value in real time.
	public func cmTimeFrom(timecodeHours: Int, timecodeMinutes: Int, timecodeSeconds: Int, timecodeFrames: Int, frameDuration: CMTime) -> CMTime {
		return timecodeConverter.cmTimeFrom(timecodeHours: timecodeHours, timecodeMinutes: timecodeMinutes, timecodeSeconds: timecodeSeconds, timecodeFrames: timecodeFrames, frameDuration: frameDuration)
	}

	/// Converts an FCPXML time value to a CMTime value.
	///
	/// - Parameter timeString: The FCPXML time value as a string.
	/// - Returns: The equivalent CMTime value.
	public func cmTime(fromFCPXMLTime timeString: String) -> CoreMedia.CMTime {
		return timecodeConverter.cmTime(fromFCPXMLTime: timeString)
	}
	
	/// Converts a CMTime value to an FCPXML time value.
	///
	/// - Parameter time: A CMTime value to convert.
	/// - Returns: The FCPXML time value as a string.
	public func fcpxmlTime(fromCMTime time: CMTime) -> String {
		return timecodeConverter.fcpxmlTime(fromCMTime: time)
	}
	
	/// Conforms a given CMTime value to the frameDuration so that the value falls on an edit frame boundary. The function rounds the edit frame down.
	///
	/// - Parameters:
	///   - time: A CMTime value to conform.
	///   - frameDuration: The frame duration to conform to, represented as a CMTime.
	/// - Returns: A CMTime of the conformed value.
	public func conform(time: CMTime, toFrameDuration frameDuration: CMTime) -> CMTime {
		return timecodeConverter.conform(time: time, toFrameDuration: frameDuration)
	}

	/// Detects edit points (cuts) in the first project spine of the document.
	/// - Parameter document: Parsed FCPXML document.
	/// - Returns: Result with edit points and counts (same-clip vs different-clips, hard cut / transition / gap).
	public func detectCuts(in document: any PNXMLDocument) -> CutDetectionResult {
		cutDetector.detectCuts(in: document)
	}

	/// Detects edit points (cuts) in the given spine element.
	/// - Parameter spine: An FCPXML `spine` PNXMLElement.
	/// - Returns: Result with edit points and counts.
	public func detectCuts(inSpine spine: any PNXMLElement) -> CutDetectionResult {
		cutDetector.detectCuts(inSpine: spine)
	}

	/// Asynchronously detects edit points (cuts) in the first project spine of the document.
	public func detectCuts(in document: any PNXMLDocument) async -> CutDetectionResult {
		await cutDetector.detectCuts(in: document)
	}

	/// Asynchronously detects edit points (cuts) in the given spine element.
	public func detectCuts(inSpine spine: any PNXMLElement) async -> CutDetectionResult {
		await cutDetector.detectCuts(inSpine: spine)
	}

	/// Converts the document to the target FCPXML version (e.g. 1.14 → 1.10).
	public func convertToVersion(_ document: any PNXMLDocument, targetVersion: FCPXMLVersion) throws -> any PNXMLDocument {
		try versionConverter.convert(document, to: targetVersion)
	}

	/// Saves the document as a single .fcpxml file.
	public func saveAsFCPXML(_ document: any PNXMLDocument, to url: URL) throws {
		try documentManager.saveDocument(document, to: url)
	}

	/// Saves the document as a .fcpxmld bundle. Only supported when document version is 1.10 or higher.
	/// - Throws: `FCPXMLBundleExportError.bundleRequiresVersion1_10OrHigher` if version < 1.10.
	public func saveAsBundle(_ document: any PNXMLDocument, to outputDirectory: URL, bundleName: String) throws -> URL {
		let exporter = FCPXMLBundleExporter(version: .v1_10)
		return try exporter.saveDocumentAsBundle(document, to: outputDirectory, bundleName: bundleName)
	}

	/// Asynchronously converts the document to the target FCPXML version.
	public func convertToVersion(_ document: any PNXMLDocument, targetVersion: FCPXMLVersion) async throws -> any PNXMLDocument {
		try await versionConverter.convert(document, to: targetVersion)
	}

	/// Asynchronously saves the document as a .fcpxml file.
	public func saveAsFCPXML(_ document: any PNXMLDocument, to url: URL) async throws {
		try await documentManager.saveDocument(document, to: url)
	}

	/// Asynchronously saves the document as a .fcpxmld bundle (document version must be 1.10 or higher).
	public func saveAsBundle(_ document: any PNXMLDocument, to outputDirectory: URL, bundleName: String) async throws -> URL {
		let exporter = FCPXMLBundleExporter(version: .v1_10)
		return try exporter.saveDocumentAsBundle(document, to: outputDirectory, bundleName: bundleName)
	}

	/// Extracts media references (asset media-rep src, locator url) from the document.
	public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL? = nil) -> MediaExtractionResult {
		mediaExtractor.extractMediaReferences(from: document, baseURL: baseURL)
	}

	/// Copies referenced media files (file URLs only) to the destination directory; deduplicates by source URL.
	public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL? = nil, progress: (any ProgressReporter)? = nil) -> MediaCopyResult {
		mediaExtractor.copyReferencedMedia(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
	}

	/// Asynchronously extracts media references from the document.
	public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL? = nil) async -> MediaExtractionResult {
		await mediaExtractor.extractMediaReferences(from: document, baseURL: baseURL)
	}

	/// Asynchronously copies referenced media files to the destination directory.
	public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL? = nil, progress: (any ProgressReporter)? = nil) async -> MediaCopyResult {
		await mediaExtractor.copyReferencedMedia(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
	}
	
	// MARK: - Validation Methods
	
	/// Validates FCPXML document (root element and basic structure only).
	///
	/// For schema validation against a specific FCPXML version's DTD, use
	/// `validateDocumentAgainstDTD(_:version:)` or `validateDocumentAgainstDeclaredVersion(_:)`.
	/// - Parameter document: Document to validate
	/// - Returns: True if valid, false otherwise
	public func validateDocument(_ document: any PNXMLDocument) -> Bool {
		return parser.validate(document)
	}

	/// Validates the document against the DTD for the given FCPXML version (1.5–1.14).
	///
	/// Use this to ensure a document conforms to a specific version's schema before
	/// import or after conversion. Each FCPXML version has a distinct DTD in the package.
	/// - Parameters:
	///   - document: The FCPXML document to validate.
	///   - version: The FCPXML version whose DTD to use (e.g. `.v1_10`, `.v1_14`).
	/// - Returns: `.success` if the document conforms to that version's DTD; otherwise a result with `dtd_validation` error(s).
	public func validateDocumentAgainstDTD(_ document: any PNXMLDocument, version: FCPXMLVersion) -> ValidationResult {
		logger.log(level: .debug, message: "Validating document against DTD", metadata: ["version": version.rawValue])
		let result = dtdValidator.validate(document, version: version)
		if result.isValid {
			logger.log(level: .debug, message: "DTD validation passed", metadata: ["version": version.rawValue])
		} else {
			logger.log(level: .warning, message: "DTD validation failed", metadata: ["version": version.rawValue, "errors": result.detailedDescription])
		}
		return result
	}
	
	/// Validates the document against the DTD for its declared root version.
	///
	/// Reads the document's `fcpxml` root `version` attribute and validates against
	/// the matching DTD (1.5–1.14). Use to check that a document conforms to the schema
	/// it claims. If the version is missing or not supported, returns an error result.
	/// - Parameter document: The FCPXML document to validate.
	/// - Returns: `.success` if the document conforms to its declared version's DTD; otherwise a result with errors (e.g. unknown version or DTD validation failure).
	public func validateDocumentAgainstDeclaredVersion(_ document: any PNXMLDocument) -> ValidationResult {
		_validateDocumentAgainstDeclaredVersion(document)
	}

	/// Performs robust validation: semantic (root, resources, ref resolution) and DTD (against the document's declared version).
	///
	/// Use this for a full check before processing or to report validation status to the user.
	/// - Parameter document: The FCPXML document to validate.
	/// - Returns: A report combining semantic and DTD results; ``DocumentValidationReport/isValid`` is `true` only when both pass.
	public func performValidation(_ document: any PNXMLDocument) -> DocumentValidationReport {
		_performValidation(document)
	}

	private func _performValidation(_ document: any PNXMLDocument) -> DocumentValidationReport {
		logger.log(level: .debug, message: "Performing full validation (semantic + DTD)", metadata: nil)
		let semanticResult = semanticValidator.validate(document)
		let dtdResult = _validateDocumentAgainstDeclaredVersion(document)
		let report = DocumentValidationReport(semantic: semanticResult, dtd: dtdResult)
		if report.isValid {
			logger.log(level: .debug, message: report.summary, metadata: nil)
		} else {
			logger.log(level: .warning, message: report.summary, metadata: ["details": report.detailedDescription])
		}
		return report
	}
	
	private func _validateDocumentAgainstDeclaredVersion(_ document: any PNXMLDocument) -> ValidationResult {
		let versionString: String? = {
			guard let root = document.rootElement(), root.name == "fcpxml" else { return nil }
			return root.attribute(forName: "version")
		}()
		guard let versionString, !versionString.isEmpty else {
			return .error(ValidationError(
				type: .invalidAttributeValue,
				message: "Document has no FCPXML version attribute on root",
				context: [:]
			))
		}
		guard let version = FCPXMLVersion(string: versionString) else {
			return .error(ValidationError(
				type: .invalidAttributeValue,
				message: "Unsupported or invalid FCPXML version: '\(versionString)'",
				context: ["version": versionString]
			))
		}
		return dtdValidator.validate(document, version: version)
	}
	
	/// Asynchronously validates FCPXML document (root element and basic structure only).
	public func validateDocument(_ document: any PNXMLDocument) async -> Bool {
		return await parser.validate(document)
	}

	/// Asynchronously validates the document against the DTD for the given FCPXML version (1.5–1.14).
	///
	/// **Note:** This method calls the synchronous validator directly. Since validation is CPU-bound
	/// and works with non-Sendable `PNXMLDocument` types, wrapping in `Task` would not provide
	/// concurrency benefits and could introduce thread-safety issues. The async signature allows
	/// this method to be used in async contexts while maintaining type safety.
	///
	/// - Parameters:
	///   - document: The FCPXML document to validate.
	///   - version: The FCPXML version whose DTD to use (e.g. `.v1_10`, `.v1_14`).
	/// - Returns: `.success` if the document conforms to that version's DTD; otherwise a result with `dtd_validation` error(s).
	public func validateDocumentAgainstDTD(_ document: any PNXMLDocument, version: FCPXMLVersion) async -> ValidationResult {
		dtdValidator.validate(document, version: version)
	}

	/// Asynchronously validates the document against the DTD for its declared root version.
	///
	/// **Note:** This method calls the synchronous validator directly. Since validation is CPU-bound
	/// and works with non-Sendable `PNXMLDocument` types, wrapping in `Task` would not provide
	/// concurrency benefits and could introduce thread-safety issues. The async signature allows
	/// this method to be used in async contexts while maintaining type safety.
	///
	/// - Parameter document: The FCPXML document to validate.
	/// - Returns: `.success` if the document conforms to its declared version's DTD; otherwise a result with errors (e.g. unknown version or DTD validation failure).
	public func validateDocumentAgainstDeclaredVersion(_ document: any PNXMLDocument) async -> ValidationResult {
		_validateDocumentAgainstDeclaredVersion(document)
	}

	/// Asynchronously performs robust validation: semantic and DTD (against the document's declared version).
	///
	/// **Note:** This method calls synchronous validators directly. Since validation is CPU-bound
	/// and works with non-Sendable `PNXMLDocument` types, wrapping in `Task` would not provide
	/// concurrency benefits and could introduce thread-safety issues. The async signature allows
	/// this method to be used in async contexts while maintaining type safety.
	///
	/// - Parameter document: The FCPXML document to validate.
	/// - Returns: A report combining semantic and DTD results; ``DocumentValidationReport/isValid`` is `true` only when both pass.
	public func performValidation(_ document: any PNXMLDocument) async -> DocumentValidationReport {
		_performValidation(document)
	}
	
	/// Converts a project counter value to the project's timecode.
	///
	/// - Parameters:
	///   - counterValue: The counter value to convert.
	///   - project: The project to convert against, as an NSXMLElement.
	/// - Returns: An optional CMTime value of the timecode value.
	@available(*, deprecated, message: "Use sequenceTimecode(fromCounterValue:inSequence:) instead.")
	public func projectTimecode(fromCounterValue counterValue: CMTime, inProject project: any PNXMLElement) -> CMTime? {
		guard let projectSequence = project.fcpxProjectSequence else {
			return nil
		}
		return sequenceTimecode(fromCounterValue: counterValue, inSequence: projectSequence)
	}
	
	/// Converts a project timecode value to the project's counter time.
	///
	/// - Parameters:
	///   - timecodeValue: The timecode value to convert.
	///   - project: The project to convert against, as an NSXMLElement.
	/// - Returns: An optional CMTime value of the counter time.
	@available(*, deprecated, message: "Use sequenceCounterTime(fromTimecodeValue:inSequence:) instead.")
	public func projectCounterTime(fromTimecodeValue timecodeValue: CMTime, inProject project: any PNXMLElement) -> CMTime? {
		guard let projectSequence = project.fcpxProjectSequence else {
			return nil
		}
		return sequenceCounterTime(fromTimecodeValue: timecodeValue, inSequence: projectSequence)
	}
    
    /// Converts a sequence counter value to the sequence's timecode.
    ///
    /// - Parameters:
    ///   - counterValue: The counter value to convert.
    ///   - sequence: The sequence to convert against, as an NSXMLElement.
    /// - Returns: An optional CMTime value of the timecode value.
    public func sequenceTimecode(fromCounterValue counterValue: CMTime, inSequence sequence: any PNXMLElement) -> CMTime? {
        
        guard sequence.fcpxType == .sequence else {
            return nil
        }
        
        guard let sequenceTCStart = sequence.fcpxTCStart else {
            return nil
        }
        
        let timecodeValue = CMTimeAdd(sequenceTCStart, counterValue)
        
        return timecodeValue
    }
    
    /// Converts a sequence timecode value to the sequence counter time.
    ///
    /// - Parameters:
    ///   - timecodeValue: The timecode value to convert.
    ///   - sequence: The sequence to convert against, as an NSXMLElement.
    /// - Returns: An optional CMTime value of the counter time.
    public func sequenceCounterTime(fromTimecodeValue timecodeValue: CMTime, inSequence sequence: any PNXMLElement) -> CMTime? {
        
        // Convert the timecode values to sequence counter time values
        guard sequence.fcpxType == .sequence else {
            return nil
        }
        
        guard let sequenceTCStart = sequence.fcpxTCStart else {
            return nil
        }
        
        let counterValue = CMTimeSubtract(timecodeValue, sequenceTCStart)
        
        return counterValue
    }
	
	/// Converts a local time value to a clip's parent time value. In FCPXML, this would be converting a time value that is in the start value timescale to the offset value timescale.
	///
	/// For example, if a clip on the primary storyline has an attached clip, this will convert the attached clip's offset value to its parent clip's offset value timescale.
	///
	/// - Parameters:
	///   - fromLocalTime: The local time value to convert.
	///   - forClip: The clip to convert against.
	/// - Returns: A CMTime value of the resulting parent time value.
	public func parentTime(fromLocalTime localTimeValue: CMTime, forClip clip: any PNXMLElement) -> CMTime? {
		
		guard let parentInPoint = clip.fcpxParentInPoint else {
			return nil
		}
		
		let localTimeOffset = CMTimeSubtract(localTimeValue, clip.fcpxLocalInPoint)
		
		let localTimeAsParentTime = CMTimeAdd(parentInPoint, localTimeOffset)
		
		return localTimeAsParentTime
	}
	
	/// Converts a parent time value to a clip's local time value. In FCPXML, this would be converting a time value that is in the offset value timescale to the start value timescale.
	///
	/// For example, if a clip on the primary storyline has an attached clip, this will tell you what the attached clip's offset should be based on where you want it to be placed along the primary storyline.
	///
	/// - Parameters:
	///   - fromParentTime: The parent time value to convert.
	///   - forClip: The clip to convert against.
	/// - Returns: A CMTime value of the resulting parent time value.
	public func localTime(fromParentTime parentTimeValue: CMTime, forClip clip: any PNXMLElement) -> CMTime? {
		
		guard let parentInPoint = clip.fcpxParentInPoint else {
			return nil
		}
		
		let parentTimeOffset = CMTimeSubtract(parentTimeValue, parentInPoint)
		
		let parentTimeAsLocalTime = CMTimeAdd(clip.fcpxLocalInPoint, parentTimeOffset)
		
		return parentTimeAsLocalTime
	}
	
	/// Provides the start time of the given clip within the project timeline.
	///
	/// - Parameters:
	///   - forClip: The clip on the timeline to return the start time value for. The clip can be a clip on the primary storyline, a secondary storyline or it can be a connected clip.
	///   - inProject: The project that the clip resides in.
	/// - Returns: A CMTime value of the resulting project time value.
	public func projectTime(forClip clip: any PNXMLElement, inProject project: any PNXMLElement) -> CMTime? {
		
		guard let clipElementOffset = clip.fcpxOffset else {
			debugLog("clipElementOffset is nil")
			return nil
		}
		
		var startTime: CMTime
		guard let clipParentElement = clip.parent else {
			debugLog("clipParentElement is nil or not PNXMLElement")
			return nil
		}
		if clipParentElement.name == "spine" && clipParentElement.fcpxOffset != nil { // If the clip is in a secondary storyline
			
			guard let spineOffset = clipParentElement.fcpxOffset else {
				debugLog("spineOffset is nil")
				return nil
			}
			
			guard let spineParent = clipParentElement.parent else {
				debugLog("spineParent is nil or not PNXMLElement")
				return nil
			}
			
			let spineParentElement = spineParent
			
			let newSpineOffset = CMTimeAdd(spineOffset, clipElementOffset)
			
			guard let spineParentOffset = self.parentTime(fromLocalTime: newSpineOffset, forClip: spineParentElement) else {
				debugLog("spineParentOffset is nil")
				return nil
			}
			
			startTime = spineParentOffset
			
		} else if clipParentElement.name != "spine" { // If the clip is an attached clip
			
			guard let clipOffset = self.parentTime(fromLocalTime: clipElementOffset, forClip: clipParentElement) else {
				return nil
			}
			
			startTime = clipOffset
			
		} else { // If the clip is in the primary storyline or any other case
			
			guard let clipOffset = clip.fcpxOffset else {
				return nil
			}
			
			startTime = clipOffset
			
		}
		
		return startTime
	}
	
	/// Returns the clip's parent's equivalent offset timings for the specified in and out times. This is useful for walking up a PNXMLElement hierarchy in order to get the time values of the clip on the project timeline.
	///
	/// - Parameters:
	///   - inTime: The in time to convert, given as a CMTime value.
	///   - outTime: The out time to convert, given as a CMTime value.
	///   - clip: The clip that the time values are from. The parent time values will be drawn from this clip's parent.
	/// - Returns: A tuple of the converted in time, the converted out time, and the parent PNXMLElement of the specified clip.
	public func parentClipTime(forInTime inTime: CMTime, outTime: CMTime, forClip clip: any PNXMLElement) -> (in: CMTime, out: CMTime, parent: any PNXMLElement)? {
		
		guard let parentClip = clip.parentElement else {
			return nil
		}
		
		guard let parentIn = self.parentTime(fromLocalTime: inTime, forClip: parentClip) else {
			return nil
		}
		
		guard let parentOut = self.parentTime(fromLocalTime: outTime, forClip: parentClip) else {
			return nil
		}
		
		return (parentIn, parentOut, parentClip)
	}
	
	// MARK: - SwiftTimecode Integration
	
	/// Converts a CMTime to a SwiftTimecode Timecode object.
	/// Delegates to the injected timecodeConverter.
	///
	/// - Parameters:
	///   - time: The CMTime to convert
	///   - frameRate: The frame rate for the timecode
	/// - Returns: A Timecode object or nil if conversion fails
	public func timecode(from time: CMTime, frameRate: TimecodeFrameRate) -> Timecode? {
		return timecodeConverter.timecode(from: time, frameRate: frameRate)
	}
	
	/// Converts a SwiftTimecode Timecode object to CMTime.
	/// Delegates to the injected timecodeConverter.
	///
	/// - Parameter timecode: The Timecode object to convert
	/// - Returns: A CMTime value
	public func cmTime(from timecode: Timecode) -> CoreMedia.CMTime {
		return timecodeConverter.cmTime(from: timecode)
	}
	
	// MARK: - Async Methods
	
	/// Asynchronously converts line breaks in attributes to safe XML entities in an XML file.
	///
	/// When text values contain line breaks, such as in markers, Final Cut Pro X exports FCPXML files with the line break as is, not encoded into a valid XML line break character. This function will replace line breaks in _attribute nodes_ in FCPXML files with the &#xA; character entity.
	///
	/// - Parameter url: A URL object pointing to the XML file to convert.
	/// - Returns: A PNXMLDocument or nil if there was a file read or conversion error.
	public func convertLineBreaksInAttributes(inXMLDocumentURL url: URL) async -> (any PNXMLDocument)? {
		
		do {
			let document = try String(contentsOf: url, encoding: .utf8)
			
			let splitDocument = document.components(separatedBy: "=\"")
			var newSplitDocument: [String] = []
			var skipNextNewLineReplacement = false
			
			for segment in splitDocument {
				
				var newSegment = ""
				var reachedAttributeEnd = false
				
				for (charIndex, char) in segment.enumerated() {
					
					if reachedAttributeEnd == false {
						
						if char == "\n" && skipNextNewLineReplacement == false {
							
							newSegment += "&#xA;"
							debugLog("Found new line character in attribute value")
							
						} else if char == "\"" {
							
							newSegment += String(char)
							reachedAttributeEnd = true
							
						} else {
							
							newSegment += String(char)
							
							if charIndex == segment.count - 1 {
								skipNextNewLineReplacement = true
							}
							
						}
						
					} else {
						
						newSegment += String(char)
						skipNextNewLineReplacement = false
						
					}
					
				}
				
				newSplitDocument.append(newSegment)
				
			}
			
			let newDocument = newSplitDocument.joined(separator: "=\"")
			
			let newXMLDocument = try PNXMLDefaultFactory().makeDocument(xmlString: newDocument, options: [.preserveWhitespace, .prettyPrint, .compactEmptyElements])
			
			return newXMLDocument
			
		} catch {
			debugLog("Error converting line breaks: \(error)")
			return nil
		}
	}
	
	// MARK: - Other Conversion Methods
	
	/// Returns the FFVideoFormat identifier based on the given parameters. If the parameters don't match a defined identifier according to FCPXML v1.5, the method will return the string "FFVideoFormatRateUndefined".
	///
	/// - Parameters:
	///   - width: The width of the frame as an integer.
	///   - height: The height of the frame as an integer.
	///   - frameRate: The frame rate as a float.
	///   - isInterlaced: A boolean value indicating if the format is interlaced.
	///   - isSD16x9: A boolean value indicating if the format has an aspect ratio of 16:9.
	/// - Returns: A string of the FFVideoFormat identifier.
	public func ffVideoFormat(fromWidth width: Int, height: Int, frameRate: Float, isInterlaced: Bool, isSD16x9: Bool) -> String {
		
		var ffVideoFormat = "FFVideoFormat"
		let undefined = "FFVideoFormatRateUndefined"
		
		switch width {
		case 1920:
			if height == 1080 {
				ffVideoFormat += "1080"
			} else {
				return undefined
			}
		case 1280:
			switch height {
			case 1080:
				ffVideoFormat += "1280x1080"
			case 720:
				ffVideoFormat += "720"
			default:
				return undefined
			}
		case 1440:
			if height == 1080 {
				ffVideoFormat += "1440x1080"
			} else {
				return undefined
			}
		case 2048:
			switch height {
			case 1080:
				ffVideoFormat += "2048x1080"
			case 1024:
				ffVideoFormat += "2048x1024"
			case 1152:
				ffVideoFormat += "2048x1152"
			case 1536:
				ffVideoFormat += "2048x1536"
			case 1556:
				ffVideoFormat += "2048x1556"
			default:
				return undefined
			}
		case 3840:
			if height == 2160 {
				ffVideoFormat += "3840x2160"
			} else {
				return undefined
			}
		case 4096:
			switch height {
			case 2048:
				ffVideoFormat += "4096x2048"
			case 2160:
				ffVideoFormat += "4096x2160"
			case 2304:
				ffVideoFormat += "4096x2304"
			case 3112:
				ffVideoFormat += "4096x3112"
			default:
				return undefined
			}
		case 5120:
			switch height {
			case 2160:
				ffVideoFormat += "5120x2160"
			case 2560:
				ffVideoFormat += "5120x2560"
			case 2700:
				ffVideoFormat += "5120x2700"
			default:
				return undefined
			}
		case 640:
			switch height {
			case 360:
				ffVideoFormat += "640x360"
			case 480:
				ffVideoFormat += "640x480"
			default:
				return undefined
			}
		case 720:
			switch height {
			case 480:
				ffVideoFormat += "DV720x480"
			case 486:
				ffVideoFormat += "720x486"
			case 576:
				ffVideoFormat += "720x576"
			default:
				return undefined
			}
		case 960:
			switch height {
			case 540:
				ffVideoFormat += "960x540"
			case 720:
				ffVideoFormat += "960x720"
			default:
				return undefined
			}
		default:
			return undefined
		}
		
		if !isInterlaced {
			ffVideoFormat += "p"
		} else {
			if frameRate == 59.94 || frameRate == 50 {
				ffVideoFormat += "i"
			} else {
				return undefined
			}
		}
		
		// Use tolerance-based matching for frame rates to handle floating-point rounding
		// (e.g. 23.976 may be rounded to 23.98 by callers).
		let tolerance: Float = 0.05
		if abs(frameRate - 23.976) < tolerance || abs(frameRate - 23.98) < tolerance {
			ffVideoFormat += "2398"
		} else if abs(frameRate - 24) < tolerance {
			ffVideoFormat += "24"
		} else if abs(frameRate - 25) < tolerance {
			ffVideoFormat += "25"
		} else if abs(frameRate - 29.97) < tolerance {
			ffVideoFormat += "2997"
		} else if abs(frameRate - 30) < tolerance {
			ffVideoFormat += "30"
		} else if abs(frameRate - 50) < tolerance {
			ffVideoFormat += "50"
		} else if abs(frameRate - 59.94) < tolerance {
			ffVideoFormat += "5994"
		} else if abs(frameRate - 60) < tolerance {
			ffVideoFormat += "60"
		} else {
			return undefined
		}
		
		if isSD16x9 {
			ffVideoFormat += "_16x9"
		}
		
		return ffVideoFormat
	}

	private func debugLog(_ message: String) {
		logger.log(level: .debug, message: message, metadata: nil)
	}
}
