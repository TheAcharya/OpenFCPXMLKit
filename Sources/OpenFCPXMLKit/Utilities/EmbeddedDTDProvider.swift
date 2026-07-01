//
//  EmbeddedDTDProvider.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Optional provider for DTD content by resource name (e.g. from hardcoded CLI data).
//

import Foundation

/// Allows supplying DTD data from memory (e.g. embedded in the CLI binary).
/// When set, the library uses this to load a DTD by name when no bundle resource is found.
/// The name is the DTD resource name without extension (e.g. `Final_Cut_Pro_XML_DTD_version_1.13`).
public enum EmbeddedDTDProvider {

	/// When non-nil, called with a DTD resource name; return the DTD file data or nil.
	/// Set once at process startup (e.g. by the CLI); reads are synchronized by the caller.
	nonisolated(unsafe) public static var provide: (@Sendable (String) -> Data?)?

	/// Returns DTD file data for the given resource name (no .dtd extension).
	/// Tries EmbeddedDTDProvider.provide first (so CLI embedded DTDs are used), then bundle resources. Used by the version converter to derive allowlists from the same DTDs (bundle or embedded) used for validation.
	public static func dtdData(forResourceName name: String) -> Data? {
		if let data = provide?(name) { return data }
		func urlFromBundle(_ bundle: Bundle) -> URL? {
			bundle.url(forResource: name, withExtension: "dtd", subdirectory: nil)
				?? bundle.url(forResource: name, withExtension: "dtd", subdirectory: "FCPXML DTDs")
		}
		if let u = urlFromBundle(Bundle.module), let data = try? Data(contentsOf: u) { return data }
		for bundle in Bundle.allBundles {
			if let u = urlFromBundle(bundle), let data = try? Data(contentsOf: u) { return data }
		}
		for bundle in Bundle.allFrameworks {
			if let u = bundle.url(forResource: name, withExtension: "dtd", subdirectory: "DTDs"), let data = try? Data(contentsOf: u) {
				return data
			}
		}
		return nil
	}
}
