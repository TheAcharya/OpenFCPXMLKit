//
//  FCPXMLService.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Service orchestrating modular components for high-level FCPXML workflows.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Main service for FCPXML operations, orchestrating modular components
@available(macOS 12.0, *)
public final class FCPXMLService: Sendable {

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

    // MARK: - Initialisation

    /// Creates a service with injected dependencies.
    ///
    /// All parameters have sensible defaults. Pass custom implementations
    /// to override parsing, timecode conversion, document management,
    /// error handling, cut detection, version conversion, semantic/DTD validation, or logging behaviour.
    ///
    /// - Parameters:
    ///   - parser: FCPXML parser and element filter (default: `FCPXMLParser()`).
    ///   - timecodeConverter: Timecode conversion, FCPXML time string parsing, and time conforming (default: `TimecodeConverter()`).
    ///   - documentManager: XML document and element operations (default: `XMLDocumentManager()`).
    ///   - errorHandler: Error formatting service (default: `ErrorHandler()`).
    ///   - cutDetector: Cut detection implementation (default: `CutDetector()`).
    ///   - versionConverter: FCPXML version conversion (default: `FCPXMLVersionConverter()`).
    ///   - mediaExtractor: Media reference extraction and copy (default: `MediaExtractor()`).
    ///   - semanticValidator: Semantic validator for root, resources, ref resolution (default: `FCPXMLValidator()`).
    ///   - dtdValidator: DTD validator for per-version schema checks (default: `FCPXMLDTDValidator()`).
    ///   - logger: Pipeline logger (default: `NoOpPipelineLogger()`).
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

    // MARK: - Public API (Sync)

    /// Parses FCPXML from data
    /// - Parameter data: FCPXML data
    /// - Returns: Parsed document
    /// - Throws: FCPXMLError
    public func parseFCPXML(from data: Data) throws -> any PNXMLDocument {
        logger.log(level: .debug, message: "Parsing FCPXML from data", metadata: ["bytes": "\(data.count)"])
        do {
            let doc = try parser.parse(data)
            logger.log(level: .debug, message: "Parsed FCPXML successfully", metadata: nil)
            return doc
        } catch {
            logger.log(level: .error, message: "Parse failed: \(errorHandler.handleParsingError(error))", metadata: nil)
            throw error
        }
    }

    /// Parses FCPXML from URL
    /// - Parameter url: URL containing FCPXML data
    /// - Returns: Parsed document
    /// - Throws: FCPXMLError
    public func parseFCPXML(from url: URL) throws -> any PNXMLDocument {
        logger.log(level: .debug, message: "Parsing FCPXML from URL", metadata: ["url": url.lastPathComponent])
        do {
            let doc = try parser.parse(from: url)
            logger.log(level: .debug, message: "Parsed FCPXML successfully", metadata: nil)
            return doc
        } catch {
            logger.log(level: .error, message: "Parse failed: \(errorHandler.handleParsingError(error))", metadata: nil)
            throw error
        }
    }

    /// Converts CMTime to SwiftTimecode Timecode
    /// - Parameters:
    ///   - time: CMTime to convert
    ///   - frameRate: Target frame rate
    /// - Returns: Timecode or nil
    public func timecode(from time: CMTime, frameRate: TimecodeFrameRate) -> Timecode? {
        return timecodeConverter.timecode(from: time, frameRate: frameRate)
    }

    /// Converts SwiftTimecode Timecode to CMTime
    /// - Parameter timecode: Timecode to convert
    /// - Returns: CMTime
    public func cmTime(from timecode: Timecode) -> CMTime {
        return timecodeConverter.cmTime(from: timecode)
    }

    /// Creates a new FCPXML document
    /// - Parameter version: FCPXML version
    /// - Returns: New document
    public func createFCPXMLDocument(version: String = "1.10") -> any PNXMLDocument {
        return documentManager.createFCPXMLDocument(version: version)
    }

    /// Filters elements by type
    /// - Parameters:
    ///   - elements: Elements to filter
    ///   - types: Types to match
    /// - Returns: Filtered elements
    public func filterElements(_ elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) -> [any PNXMLElement] {
        return parser.filter(elements: elements, ofTypes: types)
    }

    /// Saves document to URL
    /// - Parameters:
    ///   - document: Document to save
    ///   - url: Target URL
    /// - Throws: Error if saving fails
    public func saveDocument(_ document: any PNXMLDocument, to url: URL) throws {
        try documentManager.saveDocument(document, to: url)
    }

    /// Validates FCPXML document (root element and basic structure only).
    ///
    /// For schema validation against a specific FCPXML version's DTD, use
    /// `validateDocumentAgainstDTD(_:version:)` or `validateDocumentAgainstDeclaredVersion(_:)`.
    /// - Parameter document: Document to validate
    /// - Returns: True if valid, false otherwise
    public func validateDocument(_ document: any PNXMLDocument) -> Bool {
        return parser.validate(document)
    }

    /// Validates the document against the DTD for the given FCPXML version (1.5-1.14).
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
    /// the matching DTD (1.5-1.14). Use to check that a document conforms to the schema
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
        guard let versionString = document.rootElement()?.attribute(forName: "version"), !versionString.isEmpty else {
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

    /// Converts FCPXML time string to CMTime
    /// - Parameter timeString: FCPXML time string
    /// - Returns: CMTime
    public func cmTime(fromFCPXMLTime timeString: String) -> CMTime {
        return timecodeConverter.cmTime(fromFCPXMLTime: timeString)
    }

    /// Converts CMTime to FCPXML time string
    /// - Parameter time: CMTime to convert
    /// - Returns: FCPXML time string
    public func fcpxmlTime(fromCMTime time: CMTime) -> String {
        return timecodeConverter.fcpxmlTime(fromCMTime: time)
    }

    /// Conforms time to frame boundary
    /// - Parameters:
    ///   - time: Time to conform
    ///   - frameDuration: Target frame duration
    /// - Returns: Conformed CMTime
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
    /// - Parameter spine: An FCPXML `spine` element.
    /// - Returns: Result with edit points and counts.
    public func detectCuts(inSpine spine: any PNXMLElement) -> CutDetectionResult {
        cutDetector.detectCuts(inSpine: spine)
    }

    /// Converts the document to the target FCPXML version (e.g. 1.14 -> 1.10).
    /// Returns a new document with root `version` set to the target; save as .fcpxml or .fcpxmld (bundle only for 1.10+).
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - targetVersion: Desired version (e.g. `.v1_10`).
    /// - Returns: New document with that version.
    /// - Throws: If conversion (copy/serialization) fails.
    public func convertToVersion(_ document: any PNXMLDocument, targetVersion: FCPXMLVersion) throws -> any PNXMLDocument {
        logger.log(level: .info, message: "Converting document to FCPXML version", metadata: ["target": targetVersion.rawValue])
        let result = try versionConverter.convert(document, to: targetVersion)
        logger.log(level: .debug, message: "Version conversion completed", metadata: ["version": targetVersion.rawValue])
        return result
    }

    /// Saves the document as a single .fcpxml file.
    /// - Parameters:
    ///   - document: FCPXML document (e.g. after convertToVersion).
    ///   - url: Destination URL (typically with .fcpxml extension).
    public func saveAsFCPXML(_ document: any PNXMLDocument, to url: URL) throws {
        logger.log(level: .info, message: "Saving FCPXML document", metadata: ["path": url.path])
        try documentManager.saveDocument(document, to: url)
        logger.log(level: .debug, message: "Document saved successfully", metadata: ["path": url.path])
    }

    /// Saves the document as a .fcpxmld bundle. Only supported when document version is 1.10 or higher.
    /// - Parameters:
    ///   - document: FCPXML document (e.g. after convertToVersion to .v1_10 or later).
    ///   - outputDirectory: Parent directory for the bundle.
    ///   - bundleName: Bundle name without extension (e.g. "My Project" -> My Project.fcpxmld).
    /// - Returns: URL of the created bundle.
    /// - Throws: `FCPXMLBundleExportError.bundleRequiresVersion1_10OrHigher` if version < 1.10; or write errors.
    public func saveAsBundle(_ document: any PNXMLDocument, to outputDirectory: URL, bundleName: String) throws -> URL {
        let exporter = FCPXMLBundleExporter(version: .v1_10)
        return try exporter.saveDocumentAsBundle(document, to: outputDirectory, bundleName: bundleName)
    }

    /// Extracts media references (asset media-rep src, locator url) from the document.
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - baseURL: Optional base URL to resolve relative src (e.g. URL of the .fcpxml or .fcpxmld).
    /// - Returns: Result with references; urls may be nil for relative src when baseURL is nil.
    public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL? = nil) -> MediaExtractionResult {
        logger.log(level: .debug, message: "Extracting media references", metadata: baseURL.map { ["baseURL": $0.path] } ?? nil)
        let result = mediaExtractor.extractMediaReferences(from: document, baseURL: baseURL)
        logger.log(level: .info, message: "Media references extracted", metadata: ["count": "\(result.references.count)", "fileReferences": "\(result.fileReferences.count)"])
        return result
    }

    /// Copies referenced media files (file URLs only) to the destination directory; deduplicates by source URL.
    /// - Parameters:
    ///   - document: Parsed FCPXML document.
    ///   - destinationURL: Directory to copy files into.
    ///   - baseURL: Optional base URL to resolve relative src.
    ///   - progress: Optional progress reporter (e.g. CLI progress bar).
    /// - Returns: Result with copied, skipped, and failed entries.
    public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL? = nil, progress: (any ProgressReporter)? = nil) -> MediaCopyResult {
        logger.log(level: .info, message: "Copying referenced media to destination", metadata: ["destination": destinationURL.path])
        let result = mediaExtractor.copyReferencedMedia(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
        logger.log(level: .info, message: "Media copy completed", metadata: [
            "copied": "\(result.copied.count)",
            "skipped": "\(result.skipped.count)",
            "failed": "\(result.failed.count)"
        ])
        return result
    }

    // MARK: - Async Public API

    /// Asynchronously parses FCPXML from data
    /// - Parameter data: FCPXML data
    /// - Returns: Parsed document
    /// - Throws: FCPXMLError
    public func parseFCPXML(from data: Data) async throws -> any PNXMLDocument {
        logger.log(level: .debug, message: "Parsing FCPXML from data (async)", metadata: ["bytes": "\(data.count)"])
        do {
            let doc = try await parser.parse(data)
            logger.log(level: .debug, message: "Parsed FCPXML successfully", metadata: nil)
            return doc
        } catch {
            logger.log(level: .error, message: "Parse failed: \(errorHandler.handleParsingError(error))", metadata: nil)
            throw error
        }
    }

    /// Asynchronously parses FCPXML from URL
    /// - Parameter url: URL containing FCPXML data
    /// - Returns: Parsed document
    /// - Throws: FCPXMLError
    public func parseFCPXML(from url: URL) async throws -> any PNXMLDocument {
        logger.log(level: .debug, message: "Parsing FCPXML from URL (async)", metadata: ["url": url.lastPathComponent])
        do {
            let doc = try await parser.parse(from: url)
            logger.log(level: .debug, message: "Parsed FCPXML successfully", metadata: nil)
            return doc
        } catch {
            logger.log(level: .error, message: "Parse failed: \(errorHandler.handleParsingError(error))", metadata: nil)
            throw error
        }
    }

    /// Asynchronously converts CMTime to SwiftTimecode Timecode
    /// - Parameters:
    ///   - time: CMTime to convert
    ///   - frameRate: Target frame rate
    /// - Returns: Timecode or nil
    public func timecode(from time: CMTime, frameRate: TimecodeFrameRate) async -> Timecode? {
        return await timecodeConverter.timecode(from: time, frameRate: frameRate)
    }

    /// Asynchronously converts SwiftTimecode Timecode to CMTime
    /// - Parameter timecode: Timecode to convert
    /// - Returns: CMTime
    public func cmTime(from timecode: Timecode) async -> CMTime {
        return await timecodeConverter.cmTime(from: timecode)
    }

    /// Asynchronously creates a new FCPXML document
    /// - Parameter version: FCPXML version
    /// - Returns: New document
    public func createFCPXMLDocument(version: String = "1.10") async -> any PNXMLDocument {
        return await documentManager.createFCPXMLDocument(version: version)
    }

    /// Asynchronously filters elements by type
    /// - Parameters:
    ///   - elements: Elements to filter
    ///   - types: Types to match
    /// - Returns: Filtered elements
    public func filterElements(_ elements: [any PNXMLElement], ofTypes types: [FCPXMLElementType]) async -> [any PNXMLElement] {
        return await parser.filter(elements: elements, ofTypes: types)
    }

    /// Asynchronously saves document to URL
    /// - Parameters:
    ///   - document: Document to save
    ///   - url: Target URL
    /// - Throws: Error if saving fails
    public func saveDocument(_ document: any PNXMLDocument, to url: URL) async throws {
        try await documentManager.saveDocument(document, to: url)
    }

    /// Asynchronously validates FCPXML document (root element and basic structure only).
    public func validateDocument(_ document: any PNXMLDocument) async -> Bool {
        return await parser.validate(document)
    }

    /// Asynchronously validates the document against the DTD for the given FCPXML version (1.5-1.14).
    ///
    /// **Note:** This method calls the synchronous validator directly. Since validation is CPU-bound
    /// and works with non-Sendable document types, wrapping in `Task` would not provide
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
    /// and works with non-Sendable document types, wrapping in `Task` would not provide
    /// concurrency benefits and could introduce thread-safety issues. The async signature allows
    /// this method to be used in async contexts while maintaining type safety.
    ///
    /// - Parameter document: The FCPXML document to validate.
    /// - Returns: `.success` if the document conforms to its declared version's DTD; otherwise a result with errors (e.g. unknown version or DTD validation failure).
    public func validateDocumentAgainstDeclaredVersion(_ document: any PNXMLDocument) async -> ValidationResult {
        _validateDocumentAgainstDeclaredVersion(document)
    }

    /// Asynchronously performs robust validation: semantic and DTD (against the document's declared version).
    public func performValidation(_ document: any PNXMLDocument) async -> DocumentValidationReport {
        _performValidation(document)
    }

    /// Asynchronously converts FCPXML time string to CMTime
    /// - Parameter timeString: FCPXML time string
    /// - Returns: CMTime
    public func cmTime(fromFCPXMLTime timeString: String) async -> CMTime {
        return await timecodeConverter.cmTime(fromFCPXMLTime: timeString)
    }

    /// Asynchronously converts CMTime to FCPXML time string
    /// - Parameter time: CMTime to convert
    /// - Returns: FCPXML time string
    public func fcpxmlTime(fromCMTime time: CMTime) async -> String {
        return await timecodeConverter.fcpxmlTime(fromCMTime: time)
    }

    /// Asynchronously conforms time to frame boundary
    /// - Parameters:
    ///   - time: Time to conform
    ///   - frameDuration: Target frame duration
    /// - Returns: Conformed CMTime
    public func conform(time: CMTime, toFrameDuration frameDuration: CMTime) async -> CMTime {
        return await timecodeConverter.conform(time: time, toFrameDuration: frameDuration)
    }

    /// Asynchronously detects edit points (cuts) in the first project spine of the document.
    public func detectCuts(in document: any PNXMLDocument) async -> CutDetectionResult {
        await cutDetector.detectCuts(in: document)
    }

    /// Asynchronously detects edit points (cuts) in the given spine element.
    public func detectCuts(inSpine spine: any PNXMLElement) async -> CutDetectionResult {
        await cutDetector.detectCuts(inSpine: spine)
    }

    /// Asynchronously converts the document to the target FCPXML version.
    public func convertToVersion(_ document: any PNXMLDocument, targetVersion: FCPXMLVersion) async throws -> any PNXMLDocument {
        try await versionConverter.convert(document, to: targetVersion)
    }

    /// Asynchronously saves the document as a single .fcpxml file.
    public func saveAsFCPXML(_ document: any PNXMLDocument, to url: URL) async throws {
        try await documentManager.saveDocument(document, to: url)
    }

    /// Asynchronously saves the document as a .fcpxmld bundle (document version must be 1.10 or higher).
    public func saveAsBundle(_ document: any PNXMLDocument, to outputDirectory: URL, bundleName: String) async throws -> URL {
        let exporter = FCPXMLBundleExporter(version: .v1_10)
        return try exporter.saveDocumentAsBundle(document, to: outputDirectory, bundleName: bundleName)
    }

    /// Asynchronously extracts media references from the document.
    public func extractMediaReferences(from document: any PNXMLDocument, baseURL: URL? = nil) async -> MediaExtractionResult {
        await mediaExtractor.extractMediaReferences(from: document, baseURL: baseURL)
    }

    /// Asynchronously copies referenced media files to the destination directory.
    public func copyReferencedMedia(from document: any PNXMLDocument, to destinationURL: URL, baseURL: URL? = nil, progress: (any ProgressReporter)? = nil) async -> MediaCopyResult {
        await mediaExtractor.copyReferencedMedia(from: document, to: destinationURL, baseURL: baseURL, progress: progress)
    }
}
