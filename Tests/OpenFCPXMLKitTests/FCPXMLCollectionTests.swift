//
//  FCPXMLCollectionTests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Tests for KeywordCollection and CollectionFolder models.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("Collection")
struct FCPXMLCollectionTests {

    // MARK: - KeywordCollection Tests

    @Test("KeywordCollection initialization")
    func keywordCollectionInitialization() {
        let collection = FinalCutPro.FCPXML.KeywordCollection(name: "My Keywords")

        #expect(collection.name == "My Keywords")
    }

    @Test("KeywordCollection Codable")
    func keywordCollectionCodable() throws {
        let collection = FinalCutPro.FCPXML.KeywordCollection(name: "Test Keywords")

        let encoder = JSONEncoder()
        let data = try encoder.encode(collection)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeywordCollection.self, from: data)

        #expect(decoded.name == collection.name)
    }

    // MARK: - CollectionFolder Tests

    @Test("CollectionFolder initialization")
    func collectionFolderInitialization() {
        let folder = FinalCutPro.FCPXML.CollectionFolder(name: "My Folder")

        #expect(folder.name == "My Folder")
        #expect(folder.collectionFolders.count == 0)
        #expect(folder.keywordCollections.count == 0)
    }

    @Test("CollectionFolder with subfolders")
    func collectionFolderWithSubfolders() {
        let subfolder1 = FinalCutPro.FCPXML.CollectionFolder(name: "Subfolder 1")
        let subfolder2 = FinalCutPro.FCPXML.CollectionFolder(name: "Subfolder 2")

        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Parent Folder",
            collectionFolders: [subfolder1, subfolder2]
        )

        #expect(folder.collectionFolders.count == 2)
        #expect(folder.collectionFolders[0].name == "Subfolder 1")
        #expect(folder.collectionFolders[1].name == "Subfolder 2")
    }

    @Test("CollectionFolder with keyword collections")
    func collectionFolderWithKeywordCollections() {
        let keywordCollection1 = FinalCutPro.FCPXML.KeywordCollection(name: "Keywords 1")
        let keywordCollection2 = FinalCutPro.FCPXML.KeywordCollection(name: "Keywords 2")

        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "My Folder",
            keywordCollections: [keywordCollection1, keywordCollection2]
        )

        #expect(folder.keywordCollections.count == 2)
        #expect(folder.keywordCollections[0].name == "Keywords 1")
        #expect(folder.keywordCollections[1].name == "Keywords 2")
    }

    @Test("CollectionFolder nested")
    func collectionFolderNested() {
        let keywordCollection = FinalCutPro.FCPXML.KeywordCollection(name: "Nested Keywords")
        let subfolder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Nested Folder",
            keywordCollections: [keywordCollection]
        )

        let parentFolder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Parent Folder",
            collectionFolders: [subfolder]
        )

        #expect(parentFolder.collectionFolders.count == 1)
        #expect(parentFolder.collectionFolders[0].name == "Nested Folder")
        #expect(parentFolder.collectionFolders[0].keywordCollections.count == 1)
    }

    @Test("CollectionFolder Codable")
    func collectionFolderCodable() throws {
        let keywordCollection = FinalCutPro.FCPXML.KeywordCollection(name: "Test Keywords")
        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Test Folder",
            keywordCollections: [keywordCollection]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(folder)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.CollectionFolder.self, from: data)

        #expect(decoded.name == folder.name)
        #expect(decoded.keywordCollections.count == folder.keywordCollections.count)
        #expect(decoded.keywordCollections[0].name == folder.keywordCollections[0].name)
    }
}

