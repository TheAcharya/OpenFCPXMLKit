//
//  FCPXMLImportOption.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Import option model for controlling how Final Cut Pro imports FCPXML documents.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// An import option that controls how Final Cut Pro imports a FCPXML document.
    ///
    /// Import options are key-value pairs that specify import preferences such as:
    /// - Whether to copy or link assets (`copy assets`)
    /// - Whether to suppress warnings (`suppress warnings`)
    /// - The target library location (`library location`)
    ///
    /// - SeeAlso: [FCPXML Import Options Documentation](
    ///   https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/import-options
    ///   )
    public struct ImportOption: Sendable, Equatable, Hashable, Codable {
        /// The key of the import option.
        public let key: String
        
        /// The value of the import option.
        public let value: String
        
        /// Initializes a new import option.
        /// - Parameters:
        ///   - key: The key of the import option (e.g., `"copy assets"`, `"suppress warnings"`, `"library location"`).
        ///   - value: The value of the import option.
        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
    
    /// A container for a set of import options.
    ///
    /// The `import-options` element contains zero or more `option` elements, each specifying
    /// a key-value pair that controls how Final Cut Pro imports the FCPXML document.
    public struct ImportOptions: Sendable, Equatable, Hashable, Codable {
        /// The import options to be used when opening a FCPXML document in Final Cut Pro.
        public let options: [ImportOption]
        
        private enum CodingKeys: String, CodingKey {
            case options = "option"
        }
        
        /// Initializes a new import options container.
        /// - Parameter options: The import options included in the container. If empty or `nil`, returns `nil`.
        public init?(options: [ImportOption]?) {
            guard let options = options, !options.isEmpty else { return nil }
            self.options = options
        }
        
        /// Initializes a new import options container.
        /// - Parameter options: The import options included in the container.
        public init(options: [ImportOption]) {
            self.options = options
        }
    }
}

// MARK: - Convenience Initializers

extension FinalCutPro.FCPXML.ImportOption {
    /// Creates an import option specifying whether assets should be copied or linked.
    /// - Parameter shouldCopyAssets: `true` to copy assets, `false` to link them.
    /// - Returns: An import option with key `"copy assets"` and value `"1"` or `"0"`.
    public static func copyAssets(_ shouldCopyAssets: Bool) -> Self {
        Self(key: "copy assets", value: shouldCopyAssets ? "1" : "0")
    }
    
    /// Creates an import option specifying whether warnings should be suppressed.
    /// - Parameter shouldSuppressWarnings: `true` to suppress warnings, `false` otherwise.
    /// - Returns: An import option with key `"suppress warnings"` and value `"1"` or `"0"`.
    public static func suppressWarnings(_ shouldSuppressWarnings: Bool) -> Self {
        Self(key: "suppress warnings", value: shouldSuppressWarnings ? "1" : "0")
    }
    
    /// Creates an import option specifying the target library location.
    /// - Parameter location: The file URL of the library location. If the URL represents a directory,
    ///   the default library name is used. If no library exists at the location, a new library is created.
    /// - Returns: An import option with key `"library location"` and the location as the value.
    public static func libraryLocation(_ location: String) -> Self {
        Self(key: "library location", value: location)
    }
    
    /// Creates an import option specifying the target library location.
    /// - Parameter location: The file URL of the library location.
    /// - Returns: An import option with key `"library location"` and the location as the value.
    public static func libraryLocation(_ location: URL) -> Self {
        Self(key: "library location", value: location.absoluteString)
    }
}
