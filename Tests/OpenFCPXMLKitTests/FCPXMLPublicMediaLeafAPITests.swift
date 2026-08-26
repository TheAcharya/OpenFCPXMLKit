//
//  FCPXMLPublicMediaLeafAPITests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

import OpenFCPXMLKit
import Testing

@Suite("Public primary media leaf API")
struct FCPXMLPublicMediaLeafAPITests {
    @Test("External clients can call all primary media leaf APIs")
    func publicAccessCompilesWithoutTestableImport() {
        let element = FinalCutPro.FCPXML.AssetClip().element

        #expect(element.fcpMediaURL() == nil)
        #expect(element.fcpMediaURL(kind: .originalMedia) == nil)

        let representations = element.fcpMediaRepresentationURLs()
        #expect(representations.original == nil)
        #expect(representations.proxy == nil)
    }
}
