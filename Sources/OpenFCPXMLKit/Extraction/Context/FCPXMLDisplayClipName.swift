//
//  FCPXMLDisplayClipName.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Resolves workbook-style clip names from extracted element context.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Clip element types that can host effects and supply report clip names directly.
    static let reportClipHostTypes: Set<ElementType> = [
        .title,
        .assetClip,
        .syncClip,
        .refClip,
        .mcClip,
        .clip,
        .audio,
        .video
    ]
    
    /// Resolves the clip name shown in workbook report rows.
    enum DisplayClipName {
        /// Title/generator clips use the referenced effect resource name when available;
        /// other clip types use the clip's `name` attribute.
        static func name(for extracted: some FCPXMLExtractedElement) -> String {
            if extracted.element.fcpElementType == .caption,
               let caption = extracted.element.fcpAsCaption
            {
                return caption.workbookInventoryClipName
            }
            
            if let elementType = extracted.element.fcpElementType,
               reportClipHostTypes.contains(elementType)
            {
                if elementType == .title {
                    return titleEffectName(
                        for: extracted.element,
                        resources: extracted.resources
                    )
                }
                
                if elementType == .mcClip {
                    return extracted.element.fcpWorkbookClipName(resources: extracted.resources)
                }
                
                if let name = extracted.element.fcpName, !name.isEmpty {
                    return name
                }
            }
            
            if extracted.element.fcpElementType == .title {
                return titleEffectName(
                    for: extracted.element,
                    resources: extracted.resources
                )
            }
            
            guard let clip = extracted.ancestorClipElement() else { return "" }
            
            if clip.fcpElementType == .title,
               let ref = clip.fcpRef,
               let resourceName = clip.fcpResource(forID: ref, in: extracted.resources)?.fcpName,
               !resourceName.isEmpty
            {
                return resourceName
            }
            
            return clip.fcpName ?? ""
        }
        
        private static func titleEffectName(
            for element: any OFKXMLElement,
            resources: (any OFKXMLElement)?
        ) -> String {
            if let ref = element.fcpRef,
               let resourceName = element.fcpResource(forID: ref, in: resources)?.fcpName,
               !resourceName.isEmpty
            {
                return resourceName
            }
            
            return element.fcpName ?? ""
        }
    }
}
