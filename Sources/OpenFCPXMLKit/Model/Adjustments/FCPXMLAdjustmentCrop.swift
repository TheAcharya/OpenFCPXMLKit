//
//  FCPXMLAdjustmentCrop.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Crop adjustment model for modifying visible image width and height.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Modifies the visible image width and height by cropping, trimming, or panning.
    ///
    /// - SeeAlso: [FCPXML Crop Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-crop
    ///   )
    public struct CropAdjustment: Sendable, Equatable, Hashable, Codable {
        /// Specifies the mode of a crop adjustment.
        public enum Mode: String, Sendable, Equatable, Hashable, Codable {
            case trim
            case crop
            case pan
        }
        
        /// Defines the crop values of a crop adjustment.
        public struct CropRect: Sendable, Equatable, Hashable, Codable {
            /// The left value of the crop rect.
            public var left: Double
            
            /// The top value of the crop rect.
            public var top: Double
            
            /// The right value of the crop rect.
            public var right: Double
            
            /// The bottom value of the crop rect.
            public var bottom: Double
            
            /// Initializes a new crop rect.
            /// - Parameters:
            ///   - left: The left value of the crop rect.
            ///   - top: The top value of the crop rect.
            ///   - right: The right value of the crop rect.
            ///   - bottom: The bottom value of the crop rect.
            public init(left: Double, top: Double, right: Double, bottom: Double) {
                self.left = left
                self.top = top
                self.right = right
                self.bottom = bottom
            }
        }
        
        /// Defines the trim values of a crop adjustment.
        public struct TrimRect: Sendable, Equatable, Hashable, Codable {
            /// The left value of the trim rect.
            public var left: Double
            
            /// The top value of the trim rect.
            public var top: Double
            
            /// The right value of the trim rect.
            public var right: Double
            
            /// The bottom value of the trim rect.
            public var bottom: Double
            
            /// Initializes a new trim rect.
            /// - Parameters:
            ///   - left: The left value of the trim rect.
            ///   - top: The top value of the trim rect.
            ///   - right: The right value of the trim rect.
            ///   - bottom: The bottom value of the trim rect.
            public init(left: Double, top: Double, right: Double, bottom: Double) {
                self.left = left
                self.top = top
                self.right = right
                self.bottom = bottom
            }
        }
        
        /// Interpolation for a pan rect. FCPXML 1.15+. Default is `ease`.
        public enum PanRectInterpolation: String, Sendable, Equatable, Hashable, Codable {
            case linear
            case ease
            case easeIn
            case easeOut
        }

        /// Defines the pan values of a crop adjustment.
        public struct PanRect: Sendable, Equatable, Hashable, Codable {
            /// The left value of the pan rect.
            public var left: Double
            
            /// The top value of the pan rect.
            public var top: Double
            
            /// The right value of the pan rect.
            public var right: Double
            
            /// The bottom value of the pan rect.
            public var bottom: Double

            /// Pan interpolation. FCPXML 1.15+. Default `ease` matches the DTD and is omitted on write.
            public var interpolation: PanRectInterpolation
            
            /// Initializes a new pan rect.
            /// - Parameters:
            ///   - left: The left value of the pan rect.
            ///   - top: The top value of the pan rect.
            ///   - right: The right value of the pan rect.
            ///   - bottom: The bottom value of the pan rect.
            ///   - interpolation: Pan interpolation (default: `.ease`). FCPXML 1.15+.
            public init(
                left: Double,
                top: Double,
                right: Double,
                bottom: Double,
                interpolation: PanRectInterpolation = .ease
            ) {
                self.left = left
                self.top = top
                self.right = right
                self.bottom = bottom
                self.interpolation = interpolation
            }

            private enum CodingKeys: String, CodingKey {
                case left, top, right, bottom
                case interpolation = "interp"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                left = try container.decode(Double.self, forKey: .left)
                top = try container.decode(Double.self, forKey: .top)
                right = try container.decode(Double.self, forKey: .right)
                bottom = try container.decode(Double.self, forKey: .bottom)
                interpolation = try container.decodeIfPresent(PanRectInterpolation.self, forKey: .interpolation) ?? .ease
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(left, forKey: .left)
                try container.encode(top, forKey: .top)
                try container.encode(right, forKey: .right)
                try container.encode(bottom, forKey: .bottom)
                if interpolation != .ease {
                    try container.encode(interpolation, forKey: .interpolation)
                }
            }
        }
        
        /// The crop rect used for a crop mode crop adjustment.
        public var cropRect: CropRect?
        
        /// The trim rect used for a trim mode crop adjustment.
        public var trimRect: TrimRect?
        
        /// The pan rects used for a pan mode crop adjustment.
        public var panRects: [PanRect]?
        
        /// The mode of the crop adjustment.
        public var mode: Mode
        
        /// A Boolean value indicating whether the crop adjustment is enabled.
        public var isEnabled: Bool
        
        private enum CodingKeys: String, CodingKey {
            case cropRect = "crop-rect"
            case trimRect = "trim-rect"
            case panRects = "pan-rect"
            case mode, enabled
        }
        
        /// Initializes a new crop adjustment.
        /// - Parameters:
        ///   - mode: The mode of the crop adjustment.
        ///   - isEnabled: Whether the adjustment is enabled (default: `true`).
        public init(mode: Mode, isEnabled: Bool = true) {
            self.mode = mode
            self.isEnabled = isEnabled
        }
        
        /// Creates a crop adjustment from a decoder.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: An error if decoding fails.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mode = try container.decode(Mode.self, forKey: .mode)
            isEnabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
            cropRect = try container.decodeIfPresent(CropRect.self, forKey: .cropRect)
            trimRect = try container.decodeIfPresent(TrimRect.self, forKey: .trimRect)
            panRects = try container.decodeIfPresent([PanRect].self, forKey: .panRects)
        }
        
        /// Encodes the crop adjustment to a container.
        /// - Parameter encoder: The encoder to write data to.
        /// - Throws: An error if encoding fails.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(mode, forKey: .mode)
            if !isEnabled {
                try container.encode(isEnabled, forKey: .enabled)
            }
            try container.encodeIfPresent(cropRect, forKey: .cropRect)
            try container.encodeIfPresent(trimRect, forKey: .trimRect)
            try container.encodeIfPresent(panRects, forKey: .panRects)
        }
    }
}
