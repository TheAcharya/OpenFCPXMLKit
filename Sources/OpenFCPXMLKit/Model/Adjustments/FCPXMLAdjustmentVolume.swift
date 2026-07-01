//
//  FCPXMLAdjustmentVolume.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Volume adjustment model for audio volume control.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A volume adjustment that modifies audio volume.
    ///
    /// - SeeAlso: [FCPXML Volume Adjustment Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/adjust-volume
    ///   )
    public struct VolumeAdjustment: Sendable, Equatable, Hashable, Codable {
        /// The amount of the volume adjustment in decibels.
        public var amount: Double
        
        private enum CodingKeys: String, CodingKey {
            case amount
        }
        
        /// Initializes a new volume adjustment.
        /// - Parameter amount: The amount of the volume adjustment in decibels.
        public init(amount: Double) {
            self.amount = amount
        }
        
        /// Creates a volume adjustment from a decibel string (e.g., "3dB").
        /// - Parameter decibelString: A string containing a number followed by "dB".
        public init?(fromDecibelString decibelString: String) {
            let amountString = decibelString.replacingOccurrences(of: "dB", with: "").trimmingCharacters(in: .whitespaces)
            guard let amount = Double(amountString) else {
                return nil
            }
            self.amount = amount
        }
        
        /// Returns a decibel string representation (e.g., "3dB").
        public var decibelString: String {
            "\(amount)dB"
        }
    }
}
