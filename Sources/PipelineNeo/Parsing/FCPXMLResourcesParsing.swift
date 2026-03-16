//
//  FCPXMLResourcesParsing.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Resource parsing utilities (root resources, lookup by ID).
//

import Foundation
import SwiftExtensions
import SwiftTimecode

extension PNXMLElement {
    /// FCPXML: Returns the root-level `fcpxml/resources` element.
    /// This may be called on any element within a FCPXML.
    public var fcpRootResources: (any PNXMLElement)? {
        fcpRoot?
            .firstChildElement(whereFCPElementType: .resources)
    }
    
    /// FCPXML: Returns the resource element for the given resource ID from within the root-level
    /// `fcpxml/resources` element.
    /// This may be called on any element within a FCPXML.
    ///
    /// - Parameters:
    ///   - resourceID: Resource identifier string. (ie: "r1")
    ///   - resources: Optionally supply a resources element.
    ///     If `nil`, the resources from the XML document will be located and used.
    ///     This may be useful with isolated testing when a full FCPXML document is not loaded and
    ///     the document does not contain any resources to be found.
    /// - Returns: Resource element corresponding to the given resource ID.
    public func fcpResource(
        forID resourceID: String,
        in resources: (any PNXMLElement)? = nil
    ) -> (any PNXMLElement)? {
        (resources ?? fcpRootResources)?
            .childElements
            .first(whereAttribute: "id", hasValue: resourceID)
    }
    
    /// FCPXML: Returns the resource element referenced by the current element.
    public func fcpResource(
        in resources: (any PNXMLElement)? = nil
    ) -> (any PNXMLElement)? {
        _fcpFirstResourceForElementOrAncestors(in: resources)
    }
    
}

// MARK: - Video Frame Rate (from Format Resource)

extension PNXMLElement {
    /// FCPXML: Returns the video frame rate for the given resource ID.
    /// The resource ID should be for a `format` resource.
    /// This may be called on any element.
    func _fcpVideoFrameRate(
        forResourceID id: String,
        in resources: (any PNXMLElement)? = nil
    ) -> VideoFrameRate? {
        guard let resource = fcpResource(forID: id, in: resources) else { return nil }
        
        // Note: other resource types may also contain frame rate information.
        guard resource.fcpElementType == .format else { return nil }
        
        return resource._fcpVideoFrameRate()
    }
    
    /// FCPXML: Returns the video frame rate for the given resource ID.
    /// Call this on a `format` resource element.
    func _fcpVideoFrameRate() -> VideoFrameRate? {
        // Note: other resource types may also contain frame rate information.
        guard fcpElementType == .format else { return nil }
        
        guard let format = fcpAsFormat else { return nil }
        
        let interlaced = format.fieldOrder != nil
        
        guard let frameDuration = format.frameDuration
        else { return nil }
        
        let fRate = VideoFrameRate(frameDuration: frameDuration, interlaced: interlaced)
        return fRate
    }
}

// MARK: - Timecode Frame Rate

extension PNXMLElement {
    /// FCPXML: Returns the timecode frame rate for the given timeline.
    func _fcpTimecodeFrameRate<S: Sequence<any PNXMLElement>>(
        source frameRateSource: FinalCutPro.FCPXML.FrameRateSource,
        breadcrumbs: S? = nil as [any PNXMLElement]?,
        resources: (any PNXMLElement)?
    ) -> TimecodeFrameRate? {
        switch frameRateSource {
        case .localToElement:
            if let rate = _fcpTimecodeFrameRate(in: resources) {
                return rate
            }
            
        case .mainTimeline:
            // find outermost timeline - the first storyline in breadcrumbs.
            // traverse starting from furthest ancestor.
            
            let breadcrumbTrail = ancestorElements(overrideWith: breadcrumbs, includingSelf: true)
            
            for breadcrumb in breadcrumbTrail.reversed() {
                if let rate = breadcrumb._fcpTimecodeFrameRate(in: resources) {
                    return rate
                }
            }
            
        case let .rate(rate):
            return rate
        }
        
        return nil
    }
    
    /// FCPXML: Returns the timecode frame rate for the given resource ID.
    /// Traverses parents to determine `tcFormat`.
    func _fcpTimecodeFrameRate(
        resourceID id: String,
        in resources: (any PNXMLElement)? = nil
    ) -> TimecodeFrameRate? {
        guard let tcFormat = _fcpTCFormatForElementOrAncestors()
        else { return nil }
        
        return _fcpTimecodeFrameRate(forResourceID: id, tcFormat: tcFormat, in: resources)
    }
    
    /// FCPXML: Returns the timecode frame rate for the given resource ID & `tcFormat`.
    func _fcpTimecodeFrameRate(
        forResourceID id: String,
        tcFormat: FinalCutPro.FCPXML.TimecodeFormat,
        in resources: (any PNXMLElement)? = nil
    ) -> TimecodeFrameRate? {
        guard let videoRate = _fcpVideoFrameRate(forResourceID: id, in: resources),
              let frameRate = videoRate.timecodeFrameRate(drop: tcFormat.isDrop)
        else { return nil }
        return frameRate
    }
    
    /// FCPXML: Returns the timecode frame rate for the given resource ID & `tcFormat`.
    /// Call this on a `format` resource element.
    func _fcpTimecodeFrameRate(
        tcFormat: FinalCutPro.FCPXML.TimecodeFormat
    ) -> TimecodeFrameRate? {
        guard let videoRate = _fcpVideoFrameRate(),
              let frameRate = videoRate.timecodeFrameRate(drop: tcFormat.isDrop)
        else { return nil }
        return frameRate
    }
    
    /// FCPXML: Returns the timecode frame rate for the given resource ID.
    /// Traverses parents to determine `format` (resource ID) and `tcFormat`.
    func _fcpTimecodeFrameRate(
        in resources: (any PNXMLElement)? = nil
    ) -> TimecodeFrameRate? {
        guard let format = _fcpFirstDefinedFormatResourceForElementOrAncestors(in: resources),
              let tcFormat = _fcpTCFormatForElementOrAncestors()
        else { return nil }
        
        return format.element._fcpTimecodeFrameRate(tcFormat: tcFormat)
    }
}

// MARK: - Resource Utils

extension PNXMLElement {
    /// FCPXML: Traverses the parents of the element and returns the resource corresponding to the
    /// nearest `format` attribute if found.
    ///
    /// - Returns: A resource element.
    func _fcpFirstResourceForElementOrAncestors(
        in resources: (any PNXMLElement)? = nil
    ) -> (any PNXMLElement)? {
        if let (_, resourceID) = ancestorElements(includingSelf: true).first(withAttribute: "ref") {
            return fcpResource(forID: resourceID, in: resources)
        }
        
        // fall back to checking for format
        if let (_, resourceID) = ancestorElements(includingSelf: true).first(withAttribute: "format") {
            return fcpResource(forID: resourceID, in: resources)
        }
        
        return nil
    }
}

// MARK: - Format Resource Utils

extension PNXMLElement {
    /// FCPXML: If the resource with the given ID is a `format`, it is returned.
    /// Otherwise, references are followed until a `format` is found.
    /// This may be called on any element within a FCPXML.
    ///
    /// - Returns: `format` resource element.
    func _fcpFormatResource(
        forResourceID resourceID: String,
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.Format? {
        guard let resource = fcpResource(forID: resourceID, in: resources)
        else { return nil }
        
        return resource._fcpFormatResource(in: resources)
    }
    
    /// FCPXML: If the resource is a `format`, it is returned.
    /// Otherwise, references are followed until a `format` is found.
    ///
    /// - Returns: `format` resource element.
    func _fcpFormatResource(
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.Format? {
        guard let elementType = fcpElementType,
              elementType.isResource
        else { return nil }
        
        switch elementType {
        case .asset:
            // an asset should contain a format attribute that we can use to look up the actual
            // format resource
            guard let assetFormatID = fcpFormat else { return nil }
            return _fcpFormatResource(forResourceID: assetFormatID, in: resources)
            
        case .media:
            // Note: implementation incomplete for remaining resource types.
            // Media resource parsing not yet implemented.
            return nil
            
        case .format:
            return self.fcpAsFormat
            
        case .effect:
            return nil // effects don't carry format info
            
        case .locator:
            return nil
            
        case .objectTracker:
            return nil
            
        default:
            return nil
        }
    }
    
    /// FCPXML: Traverses the parents of the element and returns the resource corresponding
    /// to the nearest `format` attribute if found.
    ///
    /// - Returns: `format` resource element.
    func _fcpFirstFormatResourceForElementOrAncestors(
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.Format? {
        if let (_, resourceID) = ancestorElements(includingSelf: true)
            .first(withAttribute: "format")
        {
            return fcpResource(forID: resourceID, in: resources)?.fcpAsFormat
        }
        
        // `ref` could point to any resource and not just format, ie: asset or effect.
        // we need to continue drilling into it.
        if let (_, refResourceID) = ancestorElements(includingSelf: true)
            .first(withAttribute: "ref"),
           let refResource = fcpResource(forID: refResourceID, in: resources)
        {
            if refResource.fcpElementType == .format {
                return refResource.fcpAsFormat
            } else {
                // recurse
                return refResource._fcpFirstFormatResourceForElementOrAncestors(in: resources)
            }
        }
        
        return nil
    }
    
    /// FCPXML: Traverses the parents of the element and returns the nearest defined resource.
    ///
    /// - Returns: `format` resource element.
    func _fcpFirstDefinedFormatResourceForElementOrAncestors(
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.Format? {
        // note that an audio clip may point to a resource with name `FFVideoFormatRateUndefined`.
        // this should not be an error case; instead, continue traversing.
        
        let result = walkAncestorElements(
            includingSelf: true,
            returning: FinalCutPro.FCPXML.Format.self
        ) { element in
            guard let foundFormat = element._fcpFirstFormatResourceForElementOrAncestors(in: resources)
            else { return .failure }
            
            if foundFormat.name == "FFVideoFormatRateUndefined" {
                return .continue
            }
            return .return(withValue: foundFormat)
        }
        
        switch result {
        case .exhaustedAncestors:
            return nil
        case .value(let r):
            return r
        case .failure:
            return nil
        }
    }
}

// MARK: - Media Resource Utils

extension PNXMLElement {
    /// Utility:
    /// If the resource with the given ID is a format, it is returned.
    /// Otherwise, references are followed until a format is found.
    ///
    /// - Returns: `media` resource element.
    func _fcpMediaResource(
        forResourceID resourceID: String,
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.Media? {
        guard let resource = fcpResource(forID: resourceID, in: resources),
              resource.fcpElementType == .media
        else { return nil }
        
        return resource.fcpAsMedia
    }
    
    /// FCPXML: Looks up the resource for the element and returns its `media-rep` element, if any.
    ///
    /// - Returns: `media-rep` element.
    func _fcpMediaRep(
        in resources: (any PNXMLElement)? = nil
    ) -> FinalCutPro.FCPXML.MediaRep? {
        guard let resource = _fcpFirstResourceForElementOrAncestors(in: resources),
              let elementType = resource.fcpElementType,
              elementType.isResource
        else { return nil }
        
        switch elementType {
        case .asset: return resource.fcpAsAsset?.mediaRep
        case .effect: return nil
        case .format: return nil
        case .locator: return nil // contains a URL but not a `media-rep`
        case .media: return nil // Note: media can contain sequence or multicam.
        case .objectTracker: return nil
        default: return nil
        }
    }
    
    /// FCPXML: Looks up the resource for the element and returns its media url, if any.
    func fcpMediaURL(
        in resources: (any PNXMLElement)? = nil
    ) -> URL? {
        guard let resource = _fcpFirstResourceForElementOrAncestors(in: resources),
              let elementType = resource.fcpElementType,
              elementType.isResource
        else { return nil }
        
        switch elementType {
        case .asset: return resource.fcpAsAsset?.mediaRep.src
        case .effect: return nil
        case .format: return nil
        case .locator: return resource.fcpAsLocator?.url
        case .media: return nil // Note: media can contain sequence or multicam.
        case .objectTracker: return nil
        default: return nil
        }
    }
}
