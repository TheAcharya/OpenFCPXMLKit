//
//  FCPXMLSpeedChangeFormatting.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Display strings for clip time-map (retime) speed changes.
//

import Foundation

extension FinalCutPro.FCPXML {
    enum SpeedChangeFormatting {
        /// Workbook effect/settings labels derived from the first and last `timept` values.
        static func retimeDisplay(from timeMap: TimeMap) -> (effect: String, settings: String)? {
            let points = Array(timeMap.timePoints)
            guard points.count >= 2 else { return nil }
            
            let first = points.first!
            let last = points.last!
            
            let deltaTime = last.time.doubleValue - first.time.doubleValue
            guard abs(deltaTime) > .ulpOfOne else { return nil }
            
            let deltaValue = last.originalTime.doubleValue - first.originalTime.doubleValue
            let percent = (deltaValue / deltaTime) * 100
            let formatted = String(format: "%.1f%%", percent)
            
            return (effect: "Retime \(formatted)", settings: formatted)
        }
    }
}
