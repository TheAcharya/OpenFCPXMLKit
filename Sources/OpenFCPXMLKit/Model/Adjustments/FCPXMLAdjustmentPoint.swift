//
//  FCPXMLAdjustmentPoint.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Point type for adjustment models (position, scale, anchor).
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A structure that contains a point in a two-dimensional coordinate system.
    ///
    /// Used for adjustment properties such as position, scale, and anchor point.
    public struct Point: Sendable, Equatable, Hashable, Codable {
        /// The x value of the point.
        public var x: Double
        
        /// The y value of the point.
        public var y: Double
        
        /// The point with location (0,0).
        public static let zero = Point(x: 0, y: 0)
        
        /// Initializes a new point.
        /// - Parameters:
        ///   - x: The x value of the point.
        ///   - y: The y value of the point.
        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
        
        /// Creates a point from a space-separated string (e.g., "100 200").
        /// - Parameter string: A string containing two space-separated numbers.
        public init?(fromString string: String) {
            let components = string.components(separatedBy: " ")
            guard components.count == 2,
                  let x = Double(components[0]),
                  let y = Double(components[1]) else {
                return nil
            }
            self.x = x
            self.y = y
        }
        
        /// Returns a space-separated string representation (e.g., "100 200").
        public var stringValue: String {
            let xStr = x.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", x) : String(x)
            let yStr = y.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", y) : String(y)
            return "\(xStr) \(yStr)"
        }
    }
}
