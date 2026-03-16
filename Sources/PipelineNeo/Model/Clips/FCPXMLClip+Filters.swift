//
//  FCPXMLClip+Filters.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Clip filters extension for typed filter models.
//

import Foundation

extension FinalCutPro.FCPXML.Clip {
    /// The video filters applied to the clip.
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
                    
                    // Parse param elements
                    let parameters = Array(filterElement.childElements
                        .filter { $0.name == "param" }
                        .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
                    
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
    
    /// The video filter masks applied to the clip.
    public var videoFilterMasks: [FinalCutPro.FCPXML.VideoFilterMask] {
        get {
            element.childElements
                .filter { $0.name == "filter-video-mask" }
                .compactMap { maskElement -> FinalCutPro.FCPXML.VideoFilterMask? in
                    let enabledString = maskElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let isEnabled = enabledString == "1"
                    let invertedString = maskElement.stringValue(forAttributeNamed: "inverted") ?? "0"
                    let isInverted = invertedString == "1"
                    
                    // Parse mask-shape elements
                    let maskShapes = Array(maskElement.childElements
                        .filter { $0.name == "mask-shape" }
                        .compactMap { shapeElement -> FinalCutPro.FCPXML.MaskShape? in
                            let name = shapeElement.stringValue(forAttributeNamed: "name")
                            let enabledString = shapeElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                            let isEnabled = enabledString == "1"
                            let blendModeString = shapeElement.stringValue(forAttributeNamed: "blendMode") ?? "add"
                            let blendMode = FinalCutPro.FCPXML.MaskBlendMode(rawValue: blendModeString) ?? .add
                            
                            let parameters = Array(shapeElement.childElements
                                .filter { $0.name == "param" }
                                .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                                    guard let name = paramElement.stringValue(forAttributeNamed: "name") else {
                                        return nil
                                    }
                                    let key = paramElement.stringValue(forAttributeNamed: "key")
                                    let value = paramElement.stringValue(forAttributeNamed: "value")
                                    let enabledString = paramElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                                    let isEnabled = enabledString == "1"
                                    return FinalCutPro.FCPXML.FilterParameter(
                                        name: name,
                                        key: key,
                                        value: value,
                                        isEnabled: isEnabled
                                    )
                                })
                            
                            return FinalCutPro.FCPXML.MaskShape(
                                name: name,
                                blendMode: blendMode,
                                isEnabled: isEnabled,
                                parameters: parameters
                            )
                        })
                    
                    // Parse mask-isolation elements
                    let maskIsolations = Array(maskElement.childElements
                        .filter { $0.name == "mask-isolation" }
                        .compactMap { isolationElement -> FinalCutPro.FCPXML.MaskIsolation? in
                            let name = isolationElement.stringValue(forAttributeNamed: "name")
                            let enabledString = isolationElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                            let isEnabled = enabledString == "1"
                            let blendModeString = isolationElement.stringValue(forAttributeNamed: "blendMode") ?? "multiply"
                            let blendMode = FinalCutPro.FCPXML.MaskBlendMode(rawValue: blendModeString) ?? .multiply
                            
                            let data = Array(isolationElement.childElements
                                .filter { $0.name == "data" }
                                .compactMap { dataElement -> FinalCutPro.FCPXML.KeyedData? in
                                    let key = dataElement.stringValue(forAttributeNamed: "key")
                                    let value = dataElement.stringValue ?? ""
                                    return FinalCutPro.FCPXML.KeyedData(key: key, value: value)
                                })
                            
                            let parameters = Array(isolationElement.childElements
                                .filter { $0.name == "param" }
                                .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                                    guard let name = paramElement.stringValue(forAttributeNamed: "name") else {
                                        return nil
                                    }
                                    let key = paramElement.stringValue(forAttributeNamed: "key")
                                    let value = paramElement.stringValue(forAttributeNamed: "value")
                                    let enabledString = paramElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                                    let isEnabled = enabledString == "1"
                                    return FinalCutPro.FCPXML.FilterParameter(
                                        name: name,
                                        key: key,
                                        value: value,
                                        isEnabled: isEnabled
                                    )
                                })
                            
                            return FinalCutPro.FCPXML.MaskIsolation(
                                name: name,
                                blendMode: blendMode,
                                isEnabled: isEnabled,
                                data: data,
                                parameters: parameters
                            )
                        })
                    
                    // Parse filter-video elements (primary and secondary)
                    let videoFilters = Array(maskElement.childElements
                        .filter { $0.name == "filter-video" }
                        .compactMap { filterElement -> FinalCutPro.FCPXML.VideoFilter? in
                            guard let effectID = filterElement.stringValue(forAttributeNamed: "ref") else {
                                return nil
                            }
                            let name = filterElement.stringValue(forAttributeNamed: "name")
                            let enabledString = filterElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                            let isEnabled = enabledString == "1"
                            
                            let data = Array(filterElement.childElements
                                .filter { $0.name == "data" }
                                .compactMap { dataElement -> FinalCutPro.FCPXML.KeyedData? in
                                    let key = dataElement.stringValue(forAttributeNamed: "key")
                                    let value = dataElement.stringValue ?? ""
                                    return FinalCutPro.FCPXML.KeyedData(key: key, value: value)
                                })
                            
                            let parameters = Array(filterElement.childElements
                                .filter { $0.name == "param" }
                                .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                                    guard let name = paramElement.stringValue(forAttributeNamed: "name") else {
                                        return nil
                                    }
                                    let key = paramElement.stringValue(forAttributeNamed: "key")
                                    let value = paramElement.stringValue(forAttributeNamed: "value")
                                    let enabledString = paramElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                                    let isEnabled = enabledString == "1"
                                    return FinalCutPro.FCPXML.FilterParameter(
                                        name: name,
                                        key: key,
                                        value: value,
                                        isEnabled: isEnabled
                                    )
                                })
                            
                            return FinalCutPro.FCPXML.VideoFilter(
                                effectID: effectID,
                                name: name,
                                isEnabled: isEnabled,
                                data: data,
                                parameters: parameters
                            )
                        })
                    
                    guard let primaryFilter = videoFilters.first else {
                        return nil
                    }
                    
                    return FinalCutPro.FCPXML.VideoFilterMask(
                        primaryVideoFilter: primaryFilter,
                        secondaryVideoFilter: videoFilters.count > 1 ? videoFilters[1] : nil,
                        maskShapes: maskShapes,
                        maskIsolations: maskIsolations,
                        isEnabled: isEnabled,
                        isInverted: isInverted
                    )
                }
        }
        nonmutating set {
            // Remove existing filter-video-mask elements
            element.removeChildren { $0.name == "filter-video-mask" }
            
            // Add new filter-video-mask elements
            for mask in newValue {
                let maskElement = PNXMLDefaultFactory().makeElement(name: "filter-video-mask")
                if !mask.isEnabled {
                    maskElement.addAttribute(name: "enabled", value: "0")
                }
                if mask.isInverted {
                    maskElement.addAttribute(name: "inverted", value: "1")
                }
                
                // Add mask-shape elements
                for shape in mask.maskShapes {
                    let shapeElement = PNXMLDefaultFactory().makeElement(name: "mask-shape")
                    if let name = shape.name {
                        shapeElement.addAttribute(name: "name", value: name)
                    }
                    if !shape.isEnabled {
                        shapeElement.addAttribute(name: "enabled", value: "0")
                    }
                    shapeElement.addAttribute(name: "blendMode", value: shape.blendMode.rawValue)
                    
                    for param in shape.parameters {
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
                        shapeElement.addChild(paramElement)
                    }
                    
                    maskElement.addChild(shapeElement)
                }
                
                // Add mask-isolation elements
                for isolation in mask.maskIsolations {
                    let isolationElement = PNXMLDefaultFactory().makeElement(name: "mask-isolation")
                    if let name = isolation.name {
                        isolationElement.addAttribute(name: "name", value: name)
                    }
                    if !isolation.isEnabled {
                        isolationElement.addAttribute(name: "enabled", value: "0")
                    }
                    isolationElement.addAttribute(name: "blendMode", value: isolation.blendMode.rawValue)
                    
                    for dataItem in isolation.data {
                        let dataElement = PNXMLDefaultFactory().makeElement(name: "data")
                        if let key = dataItem.key {
                            dataElement.addAttribute(name: "key", value: key)
                        }
                        dataElement.stringValue = dataItem.value
                        isolationElement.addChild(dataElement)
                    }
                    
                    for param in isolation.parameters {
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
                        isolationElement.addChild(paramElement)
                    }
                    
                    maskElement.addChild(isolationElement)
                }
                
                // Add filter-video elements
                for filter in mask.videoFilters {
                    let filterElement = PNXMLDefaultFactory().makeElement(name: "filter-video")
                    filterElement.addAttribute(name: "ref", value: filter.effectID)
                    if let name = filter.name {
                        filterElement.addAttribute(name: "name", value: name)
                    }
                    if !filter.isEnabled {
                        filterElement.addAttribute(name: "enabled", value: "0")
                    }
                    
                    for dataItem in filter.data {
                        let dataElement = PNXMLDefaultFactory().makeElement(name: "data")
                        if let key = dataItem.key {
                            dataElement.addAttribute(name: "key", value: key)
                        }
                        dataElement.stringValue = dataItem.value
                        filterElement.addChild(dataElement)
                    }
                    
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
                    
                    maskElement.addChild(filterElement)
                }
                
                element.addChild(maskElement)
            }
        }
    }
    
    /// The audio filters applied to the clip.
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
                        .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
                    
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
