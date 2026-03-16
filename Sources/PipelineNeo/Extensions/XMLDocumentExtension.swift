//
//  XMLDocumentExtension.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	PNXMLDocument extensions for FCPXML document-level operations.
//

#if canImport(FoundationXML) || os(macOS)

import Foundation
import CoreMedia
import SwiftExtensions

#if canImport(Logging)
import Logging
#endif

@available(macOS 12.0, *)
extension FoundationXMLDocument {

	// MARK: - Initializing Document Objects

	/// Initializes a new document using the contents of an existing FCPXML file.
	///
	/// - Parameter url: The URL to the FCPXML file.
	/// - Throws: An error object that, on return, identifies any parsing errors and warnings or connection problems.
	public convenience init(contentsOfFCPXML url: URL) throws {
		try self.init(contentsOf: url, options: .fcpxmlDefaults)
	}

	/// Initializes a new document as FCPXML.
	///
	/// - Parameters:
	///   - resources: Resources an array of PNXMLElement objects
	///   - events: Events as an array of PNXMLElement objects
	///   - fcpxmlVersion: The FCPXML version of the document to use.
	public convenience init(resources: [any PNXMLElement], events: [any PNXMLElement], fcpxmlVersion: String) {
		self.init()
		self.documentContentKind = .xml
		self.characterEncoding = "UTF-8"
		self.version = "1.0"

		let dtd = FoundationXMLFactory().makeDTD()
		dtd.name = "fcpxml"
		self.dtd = dtd
		self.isStandalone = false

		self.setRootElement(FoundationXMLFactory().makeElement(name: "fcpxml"))
		self.fcpxmlVersion = fcpxmlVersion

		self.add(resourceElements: resources)
		self.add(events: events)
	}

	/// Initializes a new document as FCPXML using a type-safe version.
	///
	/// - Parameters:
	///   - resources: Resources as an array of PNXMLElement objects.
	///   - events: Events as an array of PNXMLElement objects.
	///   - fcpxmlVersion: The FCPXML version (e.g. `.default` or `.v1_14`).
	public convenience init(resources: [any PNXMLElement], events: [any PNXMLElement], fcpxmlVersion: FCPXMLVersion) {
		self.init(resources: resources, events: events, fcpxmlVersion: fcpxmlVersion.stringValue)
	}

	// MARK: - FCPXML Document Properties

	/// The FCPXML document as a properly formatted string.
	public var fcpxmlString: String {
		let formattedData = self.xmlData(options: .fcpxmlDefaults)
		guard var formattedString = String(data: formattedData, encoding: .utf8) else {
			return ""
		}

		// Replace standalone="yes" with standalone="no" for DTD validation compatibility.
		// Foundation's xmlData() often outputs standalone="yes" regardless of isStandalone.
		// With standalone="yes", xmllint reports: "standalone: fcpxml declared in the external subset contains white space nodes"
		// (pretty-printed whitespace violates standalone). Explicit standalone="no" declares the document
		// depends on an external DTD, so whitespace is allowed and xmllint --dtdvalid does not warn.
		if formattedString.hasPrefix("<?xml") {
			formattedString = formattedString.replacingOccurrences(
				of: #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#,
				with: #"<?xml version="1.0" encoding="UTF-8" standalone="no"?>"#
			)
		}

		return formattedString
	}

	/// The "fcpxml" element at the root of the document.
	public var fcpxmlElement: (any PNXMLElement)? {
		guard let children = self.children else {
			return nil
		}

		for child in children {
			if child.name == "fcpxml" {
				if let element = child as? (any PNXMLElement) {
					return element
				}
			}
		}
		return nil
	}

	/// The "resource" element child of the "fcpxml" element.
	public var fcpxResourceElement: (any PNXMLElement)? {
		guard let fcpxmlElement = self.fcpxmlElement else { return nil }
		return fcpxmlElement.firstChildElement(named: "resources")
	}

	/// An array of all resources in the FCPXML document.
	public var fcpxResources: [any PNXMLElement] {
		guard let resourceElement = fcpxResourceElement else { return [] }
		return Array(resourceElement.childElements)
	}

	/// The library element in the FCPXML document.
	public var fcpxLibraryElement: (any PNXMLElement)? {
		guard let fcpxmlElement = self.fcpxmlElement else { return nil }
		return fcpxmlElement.firstChildElement(named: "library")
	}

	/// An array of all event elements in the FCPXML document.
	public var fcpxEvents: [any PNXMLElement] {
		guard let libraryElement = self.fcpxLibraryElement else {
			return []
		}
		return libraryElement.elements(forName: "event")
	}

	/// An array of format resources in the FCPXML document.
	public var fcpxFormatResources: [any PNXMLElement] {
		let utility = FCPXMLUtility.defaultForExtensions
		return utility.filter(fcpxElements: self.fcpxResources, ofTypes: [.formatResource])
	}

	/// An array of asset resources in the FCPXML document.
	public var fcpxAssetResources: [any PNXMLElement] {
		let utility = FCPXMLUtility.defaultForExtensions
		return utility.filter(fcpxElements: self.fcpxResources, ofTypes: [.assetResource])
	}

	/// An array of multicam resources in the FCPXML document.
	public var fcpxMulticamResources: [any PNXMLElement] {
		let utility = FCPXMLUtility.defaultForExtensions
		return utility.filter(fcpxElements: self.fcpxResources, ofTypes: [.multicamResource])
	}

	/// An array of compound clip resources in the FCPXML document.
	public var fcpxCompoundResources: [any PNXMLElement] {
		let utility = FCPXMLUtility.defaultForExtensions
		return utility.filter(fcpxElements: self.fcpxResources, ofTypes: [.compoundResource])
	}

	/// An array of effect resources in the FCPXML document.
	public var fcpxEffectResources: [any PNXMLElement] {
		let utility = FCPXMLUtility.defaultForExtensions
		return utility.filter(fcpxElements: self.fcpxResources, ofTypes: [.effectResource])
	}

	/// An array of all projects in all events in the FCPXML document.
	public var fcpxAllProjects: [any PNXMLElement] {
		var projects: [any PNXMLElement] = []
		let utility = FCPXMLUtility.defaultForExtensions
		for event in self.fcpxEvents {
			let eventChildrenElements = event.childElements
			let eventProjects = utility.filter(fcpxElements: eventChildrenElements, ofTypes: [.project])
			projects.append(contentsOf: eventProjects)
		}
		return projects
	}

	/// An array of all clips in all events in the FCPXML document.
	public var fcpxAllClips: [any PNXMLElement] {
		var clips: [any PNXMLElement] = []
		let utility = FCPXMLUtility.defaultForExtensions
		for event in self.fcpxEvents {
			let eventChildrenElements = event.childElements
			let eventClips = utility.filter(fcpxElements: eventChildrenElements, ofTypes: [.clip, .assetClip, .compoundClip, .multicamClip, .synchronizedClip])
			clips.append(contentsOf: eventClips)
		}
		return clips
	}

	// The FCPXML version number is obtained here, not during parsing. This way, the version number can be checked before parsing, which could break depending on the FCPXML version.
	/// The version of FCPXML used in this document.
	public var fcpxmlVersion: String? {
		get {
			fcpxmlElement?.stringValue(forAttributeNamed: "version")
		}

		set {
			if let newValue {
				self.fcpxmlElement?.addSafeAttribute(name: "version", value: newValue)
			} else {
				self.fcpxmlElement?.removeAttribute(forName: "version")
			}
		}
	}

	/// The names of all events as a String array.
	public var fcpxEventNames: [String] {
		var names: [String] = []

		for event in self.fcpxEvents {
			guard let name = event.fcpxName else {
				continue
			}

			names.append(name)
		}

		return names
	}

	/// All items from all events as a PNXMLElement array.
	public var fcpxAllEventItems: [any PNXMLElement] {
		var allItems: [any PNXMLElement] = []

		for event in self.fcpxEvents {
			guard let eventItems = event.eventItems else {
				continue
			}

			allItems.append(contentsOf: eventItems)
		}

		return allItems
	}

	/// The names of all items from all events.
	public var fcpxAllEventItemNames: [String] {
		var names: [String] = []

		for event in self.fcpxEvents {
			guard let clips = event.eventClips else {
				continue
			}

			for clip in clips {
				guard let name = clip.fcpxName else {
					continue
				}

				names.append(name)
			}
		}

		return names
	}

	/// The names of all projects from all events.
	public var fcpxAllProjectNames: [String] {
		var names: [String] = []

		for project in self.fcpxAllProjects {
			guard let name = project.fcpxName else {
				continue
			}

			names.append(name)
		}

		return names
	}

	// MARK: - Roles and IDs

	/// Returns an array of all roles used in the FCPXML document.
	///
	/// This function parses the entire XML document whenever called. Avoid calling it repeatedly and store the value separately instead.
	/// - Returns: An array of String values.
	public func fcpxAllRoles() -> [String] {
		self.parseFCPXML()

		return self.fcpxRoleAttributeValues
	}

	/// Returns the highest resource ID number used in the FCPXML document.
	///
	/// This function parses the entire XML document whenever called. Avoid calling it repeatedly and store the value separately instead.
	/// - Returns: An integer value.
	public func fcpxLastResourceID() -> Int {
		self.parseFCPXML()

		return self.fcpxResourceIDs.max() ?? 0
	}

	/// Returns the highest text style ID number used in the FCPXML document.
	///
	/// This function parses the entire XML document whenever called. Avoid calling it repeatedly and store the value separately instead.
	/// - Returns: An integer value.
	public func fcpxLastTextStyleID() -> Int {
		self.parseFCPXML()

		return self.fcpxTextStyleIDs.max() ?? 0
	}

	// MARK: - Retrieving Resources

	/// Returns the resource that matches the given ID string.
	///
	/// - Parameter id: The resource ID as a string in the form of "r1"
	/// - Returns: The matching resource element
	public func resource(matchingID id: String) -> (any PNXMLElement)? {
		for resource in self.fcpxResources {
			if resource.fcpxID == id {
				return resource
			}
		}

		return nil
	}

	/// Returns asset resources that match the given URL.
	///
	/// - Parameters:
	///   - url: The URL to match with.
	///   - usingFilenameOnly: True if matching with just the filename, false if matching with the entire URL path.
	///   - omittingExtension: True if matching without the extension in the filename, false if matching with the entire filename.
	///   - caseSensitive: True if the search should be case sensitive, false if it should not.
	/// - Returns: An array of PNXMLElement objects that are matching asset resources.
	public func assetResources(matchingURL url: URL, usingFilenameOnly: Bool, omittingExtension: Bool, caseSensitive: Bool) -> [any PNXMLElement] {

		let matchURL: URL

		if omittingExtension {
			matchURL = url.deletingPathExtension()
		} else {
			matchURL = url
		}

		var matchPath: String

		if usingFilenameOnly {
			matchPath = matchURL.lastPathComponent
		} else {
			matchPath = matchURL.path
		}

		if !caseSensitive {
			matchPath = matchPath.lowercased()
		}

		var matchingResources: [any PNXMLElement] = []

		for resource in self.fcpxAssetResources {
			guard let resourceURL = resource.fcpxSrc else {
				continue
			}

			var resourcePath: String

			if omittingExtension {
				resourcePath = resourceURL.deletingPathExtension().path
			} else {
				resourcePath = resourceURL.path
			}

			if usingFilenameOnly {
				resourcePath = resourceURL.lastPathComponent
			}

			if !caseSensitive {
				resourcePath = resourcePath.lowercased()
			}

			if resourcePath == matchPath {
				matchingResources.append(resource)
			}
		}

		return matchingResources
	}

	// MARK: - Adding Elements

	/// Adds resource elements to the FCPXML document.
	///
	/// - Parameter resourceElements: An array of PNXMLElement objects to add as resources.
	public func add(resourceElements: [any PNXMLElement]) {
		guard let resourceElement = self.fcpxResourceElement else {
			return
		}

		for resource in resourceElements {
			resourceElement.addChild(resource)
		}
	}

	/// Adds events to the FCPXML document.
	///
	/// - Parameter events: An array of PNXMLElement objects to add as events.
	public func add(events: [any PNXMLElement]) {
		guard let libraryElement = self.fcpxLibraryElement else {
			return
		}

		for event in events {
			libraryElement.addChild(event)
		}
	}

	/// Removes a resource from the FCPXML document.
	///
	/// - Parameter resourceAtIndex: The index of the resource to remove.
	public func remove(resourceAtIndex index: Int) {
		guard let resourceElement = self.fcpxResourceElement else {
			return
		}

		guard let resourceChildren = resourceElement.children else {
			return
		}

		if index < resourceChildren.count {
			resourceElement.removeChild(at: index)
		}
	}

	// MARK: - Validation

	/// Validates the FCPXML document against the specified version's DTD.
	///
	/// - Parameter version: The version number as a string (e.g. `"1.14"`).
	/// - Throws: An error describing the reason for the XML being invalid or another error, such as not being able to read or set the associated DTD file.
	public func validateFCPXMLAgainst(version: String) throws {
		do {
			try self.setDTDToFCPXML(version: version)
		} catch {
			if !(error is FCPXMLDocumentError) {
				debugLog("Error setting the DTD.")
			}
			self.dtd = nil
			throw error
		}

		do {
			try self.validate()
		} catch {
			debugLog("The document is invalid. It does not conform to the FCPXML v\(version) Document Type Definition.")
			debugLog("Validation Error: \(error)")
			self.dtd = nil
			throw error
		}

		debugLog("The document conforms to the FCPXML v\(version) Document Type Definition.")
		self.dtd = nil
	}

	/// Validates the FCPXML document against the specified version's DTD.
	///
	/// - Parameter version: The FCPXML version (e.g. `.v1_14`).
	/// - Throws: An error if the document is invalid or the DTD cannot be loaded.
	public func validateFCPXMLAgainst(version: FCPXMLVersion) throws {
		try validateFCPXMLAgainst(version: version.stringValue)
	}

	/// Generates the DTD filename for a given FCPXML version.
	///
	/// - Parameters:
	///   - version: The FCPXML version number as a string.
	///   - withExtension: Whether to include the .dtd extension in the returned filename.
	/// - Returns: The DTD filename for the specified version.
	private func fcpxmlDTDFilename(fromVersion version: String, withExtension: Bool) -> String {
		let baseName = "Final_Cut_Pro_XML_DTD_version_\(version)"
		return withExtension ? "\(baseName).dtd" : baseName
	}

	/// Sets the document's DTD to the specified FCPXML version number. The version number must match a DTD resource included in the bundle.
	///
	/// - Parameter version: The version number as a String.
	/// - Throws: If the DTD file cannot be read properly, an error is thrown describing the issue.
	private func setDTDToFCPXML(version: String) throws {
		let resourceName = self.fcpxmlDTDFilename(fromVersion: version, withExtension: false)
		try self.setDTDToBundleResource(named: resourceName)
	}

	/// Returns the PipelineNeo resource bundle when it lives next to the running executable (e.g. a copied CLI) or next to the test bundle (e.g. swift test).
	private static func _pipelineNeoBundleNextToExecutable() -> Bundle? {
		guard let arg0 = ProcessInfo.processInfo.arguments.first, !arg0.isEmpty else { return nil }
		let resolvedPath = (arg0 as NSString).resolvingSymlinksInPath
		let execDir: URL
		if resolvedPath.hasPrefix("/") {
			execDir = URL(fileURLWithPath: resolvedPath).deletingLastPathComponent()
		} else {
			let cwd = FileManager.default.currentDirectoryPath
			let fullPath = (cwd as NSString).appendingPathComponent(resolvedPath)
			execDir = URL(fileURLWithPath: (fullPath as NSString).resolvingSymlinksInPath).deletingLastPathComponent()
		}
		// 1) Next to the executable: try CLI bundle first (DTDs embedded in CLI), then library bundle.
		let bundleNames = ["PipelineNeo_PipelineNeoCLI.bundle", "PipelineNeo_PipelineNeo.bundle"]
		for name in bundleNames {
			let u = execDir.appendingPathComponent(name)
			if let b = Bundle(url: u) { return b }
		}
		// 2) When running inside an .xctest (swift test), bundle is a sibling of the .xctest in the build directory.
		if resolvedPath.contains(".xctest") {
			var cursor = execDir
			while cursor.path != "/" {
				if cursor.lastPathComponent.hasSuffix(".xctest") {
					let buildDir = cursor.deletingLastPathComponent()
					for name in bundleNames {
						let u = buildDir.appendingPathComponent(name)
						if let b = Bundle(url: u) { return b }
					}
					break
				}
				cursor = cursor.deletingLastPathComponent()
			}
		}
		// 3) When the main bundle is an app or xctest, its container directory often contains the resource bundle (e.g. swift test).
		let mainContainer = Bundle.main.bundleURL.deletingLastPathComponent()
		for name in bundleNames {
			let u = mainContainer.appendingPathComponent(name)
			if let b = Bundle(url: u) { return b }
		}
		return nil
	}

	/// True when we must not call Bundle.module (would fatalError: copied CLI run without the resource bundle).
	/// Skip only when the running executable is the pipeline-neo CLI (by name) and the resource bundle is not next to it.
	/// Invoke the CLI directly from scripts (e.g. "$TOOL_PATH" "$INPUT" ...) so argv[0] is the tool path; do not use `bash -c "..."` or the process will be the shell and we may crash.
	private static func _mustSkipBundleModule() -> Bool {
		guard let arg0 = ProcessInfo.processInfo.arguments.first, !arg0.isEmpty else { return false }
		var resolvedPath = (arg0 as NSString).resolvingSymlinksInPath
		if resolvedPath.hasSuffix("/") { resolvedPath = String(resolvedPath.dropLast()) }
		let execName = URL(fileURLWithPath: resolvedPath).lastPathComponent
		guard execName == "pipeline-neo" else { return false }
		let execDir: URL
		if resolvedPath.hasPrefix("/") {
			execDir = URL(fileURLWithPath: resolvedPath).deletingLastPathComponent()
		} else {
			let cwd = FileManager.default.currentDirectoryPath
			let fullPath = (cwd as NSString).appendingPathComponent(resolvedPath)
			execDir = URL(fileURLWithPath: (fullPath as NSString).resolvingSymlinksInPath).deletingLastPathComponent()
		}
		let cliBundle = execDir.appendingPathComponent("PipelineNeo_PipelineNeoCLI.bundle")
		let libBundle = execDir.appendingPathComponent("PipelineNeo_PipelineNeo.bundle")
		let hasBundle = FileManager.default.fileExists(atPath: cliBundle.path)
			|| FileManager.default.fileExists(atPath: libBundle.path)
		return !hasBundle
	}

	/// Sets the DTD to a specified bundle resource in this framework.
	///
	/// - Parameter name: The name of the resource as a String. Do not include the extension of the filename. It is assumed to be "dtd".
	/// - Throws: An FCPXMLDocumentError or an error describing why the file cannot be read.
	private func setDTDToBundleResource(named name: String) throws {
		let factory = FoundationXMLFactory()
		var dtdURL: URL? = nil
		let bundleNextToExecutable = Self._pipelineNeoBundleNextToExecutable()
		// Prefer bundle next to executable so a copied CLI (with the .bundle copied alongside) finds DTDs.
		if let bundle = bundleNextToExecutable {
			dtdURL = bundle.url(forResource: name, withExtension: "dtd", subdirectory: nil)
				?? bundle.url(forResource: name, withExtension: "dtd", subdirectory: "FCPXML DTDs")
		}
		// Use Bundle.module only when safe (not a copied CLI without the bundle; avoids fatalError from resource_bundle_accessor).
		if dtdURL == nil, !Self._mustSkipBundleModule() {
			dtdURL = Bundle.module.url(forResource: name, withExtension: "dtd", subdirectory: nil)
				?? Bundle.module.url(forResource: name, withExtension: "dtd", subdirectory: "FCPXML DTDs")
		}
		if dtdURL == nil {
			for bundle in Bundle.allBundles {
				if let u = bundle.url(forResource: name, withExtension: "dtd", subdirectory: nil)
					?? bundle.url(forResource: name, withExtension: "dtd", subdirectory: "FCPXML DTDs") {
					dtdURL = u
					break
				}
			}
		}
		if dtdURL == nil {
			for frameworkBundle in Bundle.allFrameworks {
				if let fileURL = frameworkBundle.url(forResource: name, withExtension: "dtd", subdirectory: "DTDs") {
					dtdURL = fileURL
					break
				}
			}
		}
		// Fallback: embedded DTD data (e.g. hardcoded in CLI).
		if dtdURL == nil, let data = EmbeddedDTDProvider.provide?(name) {
			do {
				let tempDir = FileManager.default.temporaryDirectory
				let tempURL = tempDir.appendingPathComponent("\(name).dtd")
				try data.write(to: tempURL)
				defer { try? FileManager.default.removeItem(at: tempURL) }
				self.dtd = try factory.makeDTD(contentsOf: tempURL, options: .fcpxmlDefaults)
			} catch {
				debugLog("Error loading embedded DTD: \(error)")
				throw error
			}
			if self.dtd != nil {
				self.dtd!.name = "fcpxml"
				self.isStandalone = false
				debugLog("DTD set from embedded data.")
				return
			}
		}
		guard let unwrappedURL = dtdURL else {
			debugLog("Couldn't find the DTD file.")
			throw FCPXMLDocumentError.dtdResourceNotFound
		}

		do {
			self.dtd = try factory.makeDTD(contentsOf: unwrappedURL, options: .fcpxmlDefaults)
		} catch {
			debugLog("Error reading the DTD file.")
			throw error
		}

		if self.dtd != nil {
			self.dtd!.name = "fcpxml"
			self.isStandalone = false

			debugLog("DTD set successfully.")
			return

		} else {
			debugLog("Failed to set the DTD.")
			return
		}
	}

	// MARK: - XML Parsing Methods

	/// Parses the resource IDs, text style IDs, and roles, refreshing the fcpxLastResourceID, fcpxLastTextStyleID, and fcpxRoles properties. Call this method when initially loading an FCPXML document and when the IDs or roles change.
	public func parseFCPXML() {
		let xmlParser = XMLParser(data: self.xmlData)
		let delegate = FCPXMLParserDelegate()

		xmlParser.delegate = delegate
		xmlParser.parse()

		// Extract resource ID numbers from resource IDs
		let resourceIDs = delegate.resourceIDs
		self.fcpxResourceIDs = resourceIDs.compactMap { resourceID in
			let idSlice = resourceID.dropFirst()
			return Int(idSlice)
		}.sorted()

		// Extract text style ID numbers from text style IDs
		let textStyleIDs = delegate.textStyleIDs
		self.fcpxTextStyleIDs = textStyleIDs.compactMap { textStyleID in
			let idSlice = textStyleID.dropFirst(2)
			return Int(idSlice)
		}.sorted()

		// Get unique roles
		let roles = delegate.roles
		self.fcpxRoleAttributeValues = Array(Set(roles)).sorted()

		return
	}

	// MARK: - Private Properties

	// Since extensions cannot contain stored properties, the properties below are defined as Objective-C associated objects.

	// Associated object keys (stable addresses, process-safe).
	private enum AssociatedKeys {
		nonisolated(unsafe) static var resourceIDs: UInt8 = 0
		nonisolated(unsafe) static var textStyleIDs: UInt8 = 0
		nonisolated(unsafe) static var roles: UInt8 = 0
	}

	// A stored property for all resource IDs in the FCPXML document.
	private var fcpxResourceIDs: [Int] {
		get {
			objc_getAssociatedObject(self, &AssociatedKeys.resourceIDs) as? [Int] ?? []
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.resourceIDs, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	// A stored property for all text style IDs in the FCPXML document.
	private var fcpxTextStyleIDs: [Int] {
		get {
			objc_getAssociatedObject(self, &AssociatedKeys.textStyleIDs) as? [Int] ?? []
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.textStyleIDs, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	// A stored property for all roles in the FCPXML document.
	private var fcpxRoleAttributeValues: [String] {
		get {
			objc_getAssociatedObject(self, &AssociatedKeys.roles) as? [String] ?? []
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.roles, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	// MARK: - Private Methods
	private func xmlElementArrayToStringArray(usingXMLArray xmlArray: [any PNXMLElement]) -> [String] {
		xmlArray.map { $0.xmlString }
	}

	private func stringArrayToXMLElementArray(usingStringArray stringArray: [String]) -> [any PNXMLElement] {
		stringArray.compactMap { stringItem in
			try? FoundationXMLFactory().makeElement(xmlString: stringItem)
		}
	}

	// MARK: - Constants

	/// Type used to define FCPXML document errors.
	///
	/// - DTDResourceNotFound: The DTD resource in the Pipeline framework was not found.
	/// - dtdResourceUnreadable: The DTD resource in the Pipeline framework was not readable.
	enum FCPXMLDocumentError: Error, Sendable {
		case dtdResourceNotFound
		case dtdResourceUnreadable
	}

#if canImport(Logging)
  	private static let logger = Logger(label: "PipelineNeo.FoundationXMLDocument")

  	private func debugLog(_ message: String) {
		FoundationXMLDocument.logger.debug("\(message)")
	}
#else
	private func debugLog(_ message: String) {
		print(message)
	}
#endif
}

#endif
