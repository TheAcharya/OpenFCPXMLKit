//
// FCPXMLReportMediaResolutionPolicy.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Fail-soft vs fail-loud policy for report media / projection resolution.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// How report building treats unresolvable timeline projection or media geometry.
    ///
    /// Missing **files on disk** always remain Media Summary sheet content under either mode.
    /// This policy controls whether Projection / resource geometry failures abort the build.
    public enum ReportMediaResolutionPolicy: String, Sendable, Equatable, CaseIterable {
        /// Continue with empty projection windows and best-effort sections (default).
        case failSoft = "fail-soft"

        /// Throw ``ReportError/projectionFailed(_:)`` when timeline projection fails.
        case failLoud = "fail-loud"

        /// CLI / help values (`fail-soft`, `fail-loud`).
        public static var cliHelpValues: String {
            allCases.map(\.rawValue).joined(separator: ", ")
        }

        /// Parses a CLI string (`fail-soft` / `fail-loud`, with camelCase aliases).
        public init?(cliValue: String) {
            let normalized = cliValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch normalized {
            case Self.failSoft.rawValue, "failsoft":
                self = .failSoft
            case Self.failLoud.rawValue, "failloud":
                self = .failLoud
            default:
                return nil
            }
        }
    }
}
