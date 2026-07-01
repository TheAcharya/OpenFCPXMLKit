//
//  FCPXMLCollectionFolder.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Collection folder model for organizing collections.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// A container to group other collection elements.
    ///
    /// - SeeAlso: [FCPXML Collection Folder Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/collection-folder
    ///   )
    public struct CollectionFolder: Sendable, Equatable, Hashable, Codable {
        /// The collection subfolders contained in the collection folder.
        public var collectionFolders: [CollectionFolder]
        
        /// The keyword collections contained in the collection folder.
        public var keywordCollections: [KeywordCollection]
        
        /// The smart collections contained in the collection folder.
        /// Note: SmartCollection is not Sendable, so this property is excluded from Sendable conformance.
        // public var smartCollections: [SmartCollection] // TODO: Add when SmartCollection conforms to Sendable
        
        /// The name of the collection folder.
        public var name: String
        
        private enum CodingKeys: String, CodingKey {
            case collectionFolders = "collection-folder"
            case keywordCollections = "keyword-collection"
            // case smartCollections = "smart-collection" // TODO: Add when SmartCollection conforms to Sendable
            case name
        }
        
        /// Initializes a new collection folder.
        /// - Parameters:
        ///   - name: The name of the collection folder.
        ///   - collectionFolders: The collection subfolders (default: `[]`).
        ///   - keywordCollections: The keyword collections (default: `[]`).
        public init(
            name: String,
            collectionFolders: [CollectionFolder] = [],
            keywordCollections: [KeywordCollection] = []
        ) {
            self.name = name
            self.collectionFolders = collectionFolders
            self.keywordCollections = keywordCollections
        }
    }
}
