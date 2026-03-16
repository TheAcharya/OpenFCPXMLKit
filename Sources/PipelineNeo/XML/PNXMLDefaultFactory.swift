//
//  PNXMLDefaultFactory.swift
//  Pipeline Neo
//
//  Platform-dispatching factory that returns the appropriate XML backend.
//  On macOS/Linux (where Foundation XML is available), returns FoundationXMLFactory.
//  On iOS and other platforms, returns AEXMLBackendFactory.
//

import Foundation

/// Returns the default `PNXMLFactory` for the current platform.
///
/// - macOS / Linux (FoundationXML): `FoundationXMLFactory`
/// - iOS / tvOS / watchOS / visionOS: `AEXMLBackendFactory`
///
/// Use this function instead of directly instantiating `FoundationXMLFactory()`
/// to ensure cross-platform compatibility.
public func PNXMLDefaultFactory() -> any PNXMLFactory {
    #if canImport(FoundationXML) || os(macOS)
    return FoundationXMLFactory()
    #else
    return AEXMLBackendFactory()
    #endif
}
