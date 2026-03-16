//
//  ModularUtilities.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License


//
//	Pipeline creation, validation, and batch processing helpers.
//

import Foundation
import CoreMedia
import SwiftTimecode

/// Utility functions for modular FCPXML operations
@available(macOS 12.0, *)
public struct ModularUtilities: Sendable {

    /// Shared validator instance for reuse across validation calls.
    /// Since `FCPXMLValidator` is stateless, a single instance can be safely reused.
    private static let sharedValidator = FCPXMLValidator()

    /// Creates a complete FCPXML processing pipeline with all dependencies
    /// - Returns: Configured FCPXMLService
    public static func createPipeline() -> FCPXMLService {
        let parser = FCPXMLParser()
        let timecodeConverter = TimecodeConverter()
        let documentManager = XMLDocumentManager()
        let errorHandler = ErrorHandler()

        return FCPXMLService(
            parser: parser,
            timecodeConverter: timecodeConverter,
            documentManager: documentManager,
            errorHandler: errorHandler
        )
    }

    /// Creates a custom pipeline with specific implementations
    /// - Parameters:
    ///   - parser: Custom parser implementation
    ///   - timecodeConverter: Custom timecode converter
    ///   - documentManager: Custom document manager
    ///   - errorHandler: Custom error handler
    ///   - logger: Optional logger (default: no-op)
    /// - Returns: Configured FCPXMLService
    public static func createCustomPipeline(
        parser: FCPXMLParsing & FCPXMLElementFiltering,
        timecodeConverter: TimecodeConversion & FCPXMLTimeStringConversion & TimeConforming,
        documentManager: XMLDocumentOperations & XMLElementOperations,
        errorHandler: ErrorHandling,
        logger: PipelineLogger = NoOpPipelineLogger()
    ) -> FCPXMLService {
        return FCPXMLService(
            parser: parser,
            timecodeConverter: timecodeConverter,
            documentManager: documentManager,
            errorHandler: errorHandler,
            logger: logger
        )
    }

    /// Validates FCPXML document structure using the semantic validator.
    ///
    /// Delegates to `FCPXMLValidator` for root element, resources, and ref resolution checks.
    /// Uses a shared validator instance for efficiency (validator is stateless and thread-safe).
    ///
    /// - Parameter document: Document to validate.
    /// - Returns: Validation result with error messages.
    public static func validateDocument(_ document: any PNXMLDocument) -> (isValid: Bool, errors: [String]) {
        let result = sharedValidator.validate(document)
        let errorMessages = result.errors.map(\.message)
        return (result.isValid, errorMessages)
    }

    /// Validates FCPXML document (deprecated: parser parameter is unused).
    @available(*, deprecated, message: "Use validateDocument(_:) without the parser parameter.")
    public static func validateDocument(_ document: any PNXMLDocument, using parser: FCPXMLParsing) -> (isValid: Bool, errors: [String]) {
        validateDocument(document)
    }

    /// Processes FCPXML from a URL, returning a Result.
    /// - Parameters:
    ///   - url: URL of FCPXML file
    ///   - service: FCPXML service
    /// - Returns: Processed document or error
    public static func processFCPXML(
        from url: URL,
        using service: FCPXMLService
    ) -> Result<any PNXMLDocument, FCPXMLError> {
        do {
            let document = try service.parseFCPXML(from: url)
            return .success(document)
        } catch let error as FCPXMLError {
            return .failure(error)
        } catch {
            return .failure(FCPXMLError.parsingFailed(error))
        }
    }

    /// Processes FCPXML with error handling (deprecated: errorHandler is unused).
    @available(*, deprecated, message: "Use processFCPXML(from:using:) without errorHandler.")
    public static func processFCPXML(
        from url: URL,
        using service: FCPXMLService,
        errorHandler: ErrorHandling
    ) -> Result<any PNXMLDocument, FCPXMLError> {
        processFCPXML(from: url, using: service)
    }

    // MARK: - Async Methods

    /// Asynchronously validates FCPXML document structure.
    ///
    /// Uses a shared validator instance for efficiency (validator is stateless and thread-safe).
    ///
    /// - Parameter document: Document to validate.
    /// - Returns: Validation result with error messages.
    public static func validateDocument(_ document: any PNXMLDocument) async -> (isValid: Bool, errors: [String]) {
        let result = sharedValidator.validate(document)
        let errorMessages = result.errors.map(\.message)
        return (result.isValid, errorMessages)
    }

    /// Asynchronously validates FCPXML document (deprecated: parser parameter is unused).
    @available(*, deprecated, message: "Use validateDocument(_:) without the parser parameter.")
    public static func validateDocument(_ document: any PNXMLDocument, using parser: FCPXMLParsing) async -> (isValid: Bool, errors: [String]) {
        let result = sharedValidator.validate(document)
        let errorMessages = result.errors.map(\.message)
        return (result.isValid, errorMessages)
    }

    /// Asynchronously processes FCPXML from a URL, returning a Result.
    /// - Parameters:
    ///   - url: URL of FCPXML file
    ///   - service: FCPXML service
    /// - Returns: Processed document or error
    public static func processFCPXML(
        from url: URL,
        using service: FCPXMLService
    ) async -> Result<any PNXMLDocument, FCPXMLError> {
        do {
            let document = try await service.parseFCPXML(from: url)
            return .success(document)
        } catch let error as FCPXMLError {
            return .failure(error)
        } catch {
            return .failure(FCPXMLError.parsingFailed(error))
        }
    }

    /// Asynchronously processes FCPXML with error handling (deprecated: errorHandler is unused).
    @available(*, deprecated, message: "Use processFCPXML(from:using:) without errorHandler.")
    public static func processFCPXML(
        from url: URL,
        using service: FCPXMLService,
        errorHandler: ErrorHandling
    ) async -> Result<any PNXMLDocument, FCPXMLError> {
        await processFCPXML(from: url, using: service)
    }

    /// Asynchronously processes multiple FCPXML files sequentially.
    /// - Parameters:
    ///   - urls: Array of FCPXML file URLs
    ///   - service: FCPXML service
    /// - Returns: Array of processed documents or errors
    public static func processMultipleFCPXML(
        from urls: [URL],
        using service: FCPXMLService
    ) async -> [Result<any PNXMLDocument, FCPXMLError>] {
        var results: [Result<any PNXMLDocument, FCPXMLError>] = []
        for url in urls {
            let result = await processFCPXML(from: url, using: service)
            results.append(result)
        }
        return results
    }

    /// Asynchronously processes multiple FCPXML files (deprecated: errorHandler is unused).
    @available(*, deprecated, message: "Use processMultipleFCPXML(from:using:) without errorHandler.")
    public static func processMultipleFCPXML(
        from urls: [URL],
        using service: FCPXMLService,
        errorHandler: ErrorHandling
    ) async -> [Result<any PNXMLDocument, FCPXMLError>] {
        await processMultipleFCPXML(from: urls, using: service)
    }

    /// Asynchronously converts timecodes for multiple elements sequentially.
    ///
    /// Extracts the "offset" attribute from each element as an FCPXML time string,
    /// converts it to CMTime via the provided timeStringConverter, then converts to Timecode.
    /// Elements without a valid "offset" attribute produce nil.
    ///
    /// - Parameters:
    ///   - elements: Array of PNXMLElements with time attributes
    ///   - timecodeConverter: Timecode converter service (must also conform to FCPXMLTimeStringConversion)
    ///   - frameRate: Target frame rate
    /// - Returns: Array of converted timecodes
    public static func convertTimecodes(
        for elements: [any PNXMLElement],
        using timecodeConverter: TimecodeConversion & FCPXMLTimeStringConversion,
        frameRate: TimecodeFrameRate
    ) async -> [Timecode?] {
        var results: [Timecode?] = []

        for element in elements {
            let offsetString = element.attribute(forName: "offset") ?? "0s"
            let time = await timecodeConverter.cmTime(fromFCPXMLTime: offsetString)
            let timecode = await timecodeConverter.timecode(from: time, frameRate: frameRate)
            results.append(timecode)
        }

        return results
    }
}
