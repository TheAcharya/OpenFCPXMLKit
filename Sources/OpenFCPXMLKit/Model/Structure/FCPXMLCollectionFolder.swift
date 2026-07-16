//
// FCPXMLCollectionFolder.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
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

        /// Smart collections contained in the collection folder (Sendable snapshot).
        public var smartCollections: [SmartCollectionValue]
        
        /// The name of the collection folder.
        public var name: String
        
        private enum CodingKeys: String, CodingKey {
            case collectionFolders = "collection-folder"
            case keywordCollections = "keyword-collection"
            case smartCollections = "smart-collection"
            case name
        }
        
        /// Initializes a new collection folder.
        /// - Parameters:
        ///   - name: The name of the collection folder.
        ///   - collectionFolders: The collection subfolders (default: `[]`).
        ///   - keywordCollections: The keyword collections (default: `[]`).
        ///   - smartCollections: The smart collections (default: `[]`).
        public init(
            name: String,
            collectionFolders: [CollectionFolder] = [],
            keywordCollections: [KeywordCollection] = [],
            smartCollections: [SmartCollectionValue] = []
        ) {
            self.name = name
            self.collectionFolders = collectionFolders
            self.keywordCollections = keywordCollections
            self.smartCollections = smartCollections
        }
    }

    /// Sendable Codable snapshot of a smart collection for structure models
    /// that cannot store XML-backed ``SmartCollection`` values.
    public struct SmartCollectionValue: Sendable, Equatable, Hashable, Codable {
        public var name: String
        public var match: SmartCollection.MatchCriteria
        public var matchTexts: [MatchText]
        public var matchRatings: [MatchRatings]
        public var matchMedias: [MatchMedia]
        public var matchClips: [MatchClip]
        public var matchStabilizations: [MatchStabilization]
        public var matchKeywords: [MatchKeywords]
        public var matchShots: [MatchShot]
        public var matchProperties: [MatchProperty]
        public var matchTimes: [MatchTime]
        public var matchTimeRanges: [MatchTimeRange]
        public var matchRoles: [MatchRoles]
        public var matchUsages: [MatchUsage]
        public var matchRepresentations: [MatchRepresentation]
        public var matchMarkers: [MatchMarkers]
        public var matchAnalysisTypes: [MatchAnalysisType]

        public init(
            name: String,
            match: SmartCollection.MatchCriteria = .all,
            matchTexts: [MatchText] = [],
            matchRatings: [MatchRatings] = [],
            matchMedias: [MatchMedia] = [],
            matchClips: [MatchClip] = [],
            matchStabilizations: [MatchStabilization] = [],
            matchKeywords: [MatchKeywords] = [],
            matchShots: [MatchShot] = [],
            matchProperties: [MatchProperty] = [],
            matchTimes: [MatchTime] = [],
            matchTimeRanges: [MatchTimeRange] = [],
            matchRoles: [MatchRoles] = [],
            matchUsages: [MatchUsage] = [],
            matchRepresentations: [MatchRepresentation] = [],
            matchMarkers: [MatchMarkers] = [],
            matchAnalysisTypes: [MatchAnalysisType] = []
        ) {
            self.name = name
            self.match = match
            self.matchTexts = matchTexts
            self.matchRatings = matchRatings
            self.matchMedias = matchMedias
            self.matchClips = matchClips
            self.matchStabilizations = matchStabilizations
            self.matchKeywords = matchKeywords
            self.matchShots = matchShots
            self.matchProperties = matchProperties
            self.matchTimes = matchTimes
            self.matchTimeRanges = matchTimeRanges
            self.matchRoles = matchRoles
            self.matchUsages = matchUsages
            self.matchRepresentations = matchRepresentations
            self.matchMarkers = matchMarkers
            self.matchAnalysisTypes = matchAnalysisTypes
        }

        /// Snapshot an XML-backed smart collection into a Sendable value.
        public init(smartCollection: SmartCollection) {
            self.init(
                name: smartCollection.name,
                match: smartCollection.match,
                matchTexts: smartCollection.matchTexts,
                matchRatings: smartCollection.matchRatings,
                matchMedias: smartCollection.matchMedias,
                matchClips: smartCollection.matchClips,
                matchStabilizations: smartCollection.matchStabilizations,
                matchKeywords: smartCollection.matchKeywords,
                matchShots: smartCollection.matchShots,
                matchProperties: smartCollection.matchProperties,
                matchTimes: smartCollection.matchTimes,
                matchTimeRanges: smartCollection.matchTimeRanges,
                matchRoles: smartCollection.matchRoles,
                matchUsages: smartCollection.matchUsages,
                matchRepresentations: smartCollection.matchRepresentations,
                matchMarkers: smartCollection.matchMarkers,
                matchAnalysisTypes: smartCollection.matchAnalysisTypes
            )
        }
    }
}
