//
//  ProjectionTiming.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Absolute timeline placement for nested / anchored projection walks.
//

import Foundation
import SwiftTimecode

extension FinalCutPro.FCPXML {
    /// Fraction-based absolute start composition for projection walks.
    ///
    /// Mirrors the Extraction absolute-start rule for story/clip placement:
    /// a child's `offset` is relative to the parent's local timeline (parent `start`
    /// or sequence `tcStart` when that is the last parent local origin).
    ///
    /// Arithmetic intentionally uses `Double` intermediates then reconversion. Model
    /// getters apply `conform-rate` via `Fraction(double:)`, and mixing those with
    /// literal FCPXML rationals can trap on `Int` overflow inside SwiftTimecode
    /// `Fraction` `+` / `-` / LCM. Projection timing only needs second-scale accuracy
    /// for occupancy and reporting.
    enum ProjectionTiming {
        /// Decimal places kept when reconverting projection timeline math to ``Fraction``.
        static let fractionPrecision: Int = 12

        /// Absolute sequence-local start for a child with the given `offset`.
        static func absoluteStart(
            offset: Fraction?,
            parentAbsoluteStart: Fraction,
            parentLocalStart: Fraction?
        ) -> Fraction {
            let childOffset = offset ?? .zero
            if let parentLocalStart {
                return adding(
                    parentAbsoluteStart,
                    subtracting(childOffset, parentLocalStart)
                )
            }
            return adding(parentAbsoluteStart, childOffset)
        }

        /// Local timeline origin exposed to nested / anchored children after entering
        /// this element (parent `start`, if present; otherwise `nil` so children add
        /// their offsets onto `absoluteStart` directly).
        static func localStartForChildren(of element: any OFKXMLElement) -> Fraction? {
            element.fcpStart
        }

        /// Safe `a + b` for projection timeline composition.
        static func adding(_ a: Fraction, _ b: Fraction) -> Fraction {
            Fraction(
                double: a.doubleValue + b.doubleValue,
                decimalPrecision: fractionPrecision
            )
        }

        /// Safe `a - b` for projection timeline composition.
        static func subtracting(_ a: Fraction, _ b: Fraction) -> Fraction {
            Fraction(
                double: a.doubleValue - b.doubleValue,
                decimalPrecision: fractionPrecision
            )
        }
    }
}
