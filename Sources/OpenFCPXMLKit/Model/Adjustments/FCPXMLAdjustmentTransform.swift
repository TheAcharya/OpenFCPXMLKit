//
//  FCPXMLAdjustmentTransform.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Transform adjustment model for position, scale, rotation, and anchor.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A transform adjustment that modifies position, scale, rotation, and anchor point.
    ///
    /// - SeeAlso: [FCPXML Transform Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-transform
    ///   )
    public struct TransformAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The position of the transform adjustment.
        public var position: Point
        
        /// The scale of the transform adjustment.
        public var scale: Point
        
        /// The rotation of the transform adjustment.
        public var rotation: Double
        
        /// The anchor point of the transform adjustment.
        public var anchor: Point
        
        /// A Boolean value indicating whether the transform adjustment is enabled.
        public var isEnabled: Bool
        
        private enum CodingKeys: String, CodingKey {
            case position, scale, rotation, anchor
            case isEnabled = "enabled"
        }
        
        /// Initializes a new transform adjustment.
        /// - Parameters:
        ///   - position: The position of the transform adjustment (default: `.zero`).
        ///   - scale: The scale of the transform adjustment (default: `Point(x: 1, y: 1)`).
        ///   - rotation: The rotation of the transform adjustment (default: `0`).
        ///   - anchor: The anchor point of the transform adjustment (default: `.zero`).
        ///   - isEnabled: Whether the adjustment is enabled (default: `true`).
        public init(
            position: Point = .zero,
            scale: Point = Point(x: 1, y: 1),
            rotation: Double = 0,
            anchor: Point = .zero,
            isEnabled: Bool = true
        ) {
            self.position = position
            self.scale = scale
            self.rotation = rotation
            self.anchor = anchor
            self.isEnabled = isEnabled
        }
        
        /// Creates a transform adjustment from an `adjust-transform` XML element.
        public init(from adjustElement: any OFKXMLElement) {
            let enabledString = adjustElement.stringValue(forAttributeNamed: "enabled") ?? "1"
            let isEnabled = enabledString == "1"
            
            let positionString = adjustElement.stringValue(forAttributeNamed: "position") ?? "0 0"
            let position = Point(fromString: positionString) ?? .zero
            
            let scaleString = adjustElement.stringValue(forAttributeNamed: "scale") ?? "1 1"
            let scale = Point(fromString: scaleString) ?? Point(x: 1, y: 1)
            
            let rotationString = adjustElement.stringValue(forAttributeNamed: "rotation") ?? "0"
            let rotation = Double(rotationString) ?? 0
            
            let anchorString = adjustElement.stringValue(forAttributeNamed: "anchor") ?? "0 0"
            let anchor = Point(fromString: anchorString) ?? .zero
            
            self.init(
                position: position,
                scale: scale,
                rotation: rotation,
                anchor: anchor,
                isEnabled: isEnabled
            )
        }
        
        /// Unique position, rotation, and scale samples from attributes and nested `param` keyframes.
        ///
        /// Attribute values are included only when the attribute is present. Nested `param`
        /// children (including `keyframeAnimation` and split X/Y position params) are appended
        /// in document order. Identity defaults are not synthesized for omitted attributes.
        public struct ComponentSamples: Sendable, Equatable {
            /// Position samples (`x y`), in document order.
            public var positions: [Point]
            
            /// Rotation samples in degrees, in document order.
            public var rotations: [Double]
            
            /// Scale samples (`x y` factors, `1 1` = 100%), in document order.
            public var scales: [Point]
            
            /// Creates a set of transform component samples.
            public init(
                positions: [Point] = [],
                rotations: [Double] = [],
                scales: [Point] = []
            ) {
                self.positions = positions
                self.rotations = rotations
                self.scales = scales
            }
        }
        
        /// Collects position, rotation, and scale samples from an `adjust-transform` element.
        public static func componentSamples(
            from adjustElement: any OFKXMLElement
        ) -> ComponentSamples {
            var positions: [Point] = []
            var rotations: [Double] = []
            var scales: [Point] = []
            
            if let positionString = adjustElement.stringValue(forAttributeNamed: "position"),
               let position = Point(fromString: positionString)
            {
                positions.append(position)
            }
            if let scaleString = adjustElement.stringValue(forAttributeNamed: "scale"),
               let scale = Point(fromString: scaleString)
            {
                scales.append(scale)
            }
            if let rotationString = adjustElement.stringValue(forAttributeNamed: "rotation"),
               let rotation = Double(rotationString)
            {
                rotations.append(rotation)
            }
            
            for param in childParams(of: adjustElement) {
                switch param.stringValue(forAttributeNamed: "name")?.lowercased() {
                case "position":
                    positions.append(contentsOf: positionSamples(fromPositionParam: param))
                case "scale":
                    scales.append(contentsOf: pointSamples(from: param))
                case "rotation":
                    rotations.append(contentsOf: scalarSamples(from: param))
                default:
                    break
                }
            }
            
            return ComponentSamples(
                positions: uniquedPoints(positions),
                rotations: uniquedScalars(rotations),
                scales: uniquedPoints(scales)
            )
        }
        
        private static func childParams(of element: any OFKXMLElement) -> [any OFKXMLElement] {
            element.childElements.filter { $0.name == "param" }
        }
        
        private static func positionSamples(
            fromPositionParam param: any OFKXMLElement
        ) -> [Point] {
            let nested = childParams(of: param)
            let xParam = nested.first {
                $0.stringValue(forAttributeNamed: "name")?.lowercased() == "x"
            }
            let yParam = nested.first {
                $0.stringValue(forAttributeNamed: "name")?.lowercased() == "y"
            }
            
            if xParam != nil || yParam != nil {
                return pairedPositionSamples(xParam: xParam, yParam: yParam)
            }
            
            return pointSamples(from: param)
        }
        
        private static func pairedPositionSamples(
            xParam: (any OFKXMLElement)?,
            yParam: (any OFKXMLElement)?
        ) -> [Point] {
            let xs = timedScalars(from: xParam)
            let ys = timedScalars(from: yParam)
            guard !xs.isEmpty || !ys.isEmpty else { return [] }
            
            let xsHaveTimes = xs.contains { $0.time != nil }
            let ysHaveTimes = ys.contains { $0.time != nil }
            if !xsHaveTimes && !ysHaveTimes {
                let count = max(xs.count, ys.count)
                return (0..<count).map { index in
                    Point(
                        x: index < xs.count ? xs[index].value : 0,
                        y: index < ys.count ? ys[index].value : 0
                    )
                }
            }
            
            var times: Set<Double> = []
            for sample in xs { times.insert(sample.seconds) }
            for sample in ys { times.insert(sample.seconds) }
            
            return times.sorted().map { time in
                Point(
                    x: heldValue(xs, at: time),
                    y: heldValue(ys, at: time)
                )
            }
        }
        
        private static func pointSamples(from element: any OFKXMLElement) -> [Point] {
            keyframeValueStrings(in: element).compactMap { Point(fromString: $0.value) }
        }
        
        private static func scalarSamples(from element: any OFKXMLElement) -> [Double] {
            keyframeValueStrings(in: element).compactMap { Double($0.value) }
        }
        
        private static func timedScalars(
            from element: (any OFKXMLElement)?
        ) -> [TimedScalar] {
            guard let element else { return [] }
            return keyframeValueStrings(in: element).compactMap { sample in
                guard let value = Double(sample.value) else { return nil }
                return TimedScalar(time: sample.time, value: value)
            }
        }
        
        private static func keyframeValueStrings(
            in element: any OFKXMLElement
        ) -> [(time: String?, value: String)] {
            if let animation = element.firstChildElement(named: "keyframeAnimation") {
                return animation.childElements
                    .filter { $0.name == "keyframe" }
                    .compactMap { keyframe in
                        guard let value = keyframe.stringValue(forAttributeNamed: "value") else {
                            return nil
                        }
                        return (keyframe.stringValue(forAttributeNamed: "time"), value)
                    }
            }
            
            if let value = element.stringValue(forAttributeNamed: "value") {
                return [(nil, value)]
            }
            
            return []
        }
        
        private static func heldValue(_ samples: [TimedScalar], at time: Double) -> Double {
            guard !samples.isEmpty else { return 0 }
            let sorted = samples.sorted { $0.seconds < $1.seconds }
            var current = sorted[0].value
            for sample in sorted where sample.seconds <= time {
                current = sample.value
            }
            return current
        }
        
        private static func uniquedPoints(_ points: [Point]) -> [Point] {
            var seen: Set<String> = []
            var result: [Point] = []
            for point in points {
                let key = String(format: "%.4f %.4f", point.x, point.y)
                if seen.insert(key).inserted {
                    result.append(point)
                }
            }
            return result
        }
        
        private static func uniquedScalars(_ values: [Double]) -> [Double] {
            var seen: Set<String> = []
            var result: [Double] = []
            for value in values {
                let key = String(format: "%.4f", value)
                if seen.insert(key).inserted {
                    result.append(value)
                }
            }
            return result
        }
        
        private struct TimedScalar {
            var time: String?
            var value: Double
            
            var seconds: Double {
                guard let time else { return 0 }
                return fcpxmlTimeSeconds(time)
            }
        }
        
        private static func fcpxmlTimeSeconds(_ string: String) -> Double {
            let trimmed = string.hasSuffix("s") ? String(string.dropLast()) : string
            if let slash = trimmed.firstIndex(of: "/") {
                let numerator = Double(trimmed[..<slash]) ?? 0
                let denominator = Double(trimmed[trimmed.index(after: slash)...]) ?? 1
                guard denominator != 0 else { return 0 }
                return numerator / denominator
            }
            return Double(trimmed) ?? 0
        }
    }
}
