//
//  FCPXMLDTDAllowlistGenerator.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Parses FCPXML DTDs to derive element/attribute allowlists. The version converter
//	uses this at runtime (from embedded or bundle DTDs) for bulletproof stripping.
//

import Foundation

/// Parses DTD content to derive allowlists for version conversion. The version converter loads the target version's DTD (from bundle or embedded) and uses this to strip elements/attributes not in the DTD.
public enum FCPXMLDTDAllowlistGenerator {

    /// Parses DTD content and returns allowed element names and allowed attributes per element. Used automatically by the version converter when converting to a target version.
    public static func allowlist(fromDTDContent data: Data) -> (elements: Set<String>, attributes: [String: Set<String>]) {
        let text = String(data: data, encoding: .utf8) ?? ""
        return parseDTD(contents: text)
    }

    /// Parses all DTD files in `dtdDirectory` and writes `FCPXMLDTDAllowlists.swift` into `outputDirectory`. Optional build-time use; runtime stripping uses allowlist(fromDTDContent:) from embedded/bundle DTDs instead.
    public static func generate(dtdDirectory: URL, outputDirectory: URL) throws {
        let fileManager = FileManager.default
        let dtdPath = dtdDirectory.path
        guard let contents = try? fileManager.contentsOfDirectory(atPath: dtdPath) else {
            throw FCPXMLDTDAllowlistGeneratorError.cannotReadDTDDirectory(dtdPath)
        }

        let dtdFiles = contents
            .filter { $0.hasSuffix(".dtd") }
            .sorted { a, b in
                guard let va = version(from: a), let vb = version(from: b) else {
                    return a < b
                }
                if va.major != vb.major { return va.major < vb.major }
                return va.minor < vb.minor
            }

        var perVersionData: [(version: String, elements: Set<String>, attributes: [String: Set<String>])] = []

        for f in dtdFiles {
            let path = (dtdPath as NSString).appendingPathComponent(f)
            guard let data = fileManager.contents(atPath: path),
                  let text = String(data: data, encoding: .utf8) else {
                continue
            }
            guard let v = version(from: f) else { continue }
            let versionCase = swiftVersionCase(v.major, v.minor)
            let (elements, attributes) = parseDTD(contents: text)
            perVersionData.append((version: versionCase, elements: elements, attributes: attributes))
        }

        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let outputFile = outputDirectory.appendingPathComponent("FCPXMLDTDAllowlists.swift")
        let output = emitSwift(perVersionData: perVersionData)
        try output.write(to: outputFile, atomically: true, encoding: .utf8)
    }

    // MARK: - DTD parsing

    private static func version(from dtdFileName: String) -> (major: Int, minor: Int)? {
        let prefix = "Final_Cut_Pro_XML_DTD_version_"
        let suffix = ".dtd"
        guard dtdFileName.hasPrefix(prefix), dtdFileName.hasSuffix(suffix) else { return nil }
        let middle = String(dtdFileName.dropFirst(prefix.count).dropLast(suffix.count))
        let parts = middle.split(separator: ".")
        guard parts.count == 2,
              let major = Int(parts[0]),
              let minor = Int(parts[1]) else { return nil }
        return (major, minor)
    }

    private static func parseDTD(contents: String) -> (elements: Set<String>, attributes: [String: Set<String>]) {
        var elements = Set<String>()
        var attributes: [String: Set<String>] = [:]
        let lines = contents.components(separatedBy: .newlines)

        // First pass: collect parameter entities <!ENTITY % name " value "> or <!ENTITY % name ' value '>
        var paramEntities: [String: String] = [:]
        var currentEntityName: String?
        var currentEntityQuote: Character?
        var currentEntityValue: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let name = currentEntityName, let quote = currentEntityQuote {
                let endMarker = String([quote]) + ">"
                if trimmed.contains(endMarker) {
                    if let endIdx = trimmed.firstIndex(of: quote) {
                        let before = String(trimmed[..<endIdx]).trimmingCharacters(in: .whitespaces)
                        if !before.isEmpty { currentEntityValue.append(before) }
                    }
                    paramEntities[name] = currentEntityValue.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                    currentEntityName = nil
                    currentEntityQuote = nil
                    currentEntityValue = []
                } else {
                    currentEntityValue.append(trimmed)
                }
                continue
            }
            if trimmed.hasPrefix("<!ENTITY % ") {
                let remainder = trimmed.dropFirst("<!ENTITY % ".count)
                guard let spaceIdx = remainder.firstIndex(of: " ") else { continue }
                let name = String(remainder[..<spaceIdx]).trimmingCharacters(in: .whitespaces)
                let rest = String(remainder[remainder.index(after: spaceIdx)...]).trimmingCharacters(in: .whitespaces)
                let quoteChar: Character? = rest.hasPrefix("\"") ? "\"" : (rest.hasPrefix("'") ? "'" : nil)
                if let q = quoteChar {
                    let afterQuote = rest.dropFirst()
                    if let closeIdx = afterQuote.firstIndex(of: q) {
                        let value = String(afterQuote[..<closeIdx]).trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty, !value.isEmpty { paramEntities[name] = value }
                    } else {
                        currentEntityName = name
                        currentEntityQuote = q
                        currentEntityValue = afterQuote.isEmpty ? [] : [String(afterQuote)]
                    }
                }
                continue
            }

            if trimmed.hasPrefix("<!ELEMENT") {
                let remainder = trimmed.dropFirst("<!ELEMENT".count)
                let namePart = remainder.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1)
                if let first = namePart.first {
                    let name = String(first).trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { elements.insert(name) }
                }
            } else if trimmed.hasPrefix("<!ATTLIST") {
                let remainder = trimmed.dropFirst("<!ATTLIST".count).trimmingCharacters(in: .whitespaces)
                let parts = remainder.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                if parts.count >= 2 {
                    let elemName = String(parts[0])
                    let restOfLine = String(parts[1])
                    if !elemName.isEmpty {
                        elements.insert(elemName)
                        if attributes[elemName] == nil { attributes[elemName] = [] }
                        if restOfLine.hasPrefix("%"), let semicolonIdx = restOfLine.firstIndex(of: ";") {
                            let entityName = String(restOfLine[restOfLine.index(after: restOfLine.startIndex) ..< semicolonIdx])
                            let expanded = expandParameterEntity(entityName, entities: paramEntities, depth: 0)
                            let attrNames = attributeNamesFromExpandedAttlist(expanded)
                            for a in attrNames { attributes[elemName]?.insert(a) }
                        } else if !restOfLine.isEmpty {
                            let attrNames = attributeNamesFromExpandedAttlist(restOfLine)
                            for a in attrNames { attributes[elemName]?.insert(a) }
                            if attrNames.isEmpty, let first = restOfLine.split(separator: " ", omittingEmptySubsequences: true).first, !first.isEmpty {
                                attributes[elemName]?.insert(String(first))
                            }
                        }
                    }
                }
            }
        }

        // Ensure every declared element has an attribute entry (empty = no attributes allowed).
        for e in elements {
            if attributes[e] == nil { attributes[e] = [] }
        }

        return (elements, attributes)
    }

    /// Expand a parameter entity (e.g. media_attrs) and all nested %ref;s; depth limits cycles.
    private static func expandParameterEntity(_ name: String, entities: [String: String], depth: Int) -> String {
        guard depth < 20, let value = entities[name] else { return "" }
        var result = value
        var changed = true
        var iterations = 0
        while changed, iterations < 50 {
            changed = false
            iterations += 1
            for (entityName, entityValue) in entities {
                let ref = "%\(entityName);"
                if result.contains(ref) {
                    result = result.replacingOccurrences(of: ref, with: entityValue)
                    changed = true
                }
            }
        }
        return result
    }

    /// Parse expanded ATTLIST value (e.g. "format IDREF #REQUIRED duration %time; #IMPLIED") into attribute names.
    private static func attributeNamesFromExpandedAttlist(_ expanded: String) -> [String] {
        let tokens = expanded.split(whereSeparator: { $0.isWhitespace || $0 == "\n" }).map(String.init)
        var names: [String] = []
        var i = 0
        while i < tokens.count {
            let t = tokens[i]
            if t == "#REQUIRED" || t == "#IMPLIED" || t == "#FIXED" {
                if i >= 2 { names.append(tokens[i - 2]) }
                i += 1
                continue
            }
            if (t.hasPrefix("'") && t.hasSuffix("'")) || (t.hasPrefix("\"") && t.hasSuffix("\"")) {
                if i >= 2 { names.append(tokens[i - 2]) }
                i += 1
                continue
            }
            if t == ")" {
                var j = i - 1
                var depth = 1
                while j >= 0, depth > 0 {
                    if tokens[j] == ")" { depth += 1 }
                    else if tokens[j] == "(" { depth -= 1 }
                    j -= 1
                }
                if j >= 0 { names.append(tokens[j]) }
                i += 1
                continue
            }
            i += 1
        }
        return names
    }

    private static func swiftVersionCase(_ major: Int, _ minor: Int) -> String {
        "v1_\(minor)"
    }

    private static func emitSwift(perVersionData: [(version: String, elements: Set<String>, attributes: [String: Set<String>])]) -> String {
        var lines: [String] = []
        lines.append("//")
        lines.append("//  FCPXMLDTDAllowlists.swift")
        lines.append("//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit")
        lines.append("//  © 2026 • Licensed under MIT License")
        lines.append("//")
        lines.append("//")
        lines.append("//\tGenerated by FCPXMLDTDAllowlistGenerator – do not edit by hand.")
        lines.append("//\tOptional build-time generation; runtime uses allowlist(fromDTDContent:) from DTDs.")
        lines.append("//")
        lines.append("")
        lines.append("import Foundation")
        lines.append("")
        lines.append("/// DTD-derived allowlists per FCPXML version for bulletproof version conversion.")
        lines.append("/// Used by FCPXMLVersionConverter to strip elements/attributes not in the target version's DTD.")
        lines.append("enum FCPXMLDTDAllowlists {")
        lines.append("")
        lines.append("    /// Returns (allowed element names, allowed attributes per element) for the given version.")
        lines.append("    static func allowlist(for version: FCPXMLVersion) -> (elements: Set<String>, attributes: [String: Set<String>])? {")
        lines.append("        switch version {")
        for (version, _, _) in perVersionData {
            lines.append("        case .\(version):")
            lines.append("            return (elements: Self.elements_\(version), attributes: Self.attributes_\(version))")
        }
        lines.append("        }")
        lines.append("    }")
        lines.append("")

        for (version, elements, attributes) in perVersionData {
            let sortedElements = elements.sorted()
            lines.append("    private static let elements_\(version): Set<String> = [")
            for e in sortedElements { lines.append("        \"\(e)\",") }
            lines.append("    ]")
            lines.append("")
            let sortedElemNames = attributes.keys.sorted()
            lines.append("    private static let attributes_\(version): [String: Set<String>] = [")
            for elem in sortedElemNames {
                guard let attrs = attributes[elem] else { continue }
                let attrList = attrs.sorted().map { "\"\($0)\"" }.joined(separator: ", ")
                lines.append("        \"\(elem)\": [\(attrList)],")
            }
            lines.append("    ]")
            lines.append("")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }
}

public enum FCPXMLDTDAllowlistGeneratorError: Error, LocalizedError {
    case cannotReadDTDDirectory(String)

    public var errorDescription: String? {
        switch self {
        case .cannotReadDTDDirectory(let path):
            return "Cannot read DTD directory: \(path)"
        }
    }
}
