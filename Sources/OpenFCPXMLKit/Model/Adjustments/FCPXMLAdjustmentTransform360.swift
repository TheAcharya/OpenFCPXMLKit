//
//  FCPXMLAdjustmentTransform360.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	360° video transform adjustment model.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Specifies the possible coordinate types in a 360 transform adjustment.
    public enum Transform360CoordinateType: String, Sendable, Equatable, Hashable, Codable {
        case spherical
        case cartesian
    }
    
    /// A 360° video transform adjustment that modifies 360° video positioning and orientation.
    ///
    /// - SeeAlso: [FCPXML 360 Transform Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-360-transform
    ///   )
    public struct Transform360Adjustment: Sendable, Equatable, Hashable, Codable {
        /// The coordinate type of the 360 transform adjustment.
        public var coordinateType: Transform360CoordinateType
        
        /// A Boolean value indicating whether the 360 transform adjustment is enabled.
        public var isEnabled: Bool
        
        /// The latitude of the 360 transform adjustment (for spherical coordinates).
        public var latitude: Double?
        
        /// The longitude of the 360 transform adjustment (for spherical coordinates).
        public var longitude: Double?
        
        /// The distance of the 360 transform adjustment (for spherical coordinates).
        public var distance: Double?
        
        /// The x position of the 360 transform adjustment (for cartesian coordinates).
        public var xPosition: Double?
        
        /// The y position of the 360 transform adjustment (for cartesian coordinates).
        public var yPosition: Double?
        
        /// The z position of the 360 transform adjustment (for cartesian coordinates).
        public var zPosition: Double?
        
        /// The x orientation of the 360 transform adjustment.
        public var xOrientation: Double?
        
        /// The y orientation of the 360 transform adjustment.
        public var yOrientation: Double?
        
        /// The z orientation of the 360 transform adjustment.
        public var zOrientation: Double?
        
        /// A Boolean value indicating whether auto orientation is enabled.
        public var autoOrient: Bool
        
        /// The convergence of the 360 transform adjustment.
        public var convergence: Double?
        
        /// The interaxial of the 360 transform adjustment.
        public var interaxial: Double?
        
        /// The parameters associated with the 360 transform adjustment.
        public var parameters: [FilterParameter]
        
        private enum CodingKeys: String, CodingKey {
            case coordinateType = "coordinates"
            case isEnabled = "enabled"
            case latitude
            case longitude
            case distance
            case xPosition
            case yPosition
            case zPosition
            case xOrientation
            case yOrientation
            case zOrientation
            case autoOrient
            case convergence
            case interaxial
            case parameters = "param"
        }
        
        /// Initializes a new 360 transform adjustment.
        /// - Parameters:
        ///   - coordinateType: The coordinate type of the 360 transform adjustment.
        ///   - isEnabled: Whether the adjustment is enabled (default: `true`).
        ///   - autoOrient: Whether auto orientation is enabled (default: `true`).
        ///   - parameters: The parameters associated with the adjustment (default: `[]`).
        public init(
            coordinateType: Transform360CoordinateType,
            isEnabled: Bool = true,
            autoOrient: Bool = true,
            parameters: [FilterParameter] = []
        ) {
            self.coordinateType = coordinateType
            self.isEnabled = isEnabled
            self.autoOrient = autoOrient
            self.parameters = parameters
        }
    }
}
