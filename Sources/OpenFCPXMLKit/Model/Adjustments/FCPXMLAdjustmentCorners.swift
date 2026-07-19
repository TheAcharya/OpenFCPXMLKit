//
//  FCPXMLAdjustmentCorners.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Corners adjustment model (adjust-corners) for four-corner distortion.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Distorts the image by independently offsetting each corner.
    ///
    /// Corresponds to the FCPXML ``adjust-corners`` element (present since early DTD
    /// versions; part of intrinsic video parameters). Corner offsets default to
    /// `"0 0"` in the DTD when omitted.
    ///
    /// Optional nested ``param`` children are preserved for forward compatibility.
    public struct CornersAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Whether the adjustment is enabled (`enabled` attribute; default `true`).
        public var isEnabled: Bool

        /// Bottom-left corner offset (DTD `botLeft`).
        public var bottomLeft: Point

        /// Top-left corner offset (DTD `topLeft`).
        public var topLeft: Point

        /// Top-right corner offset (DTD `topRight`).
        public var topRight: Point

        /// Bottom-right corner offset (DTD `botRight`).
        public var bottomRight: Point

        /// Nested filter-style parameters, if present.
        public var parameters: [FilterParameter]

        /// Creates a corners adjustment.
        /// - Parameters:
        ///   - isEnabled: Whether the adjustment is enabled (default `true`).
        ///   - bottomLeft: Bottom-left offset (default `.zero`).
        ///   - topLeft: Top-left offset (default `.zero`).
        ///   - topRight: Top-right offset (default `.zero`).
        ///   - bottomRight: Bottom-right offset (default `.zero`).
        ///   - parameters: Nested `param` children (default empty).
        public init(
            isEnabled: Bool = true,
            bottomLeft: Point = .zero,
            topLeft: Point = .zero,
            topRight: Point = .zero,
            bottomRight: Point = .zero,
            parameters: [FilterParameter] = []
        ) {
            self.isEnabled = isEnabled
            self.bottomLeft = bottomLeft
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomRight = bottomRight
            self.parameters = parameters
        }
    }
}
