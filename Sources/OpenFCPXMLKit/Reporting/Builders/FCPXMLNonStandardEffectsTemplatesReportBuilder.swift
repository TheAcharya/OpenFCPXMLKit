//
//  FCPXMLNonStandardEffectsTemplatesReportBuilder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	Builds Non-Standard Effects & Templates from effect resources.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Inventories non-Apple effect resources (and missing Motion template paths).
    enum NonStandardEffectsTemplatesReportBuilder {
        static func build(
            document: any OFKXMLDocument,
            baseURL: URL?
        ) -> NonStandardEffectsTemplatesReportSection {
            guard let resources = document.rootElement()?
                .firstChildElement(whereFCPElementType: .resources)
            else {
                return NonStandardEffectsTemplatesReportSection(rows: [])
            }
            
            var rows: [NonStandardEffectTemplateReportRow] = []
            var seenUIDs = Set<String>()
            
            for child in resources.childElements {
                guard let effect = child.fcpAsEffect else { continue }
                guard !effect.isAppleSupplied else { continue }
                
                let uid = effect.uid
                guard !uid.isEmpty, seenUIDs.insert(uid).inserted else { continue }
                
                let path = resolvedTemplatePath(from: effect.src, baseURL: baseURL)
                let isMissing = path.map { !FileManager.default.fileExists(atPath: $0) } ?? false
                let displayName = effect.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                let baseName = (displayName?.isEmpty == false)
                    ? displayName!
                    : fallbackName(fromUID: uid)
                let name = isMissing ? "\(baseName) (MISSING)" : baseName
                
                rows.append(
                    NonStandardEffectTemplateReportRow(
                        name: name,
                        kind: kindLabel(forUID: uid, src: effect.src),
                        status: isMissing ? "MISSING" : "",
                        path: path ?? effect.src ?? "",
                        uid: uid
                    )
                )
            }
            
            rows.sort { lhs, rhs in
                let kindOrder = lhs.kind.localizedStandardCompare(rhs.kind)
                if kindOrder != .orderedSame { return kindOrder == .orderedAscending }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            
            return NonStandardEffectsTemplatesReportSection(rows: rows)
        }
        
        private static func kindLabel(forUID uid: String, src: String?) -> String {
            let haystack = ((src ?? "") + " " + uid).lowercased()
            if haystack.contains("generator") { return "Generator" }
            if haystack.contains("title") { return "Title" }
            if haystack.contains("transition") { return "Transition" }
            return "Effect"
        }
        
        private static func fallbackName(fromUID uid: String) -> String {
            if let last = uid.split(separator: "/").last, !last.isEmpty {
                return String(last)
                    .replacingOccurrences(of: ".motn", with: "")
                    .replacingOccurrences(of: ".moef", with: "")
                    .replacingOccurrences(of: ".motr", with: "")
                    .replacingOccurrences(of: ".moti", with: "")
            }
            return uid
        }
        
        private static func resolvedTemplatePath(from src: String?, baseURL: URL?) -> String? {
            guard let src, !src.isEmpty else { return nil }
            
            if src.hasPrefix("~/") {
                // `homeDirectoryForCurrentUser` is macOS-only; tilde expansion works on iOS too.
                return (src as NSString).expandingTildeInPath
            }
            
            if let url = URL(string: src), url.isFileURL {
                return url.path
            }
            
            if src.hasPrefix("/") {
                return src
            }
            
            if let baseURL {
                let resolved = URL(fileURLWithPath: src, relativeTo: baseURL).standardizedFileURL
                return resolved.path
            }
            
            return src
        }
    }
}

