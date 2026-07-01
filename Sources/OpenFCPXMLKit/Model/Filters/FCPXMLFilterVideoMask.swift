//
//  FCPXMLFilterVideoMask.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Video filter mask model for masked video effects.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Describes the blend mode of a mask shape or mask isolation.
    public enum MaskBlendMode: String, Sendable, Equatable, Hashable, Codable {
        case add
        case subtract
        case multiply
    }
    
    /// A mask shape used in video filter masks.
    public struct MaskShape: Sendable, Equatable, Hashable, Codable {
        /// The name of the mask shape.
        public var name: String?
        
        /// A Boolean value indicating whether the mask shape is enabled.
        public var isEnabled: Bool
        
        /// The blend mode of the mask shape.
        public var blendMode: MaskBlendMode
        
        /// The parameters associated with the mask shape.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case name
            case isEnabled = "enabled"
            case blendMode
            case parameters = "param"
        }
        
        /// Initializes a new mask shape.
        /// - Parameters:
        ///   - name: The name of the mask shape (default: `nil`).
        ///   - blendMode: The blend mode (default: `.add`).
        ///   - isEnabled: Whether the mask is enabled (default: `true`).
        ///   - parameters: Mask parameters (default: `[]`).
        public init(
            name: String? = nil,
            blendMode: MaskBlendMode = .add,
            isEnabled: Bool = true,
            parameters: [FilterParameter] = []
        ) {
            self.name = name
            self.blendMode = blendMode
            self.isEnabled = isEnabled
            self.parameters = parameters
        }
    }
    
    /// A mask isolation used in video filter masks.
    public struct MaskIsolation: Sendable, Equatable, Hashable, Codable {
        /// The name of the mask isolation.
        public var name: String?
        
        /// A Boolean value indicating whether the mask isolation is enabled.
        public var isEnabled: Bool
        
        /// The blend mode of the mask isolation.
        public var blendMode: MaskBlendMode
        
        /// The data associated with the mask isolation.
        public var data: [KeyedData]
        
        /// The parameters associated with the mask isolation.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case name
            case isEnabled = "enabled"
            case blendMode
            case data
            case parameters = "param"
        }
        
        /// Initializes a new mask isolation.
        /// - Parameters:
        ///   - name: The name of the mask isolation (default: `nil`).
        ///   - blendMode: The blend mode (default: `.multiply`).
        ///   - isEnabled: Whether the mask is enabled (default: `true`).
        ///   - data: Associated data (default: `[]`).
        ///   - parameters: Mask parameters (default: `[]`).
        public init(
            name: String? = nil,
            blendMode: MaskBlendMode = .multiply,
            isEnabled: Bool = true,
            data: [KeyedData] = [],
            parameters: [FilterParameter] = []
        ) {
            self.name = name
            self.blendMode = blendMode
            self.isEnabled = isEnabled
            self.data = data
            self.parameters = parameters
        }
    }
    
    /// A video filter mask that applies a masked video effect.
    ///
    /// Video filter masks contain mask shapes, mask isolations, and video filters.
    ///
    /// - SeeAlso: [FCPXML Video Filter Mask Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/filter-video-mask
    ///   )
    public struct VideoFilterMask: Sendable, Equatable, Hashable, Codable {
        /// The mask shapes of the video filter mask.
        public var maskShapes: [MaskShape]
        
        /// The mask isolations of the video filter mask.
        public var maskIsolations: [MaskIsolation]
        
        /// The video filters of the video filter mask (primary and optional secondary).
        public var videoFilters: [VideoFilter]
        
        /// A Boolean value indicating whether the video filter mask is enabled.
        public var isEnabled: Bool
        
        /// A Boolean value indicating whether the video filter mask is inverted.
        public var isInverted: Bool
        
        private enum CodingKeys: String, CodingKey {
            case maskShapes = "mask-shape"
            case maskIsolations = "mask-isolation"
            case videoFilters = "filter-video"
            case isEnabled = "enabled"
            case isInverted = "inverted"
        }
        
        /// Initializes a new video filter mask.
        /// - Parameters:
        ///   - primaryVideoFilter: The primary video filter (required).
        ///   - secondaryVideoFilter: The secondary video filter (optional).
        ///   - maskShapes: Mask shapes (default: `[]`).
        ///   - maskIsolations: Mask isolations (default: `[]`).
        ///   - isEnabled: Whether the mask is enabled (default: `true`).
        ///   - isInverted: Whether the mask is inverted (default: `false`).
        public init(
            primaryVideoFilter: VideoFilter,
            secondaryVideoFilter: VideoFilter? = nil,
            maskShapes: [MaskShape] = [],
            maskIsolations: [MaskIsolation] = [],
            isEnabled: Bool = true,
            isInverted: Bool = false
        ) {
            self.videoFilters = [primaryVideoFilter, secondaryVideoFilter].compactMap { $0 }
            self.maskShapes = maskShapes
            self.maskIsolations = maskIsolations
            self.isEnabled = isEnabled
            self.isInverted = isInverted
        }
    }
}
