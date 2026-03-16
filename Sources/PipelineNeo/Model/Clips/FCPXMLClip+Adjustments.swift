//
//  FCPXMLClip+Adjustments.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Clip adjustments extension for typed adjustment models.
//

import Foundation

extension FinalCutPro.FCPXML.Clip {
    /// Attribute names used when reading/writing adjustment XML (avoids typos and centralizes strings).
    private enum AttributeName {
        static let amount = "amount"
        static let anchor = "anchor"
        static let aperture = "aperture"
        static let autoOrient = "autoOrient"
        static let autoOrManual = "autoOrManual"
        static let autoScale = "autoScale"
        static let auxValue = "auxValue"
        static let bottom = "bottom"
        static let conformType = "conformType"
        static let convergence = "convergence"
        static let coordinates = "coordinates"
        static let dataLocator = "dataLocator"
        static let depth = "depth"
        static let distance = "distance"
        static let enabled = "enabled"
        static let fieldOfView = "fieldOfView"
        static let frequency = "frequency"
        static let interaxial = "interaxial"
        static let key = "key"
        static let latitude = "latitude"
        static let left = "left"
        static let longitude = "longitude"
        static let mapping = "mapping"
        static let mode = "mode"
        static let name = "name"
        static let pan = "pan"
        static let peakNitsOfPQSource = "peakNitsOfPQSource"
        static let peakNitsOfSDRToPQSource = "peakNitsOfSDRToPQSource"
        static let position = "position"
        static let right = "right"
        static let roll = "roll"
        static let rotation = "rotation"
        static let scale = "scale"
        static let swapEyes = "swapEyes"
        static let tilt = "tilt"
        static let top = "top"
        static let type = "type"
        static let uniformity = "uniformity"
        static let value = "value"
        static let xOrientation = "xOrientation"
        static let xPosition = "xPosition"
        static let yOrientation = "yOrientation"
        static let yPosition = "yPosition"
        static let zOrientation = "zOrientation"
        static let zPosition = "zPosition"
    }

    /// The crop adjustment applied to the clip.
    public var cropAdjustment: FinalCutPro.FCPXML.CropAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-crop") else {
                return nil
            }
            
            guard let modeString = adjustElement.stringValue(forAttributeNamed: AttributeName.mode),
                  let mode = FinalCutPro.FCPXML.CropAdjustment.Mode(rawValue: modeString) else {
                return nil
            }
            
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let isEnabled = enabledString == "1"
            
            var crop = FinalCutPro.FCPXML.CropAdjustment(mode: mode, isEnabled: isEnabled)
            
            // Parse crop-rect
            if let cropRectElement = adjustElement.firstChildElement(named: "crop-rect"),
               let left = Double(cropRectElement.stringValue(forAttributeNamed: AttributeName.left) ?? "0"),
               let top = Double(cropRectElement.stringValue(forAttributeNamed: AttributeName.top) ?? "0"),
               let right = Double(cropRectElement.stringValue(forAttributeNamed: AttributeName.right) ?? "0"),
               let bottom = Double(cropRectElement.stringValue(forAttributeNamed: AttributeName.bottom) ?? "0") {
                crop.cropRect = FinalCutPro.FCPXML.CropAdjustment.CropRect(left: left, top: top, right: right, bottom: bottom)
            }
            
            // Parse trim-rect
            if let trimRectElement = adjustElement.firstChildElement(named: "trim-rect"),
               let left = Double(trimRectElement.stringValue(forAttributeNamed: AttributeName.left) ?? "0"),
               let top = Double(trimRectElement.stringValue(forAttributeNamed: AttributeName.top) ?? "0"),
               let right = Double(trimRectElement.stringValue(forAttributeNamed: AttributeName.right) ?? "0"),
               let bottom = Double(trimRectElement.stringValue(forAttributeNamed: AttributeName.bottom) ?? "0") {
                crop.trimRect = FinalCutPro.FCPXML.CropAdjustment.TrimRect(left: left, top: top, right: right, bottom: bottom)
            }
            
            // Parse pan-rect elements
            let panRectElements = adjustElement.childElements.filter { $0.name == "pan-rect" }
            if !panRectElements.isEmpty {
                crop.panRects = panRectElements.compactMap { panElement -> FinalCutPro.FCPXML.CropAdjustment.PanRect? in
                    guard let left = Double(panElement.stringValue(forAttributeNamed: AttributeName.left) ?? "0"),
                          let top = Double(panElement.stringValue(forAttributeNamed: AttributeName.top) ?? "0"),
                          let right = Double(panElement.stringValue(forAttributeNamed: AttributeName.right) ?? "0"),
                          let bottom = Double(panElement.stringValue(forAttributeNamed: AttributeName.bottom) ?? "0") else {
                        return nil
                    }
                    return FinalCutPro.FCPXML.CropAdjustment.PanRect(left: left, top: top, right: right, bottom: bottom)
                }
            }
            
            return crop
        }
        nonmutating set {
            // Remove existing adjust-crop element
            if let existing = element.firstChildElement(named: "adjust-crop") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-crop element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-crop")
            adjustElement.addAttribute(name: AttributeName.mode, value: adjustment.mode.rawValue)
            if !adjustment.isEnabled {
                adjustElement.addAttribute(name: AttributeName.enabled, value: "0")
            }
            
            // Add crop-rect if present
            if let cropRect = adjustment.cropRect {
                let cropRectElement = PNXMLDefaultFactory().makeElement(name: "crop-rect")
                cropRectElement.addAttribute(name: AttributeName.left, value: String(cropRect.left))
                cropRectElement.addAttribute(name: AttributeName.top, value: String(cropRect.top))
                cropRectElement.addAttribute(name: AttributeName.right, value: String(cropRect.right))
                cropRectElement.addAttribute(name: AttributeName.bottom, value: String(cropRect.bottom))
                adjustElement.addChild(cropRectElement)
            }
            
            // Add trim-rect if present
            if let trimRect = adjustment.trimRect {
                let trimRectElement = PNXMLDefaultFactory().makeElement(name: "trim-rect")
                trimRectElement.addAttribute(name: AttributeName.left, value: String(trimRect.left))
                trimRectElement.addAttribute(name: AttributeName.top, value: String(trimRect.top))
                trimRectElement.addAttribute(name: AttributeName.right, value: String(trimRect.right))
                trimRectElement.addAttribute(name: AttributeName.bottom, value: String(trimRect.bottom))
                adjustElement.addChild(trimRectElement)
            }
            
            // Add pan-rect elements if present
            if let panRects = adjustment.panRects {
                for panRect in panRects {
                    let panRectElement = PNXMLDefaultFactory().makeElement(name: "pan-rect")
                    panRectElement.addAttribute(name: AttributeName.left, value: String(panRect.left))
                    panRectElement.addAttribute(name: AttributeName.top, value: String(panRect.top))
                    panRectElement.addAttribute(name: AttributeName.right, value: String(panRect.right))
                    panRectElement.addAttribute(name: AttributeName.bottom, value: String(panRect.bottom))
                    adjustElement.addChild(panRectElement)
                }
            }
            
            element.addChild(adjustElement)
        }
    }
    
    /// The transform adjustment applied to the clip.
    public var transformAdjustment: FinalCutPro.FCPXML.TransformAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-transform") else {
                return nil
            }
            
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let isEnabled = enabledString == "1"
            
            let positionString = adjustElement.stringValue(forAttributeNamed: AttributeName.position) ?? "0 0"
            let position = FinalCutPro.FCPXML.Point(fromString: positionString) ?? .zero
            
            let scaleString = adjustElement.stringValue(forAttributeNamed: AttributeName.scale) ?? "1 1"
            let scale = FinalCutPro.FCPXML.Point(fromString: scaleString) ?? FinalCutPro.FCPXML.Point(x: 1, y: 1)
            
            let rotationString = adjustElement.stringValue(forAttributeNamed: AttributeName.rotation) ?? "0"
            let rotation = Double(rotationString) ?? 0
            
            let anchorString = adjustElement.stringValue(forAttributeNamed: AttributeName.anchor) ?? "0 0"
            let anchor = FinalCutPro.FCPXML.Point(fromString: anchorString) ?? .zero
            
            return FinalCutPro.FCPXML.TransformAdjustment(
                position: position,
                scale: scale,
                rotation: rotation,
                anchor: anchor,
                isEnabled: isEnabled
            )
        }
        nonmutating set {
            // Remove existing adjust-transform element
            if let existing = element.firstChildElement(named: "adjust-transform") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-transform element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-transform")
            if !adjustment.isEnabled {
                adjustElement.addAttribute(name: AttributeName.enabled, value: "0")
            }
            adjustElement.addAttribute(name: AttributeName.position, value: adjustment.position.stringValue)
            adjustElement.addAttribute(name: AttributeName.scale, value: adjustment.scale.stringValue)
            adjustElement.addAttribute(name: AttributeName.rotation, value: String(adjustment.rotation))
            adjustElement.addAttribute(name: AttributeName.anchor, value: adjustment.anchor.stringValue)
            
            element.addChild(adjustElement)
        }
    }
    
    /// The blend adjustment applied to the clip.
    public var blendAdjustment: FinalCutPro.FCPXML.BlendAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-blend") else {
                return nil
            }
            
            let amountString = adjustElement.stringValue(forAttributeNamed: AttributeName.amount) ?? "1"
            let amount = Double(amountString) ?? 1.0
            
            let mode = adjustElement.stringValue(forAttributeNamed: AttributeName.mode)
            
            return FinalCutPro.FCPXML.BlendAdjustment(mode: mode, amount: amount)
        }
        nonmutating set {
            // Remove existing adjust-blend element
            if let existing = element.firstChildElement(named: "adjust-blend") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-blend element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-blend")
            adjustElement.addAttribute(name: AttributeName.amount, value: String(adjustment.amount))
            if let mode = adjustment.mode {
                adjustElement.addAttribute(name: AttributeName.mode, value: mode)
            }
            
            element.addChild(adjustElement)
        }
    }
    
    /// The stabilization adjustment applied to the clip.
    public var stabilizationAdjustment: FinalCutPro.FCPXML.StabilizationAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-stabilization") else {
                return nil
            }
            
            let typeString = adjustElement.stringValue(forAttributeNamed: AttributeName.type) ?? "automatic"
            guard let type = FinalCutPro.FCPXML.StabilizationAdjustment.Mode(rawValue: typeString) else {
                return FinalCutPro.FCPXML.StabilizationAdjustment()
            }
            
            return FinalCutPro.FCPXML.StabilizationAdjustment(type: type)
        }
        nonmutating set {
            // Remove existing adjust-stabilization element
            if let existing = element.firstChildElement(named: "adjust-stabilization") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-stabilization element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-stabilization")
            adjustElement.addAttribute(name: AttributeName.type, value: adjustment.type.rawValue)
            
            element.addChild(adjustElement)
        }
    }

    /// The rolling shutter adjustment applied to the clip.
    public var rollingShutterAdjustment: FinalCutPro.FCPXML.RollingShutterAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-rollingShutter") else {
                return nil
            }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let amountString = adjustElement.stringValue(forAttributeNamed: AttributeName.amount) ?? "none"
            return FinalCutPro.FCPXML.RollingShutterAdjustment(
                isEnabled: enabledString == "1",
                amount: FinalCutPro.FCPXML.RollingShutterAdjustment.Amount(rawValue: amountString) ?? .none
            )
        }
        nonmutating set {
            if let existing = element.firstChildElement(named: "adjust-rollingShutter") {
                element.removeChildren { $0 === existing }
            }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-rollingShutter")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            adjustElement.addAttribute(name: AttributeName.amount, value: adjustment.amount.rawValue)
            element.addChild(adjustElement)
        }
    }

    /// The conform (fit/fill) adjustment applied to the clip.
    public var conformAdjustment: FinalCutPro.FCPXML.ConformAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-conform") else {
                return nil
            }
            let typeString = adjustElement.stringValue(forAttributeNamed: AttributeName.type) ?? "fit"
            return FinalCutPro.FCPXML.ConformAdjustment(
                type: FinalCutPro.FCPXML.ConformAdjustment.ConformType(rawValue: typeString) ?? .fit
            )
        }
        nonmutating set {
            if let existing = element.firstChildElement(named: "adjust-conform") {
                element.removeChildren { $0 === existing }
            }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-conform")
            adjustElement.addAttribute(name: AttributeName.type, value: adjustment.type.rawValue)
            element.addChild(adjustElement)
        }
    }
    
    /// The volume adjustment applied to the clip.
    public var volumeAdjustment: FinalCutPro.FCPXML.VolumeAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-volume") else {
                return nil
            }
            
            let amountString = adjustElement.stringValue(forAttributeNamed: AttributeName.amount) ?? "0dB"
            if let volume = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: amountString) {
                return volume
            }
            
            // Fallback: try parsing as plain number
            if let amount = Double(amountString) {
                return FinalCutPro.FCPXML.VolumeAdjustment(amount: amount)
            }
            
            return FinalCutPro.FCPXML.VolumeAdjustment(amount: 0)
        }
        nonmutating set {
            // Remove existing adjust-volume element
            if let existing = element.firstChildElement(named: "adjust-volume") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-volume element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-volume")
            adjustElement.addAttribute(name: AttributeName.amount, value: adjustment.decibelString)
            
            element.addChild(adjustElement)
        }
    }
    
    /// The loudness adjustment applied to the clip.
    public var loudnessAdjustment: FinalCutPro.FCPXML.LoudnessAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-loudness") else {
                return nil
            }
            
            let amountString = adjustElement.stringValue(forAttributeNamed: AttributeName.amount) ?? "0"
            let uniformityString = adjustElement.stringValue(forAttributeNamed: AttributeName.uniformity) ?? "0"
            
            guard let amount = Double(amountString),
                  let uniformity = Double(uniformityString) else {
                return FinalCutPro.FCPXML.LoudnessAdjustment(amount: 0, uniformity: 0)
            }
            
            return FinalCutPro.FCPXML.LoudnessAdjustment(amount: amount, uniformity: uniformity)
        }
        nonmutating set {
            // Remove existing adjust-loudness element
            if let existing = element.firstChildElement(named: "adjust-loudness") {
                element.removeChildren { $0 === existing }
            }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-loudness element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-loudness")
            adjustElement.addAttribute(name: AttributeName.amount, value: String(adjustment.amount))
            adjustElement.addAttribute(name: AttributeName.uniformity, value: String(adjustment.uniformity))
            
            element.addChild(adjustElement)
        }
    }
    
    /// The noise reduction adjustment applied to the clip.
    public var noiseReductionAdjustment: FinalCutPro.FCPXML.NoiseReductionAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-noiseReduction") else {
                return nil
            }
            
            let amountString = adjustElement.stringValue(forAttributeNamed: AttributeName.amount) ?? "0"
            guard let amount = Double(amountString) else {
                return FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: 0)
            }
            
            return FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: amount)
        }
        nonmutating set {
            // Remove existing adjust-noiseReduction element
            element.removeChildren { $0.name == "adjust-noiseReduction" }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-noiseReduction element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-noiseReduction")
            adjustElement.addAttribute(name: AttributeName.amount, value: String(adjustment.amount))
            
            element.addChild(adjustElement)
        }
    }
    
    /// The hum reduction adjustment applied to the clip.
    public var humReductionAdjustment: FinalCutPro.FCPXML.HumReductionAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-humReduction") else {
                return nil
            }
            
            let frequencyString = adjustElement.stringValue(forAttributeNamed: AttributeName.frequency) ?? "50"
            guard let frequency = FinalCutPro.FCPXML.HumReductionFrequency(rawValue: frequencyString) else {
                return FinalCutPro.FCPXML.HumReductionAdjustment(frequency: .hz50)
            }
            
            return FinalCutPro.FCPXML.HumReductionAdjustment(frequency: frequency)
        }
        nonmutating set {
            // Remove existing adjust-humReduction element
            element.removeChildren { $0.name == "adjust-humReduction" }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-humReduction element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-humReduction")
            adjustElement.addAttribute(name: AttributeName.frequency, value: adjustment.frequency.rawValue)
            
            element.addChild(adjustElement)
        }
    }
    
    /// The equalization adjustment applied to the clip.
    public var equalizationAdjustment: FinalCutPro.FCPXML.EqualizationAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-EQ") else {
                return nil
            }
            
            let modeString = adjustElement.stringValue(forAttributeNamed: AttributeName.mode) ?? "flat"
            guard let mode = FinalCutPro.FCPXML.EqualizationMode(rawValue: modeString) else {
                return FinalCutPro.FCPXML.EqualizationAdjustment(mode: .flat)
            }
            
            // Parse param elements
            let parameters = Array(adjustElement.childElements
                .filter { $0.name == "param" }
                .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                    FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
                })
            
            return FinalCutPro.FCPXML.EqualizationAdjustment(mode: mode, parameters: parameters)
        }
        nonmutating set {
            // Remove existing adjust-EQ element
            element.removeChildren { $0.name == "adjust-EQ" }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-EQ element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-EQ")
            adjustElement.addAttribute(name: AttributeName.mode, value: adjustment.mode.rawValue)
            
            // Add param elements
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let key = param.key {
                    paramElement.addAttribute(name: AttributeName.key, value: key)
                }
                if let value = param.value {
                    paramElement.addAttribute(name: AttributeName.value, value: value)
                }
                if let auxValue = param.auxValue {
                    paramElement.addAttribute(name: AttributeName.auxValue, value: auxValue)
                }
                if !param.isEnabled {
                    paramElement.addAttribute(name: AttributeName.enabled, value: "0")
                }
                adjustElement.addChild(paramElement)
            }
            
            element.addChild(adjustElement)
        }
    }
    
    /// The match equalization adjustment applied to the clip.
    public var matchEqualizationAdjustment: FinalCutPro.FCPXML.MatchEqualizationAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-matchEQ") else {
                return nil
            }
            
            // Parse data element
            guard let dataElement = adjustElement.firstChildElement(named: "data") else {
                return nil
            }
            
            let key = dataElement.stringValue(forAttributeNamed: AttributeName.key)
            let value = dataElement.stringValue ?? ""
            let data = FinalCutPro.FCPXML.KeyedData(key: key, value: value)
            
            return FinalCutPro.FCPXML.MatchEqualizationAdjustment(data: data)
        }
        nonmutating set {
            // Remove existing adjust-matchEQ element
            element.removeChildren { $0.name == "adjust-matchEQ" }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-matchEQ element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-matchEQ")
            
            // Add data element
            let dataElement = PNXMLDefaultFactory().makeElement(name: "data")
            if let key = adjustment.data.key {
                dataElement.addAttribute(name: AttributeName.key, value: key)
            }
            dataElement.stringValue = adjustment.data.value
            adjustElement.addChild(dataElement)
            
            element.addChild(adjustElement)
        }
    }
    
    /// The 360° transform adjustment applied to the clip.
    public var transform360Adjustment: FinalCutPro.FCPXML.Transform360Adjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-360-transform") else {
                return nil
            }
            
            guard let coordinatesString = adjustElement.stringValue(forAttributeNamed: AttributeName.coordinates),
                  let coordinateType = FinalCutPro.FCPXML.Transform360CoordinateType(rawValue: coordinatesString) else {
                return nil
            }
            
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let isEnabled = enabledString == "1"
            
            let autoOrientString = adjustElement.stringValue(forAttributeNamed: AttributeName.autoOrient) ?? "1"
            let autoOrient = autoOrientString == "1"
            
            // Parse coordinate-specific attributes
            let latitude = adjustElement.stringValue(forAttributeNamed: AttributeName.latitude).flatMap { Double($0) }
            let longitude = adjustElement.stringValue(forAttributeNamed: AttributeName.longitude).flatMap { Double($0) }
            let distance = adjustElement.stringValue(forAttributeNamed: AttributeName.distance).flatMap { Double($0) }
            let xPosition = adjustElement.stringValue(forAttributeNamed: AttributeName.xPosition).flatMap { Double($0) }
            let yPosition = adjustElement.stringValue(forAttributeNamed: AttributeName.yPosition).flatMap { Double($0) }
            let zPosition = adjustElement.stringValue(forAttributeNamed: AttributeName.zPosition).flatMap { Double($0) }
            let xOrientation = adjustElement.stringValue(forAttributeNamed: AttributeName.xOrientation).flatMap { Double($0) }
            let yOrientation = adjustElement.stringValue(forAttributeNamed: AttributeName.yOrientation).flatMap { Double($0) }
            let zOrientation = adjustElement.stringValue(forAttributeNamed: AttributeName.zOrientation).flatMap { Double($0) }
            let convergence = adjustElement.stringValue(forAttributeNamed: AttributeName.convergence).flatMap { Double($0) }
            let interaxial = adjustElement.stringValue(forAttributeNamed: AttributeName.interaxial).flatMap { Double($0) }
            
            // Parse param elements
            let parameters = Array(adjustElement.childElements
                .filter { $0.name == "param" }
                .compactMap { paramElement -> FinalCutPro.FCPXML.FilterParameter? in
                    FinalCutPro.FCPXML.FilterParameter(paramElement: paramElement)
                })
            
            var adjustment = FinalCutPro.FCPXML.Transform360Adjustment(
                coordinateType: coordinateType,
                isEnabled: isEnabled,
                autoOrient: autoOrient,
                parameters: parameters
            )
            
            adjustment.latitude = latitude
            adjustment.longitude = longitude
            adjustment.distance = distance
            adjustment.xPosition = xPosition
            adjustment.yPosition = yPosition
            adjustment.zPosition = zPosition
            adjustment.xOrientation = xOrientation
            adjustment.yOrientation = yOrientation
            adjustment.zOrientation = zOrientation
            adjustment.convergence = convergence
            adjustment.interaxial = interaxial
            
            return adjustment
        }
        nonmutating set {
            // Remove existing adjust-360-transform element
            element.removeChildren { $0.name == "adjust-360-transform" }
            
            guard let adjustment = newValue else { return }
            
            // Create new adjust-360-transform element
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-360-transform")
            adjustElement.addAttribute(name: AttributeName.coordinates, value: adjustment.coordinateType.rawValue)
            if !adjustment.isEnabled {
                adjustElement.addAttribute(name: AttributeName.enabled, value: "0")
            }
            if !adjustment.autoOrient {
                adjustElement.addAttribute(name: AttributeName.autoOrient, value: "0")
            }
            
            // Add coordinate-specific attributes
            if let latitude = adjustment.latitude {
                adjustElement.addAttribute(name: AttributeName.latitude, value: String(latitude))
            }
            if let longitude = adjustment.longitude {
                adjustElement.addAttribute(name: AttributeName.longitude, value: String(longitude))
            }
            if let distance = adjustment.distance {
                adjustElement.addAttribute(name: AttributeName.distance, value: String(distance))
            }
            if let xPosition = adjustment.xPosition {
                adjustElement.addAttribute(name: AttributeName.xPosition, value: String(xPosition))
            }
            if let yPosition = adjustment.yPosition {
                adjustElement.addAttribute(name: AttributeName.yPosition, value: String(yPosition))
            }
            if let zPosition = adjustment.zPosition {
                adjustElement.addAttribute(name: AttributeName.zPosition, value: String(zPosition))
            }
            if let xOrientation = adjustment.xOrientation {
                adjustElement.addAttribute(name: AttributeName.xOrientation, value: String(xOrientation))
            }
            if let yOrientation = adjustment.yOrientation {
                adjustElement.addAttribute(name: AttributeName.yOrientation, value: String(yOrientation))
            }
            if let zOrientation = adjustment.zOrientation {
                adjustElement.addAttribute(name: AttributeName.zOrientation, value: String(zOrientation))
            }
            if let convergence = adjustment.convergence {
                adjustElement.addAttribute(name: AttributeName.convergence, value: String(convergence))
            }
            if let interaxial = adjustment.interaxial {
                adjustElement.addAttribute(name: AttributeName.interaxial, value: String(interaxial))
            }
            
            // Add param elements
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let key = param.key {
                    paramElement.addAttribute(name: AttributeName.key, value: key)
                }
                if let value = param.value {
                    paramElement.addAttribute(name: AttributeName.value, value: value)
                }
                if let auxValue = param.auxValue {
                    paramElement.addAttribute(name: AttributeName.auxValue, value: auxValue)
                }
                if !param.isEnabled {
                    paramElement.addAttribute(name: AttributeName.enabled, value: "0")
                }
                adjustElement.addChild(paramElement)
            }
            
            element.addChild(adjustElement)
        }
    }

    // MARK: - Reorient (FCPXML 1.7+)

    /// The reorient adjustment applied to the clip. FCPXML 1.7+.
    public var reorientAdjustment: FinalCutPro.FCPXML.ReorientAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-reorient") else { return nil }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let parameters = Array(adjustElement.childElements.filter { $0.name == "param" }.compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
            return FinalCutPro.FCPXML.ReorientAdjustment(
                isEnabled: enabledString == "1",
                tilt: adjustElement.stringValue(forAttributeNamed: AttributeName.tilt) ?? "0",
                pan: adjustElement.stringValue(forAttributeNamed: AttributeName.pan) ?? "0",
                roll: adjustElement.stringValue(forAttributeNamed: AttributeName.roll) ?? "0",
                convergence: adjustElement.stringValue(forAttributeNamed: AttributeName.convergence) ?? "0",
                parameters: parameters
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-reorient" }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-reorient")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            adjustElement.addAttribute(name: AttributeName.tilt, value: adjustment.tilt)
            adjustElement.addAttribute(name: AttributeName.pan, value: adjustment.pan)
            adjustElement.addAttribute(name: AttributeName.roll, value: adjustment.roll)
            adjustElement.addAttribute(name: AttributeName.convergence, value: adjustment.convergence)
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let k = param.key { paramElement.addAttribute(name: AttributeName.key, value: k) }
                if let v = param.value { paramElement.addAttribute(name: AttributeName.value, value: v) }
                if let av = param.auxValue { paramElement.addAttribute(name: AttributeName.auxValue, value: av) }
                if !param.isEnabled { paramElement.addAttribute(name: AttributeName.enabled, value: "0") }
                adjustElement.addChild(paramElement)
            }
            element.addChild(adjustElement)
        }
    }

    // MARK: - Orientation (FCPXML 1.7+)

    /// The orientation adjustment applied to the clip. FCPXML 1.7+.
    public var orientationAdjustment: FinalCutPro.FCPXML.OrientationAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-orientation") else { return nil }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let mappingString = adjustElement.stringValue(forAttributeNamed: AttributeName.mapping) ?? "normal"
            let mapping = FinalCutPro.FCPXML.OrientationAdjustment.Mapping(rawValue: mappingString) ?? .normal
            let parameters = Array(adjustElement.childElements.filter { $0.name == "param" }.compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
            return FinalCutPro.FCPXML.OrientationAdjustment(
                isEnabled: enabledString == "1",
                tilt: adjustElement.stringValue(forAttributeNamed: AttributeName.tilt) ?? "0",
                pan: adjustElement.stringValue(forAttributeNamed: AttributeName.pan) ?? "0",
                roll: adjustElement.stringValue(forAttributeNamed: AttributeName.roll) ?? "0",
                fieldOfView: adjustElement.stringValue(forAttributeNamed: AttributeName.fieldOfView),
                mapping: mapping,
                parameters: parameters
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-orientation" }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-orientation")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            adjustElement.addAttribute(name: AttributeName.tilt, value: adjustment.tilt)
            adjustElement.addAttribute(name: AttributeName.pan, value: adjustment.pan)
            adjustElement.addAttribute(name: AttributeName.roll, value: adjustment.roll)
            if let fov = adjustment.fieldOfView { adjustElement.addAttribute(name: AttributeName.fieldOfView, value: fov) }
            adjustElement.addAttribute(name: AttributeName.mapping, value: adjustment.mapping.rawValue)
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let k = param.key { paramElement.addAttribute(name: AttributeName.key, value: k) }
                if let v = param.value { paramElement.addAttribute(name: AttributeName.value, value: v) }
                if let av = param.auxValue { paramElement.addAttribute(name: AttributeName.auxValue, value: av) }
                if !param.isEnabled { paramElement.addAttribute(name: AttributeName.enabled, value: "0") }
                adjustElement.addChild(paramElement)
            }
            element.addChild(adjustElement)
        }
    }

    // MARK: - Cinematic (FCPXML 1.10+)

    /// The cinematic adjustment applied to the clip. FCPXML 1.10+.
    public var cinematicAdjustment: FinalCutPro.FCPXML.CinematicAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-cinematic") else { return nil }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let parameters = Array(adjustElement.childElements.filter { $0.name == "param" }.compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
            return FinalCutPro.FCPXML.CinematicAdjustment(
                isEnabled: enabledString == "1",
                dataLocator: adjustElement.stringValue(forAttributeNamed: AttributeName.dataLocator),
                aperture: adjustElement.stringValue(forAttributeNamed: AttributeName.aperture),
                parameters: parameters
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-cinematic" }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-cinematic")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            if let loc = adjustment.dataLocator { adjustElement.addAttribute(name: AttributeName.dataLocator, value: loc) }
            if let ap = adjustment.aperture { adjustElement.addAttribute(name: AttributeName.aperture, value: ap) }
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let k = param.key { paramElement.addAttribute(name: AttributeName.key, value: k) }
                if let v = param.value { paramElement.addAttribute(name: AttributeName.value, value: v) }
                if let av = param.auxValue { paramElement.addAttribute(name: AttributeName.auxValue, value: av) }
                if !param.isEnabled { paramElement.addAttribute(name: AttributeName.enabled, value: "0") }
                adjustElement.addChild(paramElement)
            }
            element.addChild(adjustElement)
        }
    }

    // MARK: - Color Conform (FCPXML 1.11+)

    /// The color conform adjustment applied to the clip. FCPXML 1.11+.
    public var colorConformAdjustment: FinalCutPro.FCPXML.ColorConformAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-colorConform") else { return nil }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let autoString = adjustElement.stringValue(forAttributeNamed: AttributeName.autoOrManual) ?? "automatic"
            let autoOrManual = FinalCutPro.FCPXML.ColorConformAdjustment.AutoOrManual(rawValue: autoString) ?? .automatic
            let typeString = adjustElement.stringValue(forAttributeNamed: AttributeName.conformType) ?? "conformNone"
            let conformType = FinalCutPro.FCPXML.ColorConformAdjustment.ConformType(rawValue: typeString) ?? .conformNone
            let peakPQ = adjustElement.stringValue(forAttributeNamed: AttributeName.peakNitsOfPQSource) ?? "1000"
            let peakSDR = adjustElement.stringValue(forAttributeNamed: AttributeName.peakNitsOfSDRToPQSource) ?? "100"
            return FinalCutPro.FCPXML.ColorConformAdjustment(
                isEnabled: enabledString == "1",
                autoOrManual: autoOrManual,
                conformType: conformType,
                peakNitsOfPQSource: peakPQ,
                peakNitsOfSDRToPQSource: peakSDR
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-colorConform" }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-colorConform")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            adjustElement.addAttribute(name: AttributeName.autoOrManual, value: adjustment.autoOrManual.rawValue)
            adjustElement.addAttribute(name: AttributeName.conformType, value: adjustment.conformType.rawValue)
            adjustElement.addAttribute(name: AttributeName.peakNitsOfPQSource, value: adjustment.peakNitsOfPQSource)
            adjustElement.addAttribute(name: AttributeName.peakNitsOfSDRToPQSource, value: adjustment.peakNitsOfSDRToPQSource)
            element.addChild(adjustElement)
        }
    }

    // MARK: - Stereo 3D (FCPXML 1.13+)

    /// The stereo 3D adjustment applied to the clip. FCPXML 1.13+.
    public var stereo3DAdjustment: FinalCutPro.FCPXML.Stereo3DAdjustment? {
        get {
            guard let adjustElement = element.firstChildElement(named: "adjust-stereo-3D") else { return nil }
            let enabledString = adjustElement.stringValue(forAttributeNamed: AttributeName.enabled) ?? "1"
            let autoScaleString = adjustElement.stringValue(forAttributeNamed: AttributeName.autoScale) ?? "1"
            let swapEyesString = adjustElement.stringValue(forAttributeNamed: AttributeName.swapEyes) ?? "0"
            let parameters = Array(adjustElement.childElements.filter { $0.name == "param" }.compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
            return FinalCutPro.FCPXML.Stereo3DAdjustment(
                isEnabled: enabledString == "1",
                convergence: adjustElement.stringValue(forAttributeNamed: AttributeName.convergence) ?? "0",
                autoScale: autoScaleString == "1",
                swapEyes: swapEyesString == "1",
                depth: adjustElement.stringValue(forAttributeNamed: AttributeName.depth) ?? "0",
                parameters: parameters
            )
        }
        nonmutating set {
            element.removeChildren { $0.name == "adjust-stereo-3D" }
            guard let adjustment = newValue else { return }
            let adjustElement = PNXMLDefaultFactory().makeElement(name: "adjust-stereo-3D")
            if !adjustment.isEnabled { adjustElement.addAttribute(name: AttributeName.enabled, value: "0") }
            adjustElement.addAttribute(name: AttributeName.convergence, value: adjustment.convergence)
            adjustElement.addAttribute(name: AttributeName.autoScale, value: adjustment.autoScale ? "1" : "0")
            adjustElement.addAttribute(name: AttributeName.swapEyes, value: adjustment.swapEyes ? "1" : "0")
            adjustElement.addAttribute(name: AttributeName.depth, value: adjustment.depth)
            for param in adjustment.parameters {
                let paramElement = PNXMLDefaultFactory().makeElement(name: "param")
                paramElement.addAttribute(name: AttributeName.name, value: param.name)
                if let k = param.key { paramElement.addAttribute(name: AttributeName.key, value: k) }
                if let v = param.value { paramElement.addAttribute(name: AttributeName.value, value: v) }
                if let av = param.auxValue { paramElement.addAttribute(name: AttributeName.auxValue, value: av) }
                if !param.isEnabled { paramElement.addAttribute(name: AttributeName.enabled, value: "0") }
                adjustElement.addChild(paramElement)
            }
            element.addChild(adjustElement)
        }
    }

    // MARK: - Voice Isolation (FCPXML 1.14; on audio-channel-source / audio-role-source)

    /// The voice isolation adjustment, if present on an audio-channel-source or audio-role-source child. FCPXML 1.14+.
    public var voiceIsolationAdjustment: FinalCutPro.FCPXML.VoiceIsolationAdjustment? {
        get {
            for node in element.children ?? [] {
                guard let child = node as? (any PNXMLElement) else { continue }
                if child.name == "audio-channel-source" || child.name == "audio-role-source",
                   let voiceEl = child.firstChildElement(named: "adjust-voiceIsolation"),
                   let amount = voiceEl.stringValue(forAttributeNamed: AttributeName.amount) {
                    return FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: amount)
                }
            }
            return nil
        }
        nonmutating set {
            for node in element.children ?? [] {
                guard let child = node as? (any PNXMLElement) else { continue }
                if child.name == "audio-channel-source" || child.name == "audio-role-source" {
                    child.removeChildren { $0.name == "adjust-voiceIsolation" }
                    if let adjustment = newValue {
                        let voiceElement = PNXMLDefaultFactory().makeElement(name: "adjust-voiceIsolation")
                        voiceElement.addAttribute(name: AttributeName.amount, value: adjustment.amount)
                        child.addChild(voiceElement)
                    }
                    return
                }
            }
        }
    }
}
