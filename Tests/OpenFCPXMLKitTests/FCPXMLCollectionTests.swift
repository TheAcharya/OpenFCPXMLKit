//
//  FCPXMLCollectionTests.swift
//  OpenFCPXMLKitTests
//  © 2026 • Licensed under MIT License
//

import XCTest
@testable import OpenFCPXMLKit

final class FCPXMLCollectionTests: XCTestCase {
    
    // MARK: - KeywordCollection Tests
    
    func testKeywordCollectionInitialization() {
        let collection = FinalCutPro.FCPXML.KeywordCollection(name: "My Keywords")
        
        XCTAssertEqual(collection.name, "My Keywords")
    }
    
    func testKeywordCollectionCodable() throws {
        let collection = FinalCutPro.FCPXML.KeywordCollection(name: "Test Keywords")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(collection)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.KeywordCollection.self, from: data)
        
        XCTAssertEqual(decoded.name, collection.name)
    }
    
    // MARK: - CollectionFolder Tests
    
    func testCollectionFolderInitialization() {
        let folder = FinalCutPro.FCPXML.CollectionFolder(name: "My Folder")
        
        XCTAssertEqual(folder.name, "My Folder")
        XCTAssertEqual(folder.collectionFolders.count, 0)
        XCTAssertEqual(folder.keywordCollections.count, 0)
    }
    
    func testCollectionFolderWithSubfolders() {
        let subfolder1 = FinalCutPro.FCPXML.CollectionFolder(name: "Subfolder 1")
        let subfolder2 = FinalCutPro.FCPXML.CollectionFolder(name: "Subfolder 2")
        
        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Parent Folder",
            collectionFolders: [subfolder1, subfolder2]
        )
        
        XCTAssertEqual(folder.collectionFolders.count, 2)
        XCTAssertEqual(folder.collectionFolders[0].name, "Subfolder 1")
        XCTAssertEqual(folder.collectionFolders[1].name, "Subfolder 2")
    }
    
    func testCollectionFolderWithKeywordCollections() {
        let keywordCollection1 = FinalCutPro.FCPXML.KeywordCollection(name: "Keywords 1")
        let keywordCollection2 = FinalCutPro.FCPXML.KeywordCollection(name: "Keywords 2")
        
        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "My Folder",
            keywordCollections: [keywordCollection1, keywordCollection2]
        )
        
        XCTAssertEqual(folder.keywordCollections.count, 2)
        XCTAssertEqual(folder.keywordCollections[0].name, "Keywords 1")
        XCTAssertEqual(folder.keywordCollections[1].name, "Keywords 2")
    }
    
    func testCollectionFolderNested() {
        let keywordCollection = FinalCutPro.FCPXML.KeywordCollection(name: "Nested Keywords")
        let subfolder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Nested Folder",
            keywordCollections: [keywordCollection]
        )
        
        let parentFolder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Parent Folder",
            collectionFolders: [subfolder]
        )
        
        XCTAssertEqual(parentFolder.collectionFolders.count, 1)
        XCTAssertEqual(parentFolder.collectionFolders[0].name, "Nested Folder")
        XCTAssertEqual(parentFolder.collectionFolders[0].keywordCollections.count, 1)
    }
    
    func testCollectionFolderCodable() throws {
        let keywordCollection = FinalCutPro.FCPXML.KeywordCollection(name: "Test Keywords")
        let folder = FinalCutPro.FCPXML.CollectionFolder(
            name: "Test Folder",
            keywordCollections: [keywordCollection]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(folder)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FinalCutPro.FCPXML.CollectionFolder.self, from: data)
        
        XCTAssertEqual(decoded.name, folder.name)
        XCTAssertEqual(decoded.keywordCollections.count, folder.keywordCollections.count)
        XCTAssertEqual(decoded.keywordCollections[0].name, folder.keywordCollections[0].name)
    }
}
