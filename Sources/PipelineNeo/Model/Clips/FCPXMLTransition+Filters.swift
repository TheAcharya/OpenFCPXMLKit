//
//  FCPXMLTransition+Filters.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Transition filters and metadata extension.
//

import Foundation

extension FinalCutPro.FCPXML.Transition {
    /// The video filters applied to the transition.
    public var videoFilters: [FinalCutPro.FCPXML.VideoFilter] {
        get {
            element.childElements
                .filter { $0.name == "filter-video" }
                .compactMap { filterElement -> FinalCutPro.FCPXML.VideoFilter? in
                    guard let effectID = filterElement.stringValue(forAttributeNamed: "ref") else {
                        return nil
                    }
                    
                    let name = filterElement.stringValue(forAttributeNamed: "name")
                    let enabledString = filterElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    // Parse data elements
                    let data = Array(filterElement.childElements
                        .filter { $0.name == "data" }
                        .compactMap { dataElement -> FinalCutPro.FCPXML.KeyedData? in
                            let key = dataElement.stringValue(forAttributeNamed: "key")
                            let value = dataElement.stringValue ?? ""
                            return FinalCutPro.FCPXML.KeyedData(key: key, value: value)
                        })
                    
                    // Parse param elements (simplified - nested params not fully parsed)
                    let parameters = Array(filterElement.childElements
                        .filter { $0.name == "param" }
                        .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                            FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
                        })
                    
                    return FinalCutPro.FCPXML.VideoFilter(
                        effectID: effectID,
                        name: name,
                        isEnabled: isEnabled,
                        data: data,
                        parameters: parameters
                    )
                }
        }
        nonmutating set {
            // Remove existing filter-video elements
            element.removeChildren { $0.name == "filter-video" }
            
            // Add new filter-video elements
            for filter in newValue {
                let filterElement = PNXMLDefaultFactory().makeElement(name: "filter-video")
                filterElement.addAttribute(name: "ref", value: filter.effectID)
                if let name = filter.name {
                    filterElement.addAttribute(name: "name", value: name)
                }
                if !filter.isEnabled {
                    filterElement.addAttribute(name: "enabled", value: "0")
                }
                
                // Add data elements
                for dataItem in filter.data {
                    let dataElement = PNXMLDefaultFactory().makeElement(name: "data")
                    if let key = dataItem.key {
                        dataElement.addAttribute(name: "key", value: key)
                    }
                    dataElement.stringValue = dataItem.value
                    filterElement.addChild(dataElement)
                }
                
                // Add param elements
                for param in filter.parameters {
                    let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                    paramElement.addAttribute(name: "name", value: param.name)
                    if let key = param.key {
                        paramElement.addAttribute(name: "key", value: key)
                    }
                    if let value = param.value {
                        paramElement.addAttribute(name: "value", value: value)
                    }
                    if let auxValue = param.auxValue {
                        paramElement.addAttribute(name: "auxValue", value: auxValue)
                    }
                    if !param.isEnabled {
                        paramElement.addAttribute(name: "enabled", value: "0")
                    }
                    filterElement.addChild(paramElement)
                }
                
                element.addChild(filterElement)
            }
        }
    }
    
    /// The audio filters applied to the transition.
    public var audioFilters: [FinalCutPro.FCPXML.AudioFilter] {
        get {
            element.childElements
                .filter { $0.name == "filter-audio" }
                .compactMap { filterElement -> FinalCutPro.FCPXML.AudioFilter? in
                    guard let effectID = filterElement.stringValue(forAttributeNamed: "ref") else {
                        return nil
                    }
                    
                    let name = filterElement.stringValue(forAttributeNamed: "name")
                    let presetID = filterElement.stringValue(forAttributeNamed: "presetID")
                    let enabledString = filterElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    
                    // Parse data elements
                    let data = Array(filterElement.childElements
                        .filter { $0.name == "data" }
                        .compactMap { dataElement -> FinalCutPro.FCPXML.KeyedData? in
                            let key = dataElement.stringValue(forAttributeNamed: "key")
                            let value = dataElement.stringValue ?? ""
                            return FinalCutPro.FCPXML.KeyedData(key: key, value: value)
                        })
                    
                    // Parse param elements
                    let parameters = Array(filterElement.childElements
                        .filter { $0.name == "param" }
                        .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                            FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
                        })
                    
                    return FinalCutPro.FCPXML.AudioFilter(
                        effectID: effectID,
                        name: name,
                        isEnabled: isEnabled,
                        presetID: presetID,
                        data: data,
                        parameters: parameters
                    )
                }
        }
        nonmutating set {
            // Remove existing filter-audio elements
            element.removeChildren { $0.name == "filter-audio" }
            
            // Add new filter-audio elements
            for filter in newValue {
                let filterElement = PNXMLDefaultFactory().makeElement(name: "filter-audio")
                filterElement.addAttribute(name: "ref", value: filter.effectID)
                if let name = filter.name {
                    filterElement.addAttribute(name: "name", value: name)
                }
                if let presetID = filter.presetID {
                    filterElement.addAttribute(name: "presetID", value: presetID)
                }
                if !filter.isEnabled {
                    filterElement.addAttribute(name: "enabled", value: "0")
                }
                
                // Add data elements
                for dataItem in filter.data {
                    let dataElement = PNXMLDefaultFactory().makeElement(name: "data")
                    if let key = dataItem.key {
                        dataElement.addAttribute(name: "key", value: key)
                    }
                    dataElement.stringValue = dataItem.value
                    filterElement.addChild(dataElement)
                }
                
                // Add param elements
                for param in filter.parameters {
                    let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                    paramElement.addAttribute(name: "name", value: param.name)
                    if let key = param.key {
                        paramElement.addAttribute(name: "key", value: key)
                    }
                    if let value = param.value {
                        paramElement.addAttribute(name: "value", value: value)
                    }
                    if let auxValue = param.auxValue {
                        paramElement.addAttribute(name: "auxValue", value: auxValue)
                    }
                    if !param.isEnabled {
                        paramElement.addAttribute(name: "enabled", value: "0")
                    }
                    filterElement.addChild(paramElement)
                }
                
                element.addChild(filterElement)
            }
        }
    }
}
