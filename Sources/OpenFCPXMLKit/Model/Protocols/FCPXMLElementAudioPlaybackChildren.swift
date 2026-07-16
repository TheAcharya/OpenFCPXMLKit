//
// FCPXMLElementAudioPlaybackChildren.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Shared audio playback children for audio-channel-source / audio-role-source (DTD).
//

import Foundation
import SwiftTimecode

/// Elements that host audio enhancement / intrinsic / filter-audio / mute children
/// (`audio-channel-source`, `audio-role-source`).
public protocol FCPXMLElementAudioPlaybackChildren: FCPXMLElement {
    var volumeAdjustment: FinalCutPro.FCPXML.VolumeAdjustment? { get nonmutating set }
    var loudnessAdjustment: FinalCutPro.FCPXML.LoudnessAdjustment? { get nonmutating set }
    var noiseReductionAdjustment: FinalCutPro.FCPXML.NoiseReductionAdjustment? { get nonmutating set }
    var humReductionAdjustment: FinalCutPro.FCPXML.HumReductionAdjustment? { get nonmutating set }
    var equalizationAdjustment: FinalCutPro.FCPXML.EqualizationAdjustment? { get nonmutating set }
    var matchEqualizationAdjustment: FinalCutPro.FCPXML.MatchEqualizationAdjustment? { get nonmutating set }
    var voiceIsolationAdjustment: FinalCutPro.FCPXML.VoiceIsolationAdjustment? { get nonmutating set }
    var audioFilters: [FinalCutPro.FCPXML.AudioFilter] { get nonmutating set }
    var mutes: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Mute> { get nonmutating set }
}

extension FCPXMLElementAudioPlaybackChildren {
    public var volumeAdjustment: FinalCutPro.FCPXML.VolumeAdjustment? {
        get { element.fcpAudioPlaybackVolumeAdjustment }
        nonmutating set { element.fcpAudioPlaybackVolumeAdjustment = newValue }
    }

    public var loudnessAdjustment: FinalCutPro.FCPXML.LoudnessAdjustment? {
        get { element.fcpAudioPlaybackLoudnessAdjustment }
        nonmutating set { element.fcpAudioPlaybackLoudnessAdjustment = newValue }
    }

    public var noiseReductionAdjustment: FinalCutPro.FCPXML.NoiseReductionAdjustment? {
        get { element.fcpAudioPlaybackNoiseReductionAdjustment }
        nonmutating set { element.fcpAudioPlaybackNoiseReductionAdjustment = newValue }
    }

    public var humReductionAdjustment: FinalCutPro.FCPXML.HumReductionAdjustment? {
        get { element.fcpAudioPlaybackHumReductionAdjustment }
        nonmutating set { element.fcpAudioPlaybackHumReductionAdjustment = newValue }
    }

    public var equalizationAdjustment: FinalCutPro.FCPXML.EqualizationAdjustment? {
        get { element.fcpAudioPlaybackEqualizationAdjustment }
        nonmutating set { element.fcpAudioPlaybackEqualizationAdjustment = newValue }
    }

    public var matchEqualizationAdjustment: FinalCutPro.FCPXML.MatchEqualizationAdjustment? {
        get { element.fcpAudioPlaybackMatchEqualizationAdjustment }
        nonmutating set { element.fcpAudioPlaybackMatchEqualizationAdjustment = newValue }
    }

    public var voiceIsolationAdjustment: FinalCutPro.FCPXML.VoiceIsolationAdjustment? {
        get { element.fcpAudioPlaybackVoiceIsolationAdjustment }
        nonmutating set { element.fcpAudioPlaybackVoiceIsolationAdjustment = newValue }
    }

    public var audioFilters: [FinalCutPro.FCPXML.AudioFilter] {
        get { element.fcpAudioPlaybackFilters }
        nonmutating set { element.fcpAudioPlaybackFilters = newValue }
    }

    public var mutes: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Mute> {
        get { element.fcpMutes }
        nonmutating set { element.fcpMutes = newValue }
    }
}

// MARK: - OFKXMLElement helpers (audio-channel-source / audio-role-source self)

extension OFKXMLElement {
    var fcpMutes: LazyFCPXMLChildrenSequence<FinalCutPro.FCPXML.Mute> {
        get { children(whereFCPElement: .mute) }
        set { _updateChildElements(ofType: .mute, with: newValue) }
    }

    var fcpAudioPlaybackVolumeAdjustment: FinalCutPro.FCPXML.VolumeAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-volume") else { return nil }
            let amountString = adjustElement.stringValue(forAttributeNamed: "amount") ?? "0dB"
            if let volume = FinalCutPro.FCPXML.VolumeAdjustment(fromDecibelString: amountString) {
                return volume
            }
            if let amount = Double(amountString) {
                return FinalCutPro.FCPXML.VolumeAdjustment(amount: amount)
            }
            return FinalCutPro.FCPXML.VolumeAdjustment(amount: 0)
        }
        set {
            removeChildren { $0.name == "adjust-volume" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-volume")
            adjustElement.addAttribute(name: "amount", value: adjustment.decibelString)
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackLoudnessAdjustment: FinalCutPro.FCPXML.LoudnessAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-loudness") else { return nil }
            let amountString = adjustElement.stringValue(forAttributeNamed: "amount") ?? "0"
            let uniformityString = adjustElement.stringValue(forAttributeNamed: "uniformity") ?? "0"
            let amount = Double(amountString) ?? 0
            let uniformity = Double(uniformityString) ?? 0
            return FinalCutPro.FCPXML.LoudnessAdjustment(amount: amount, uniformity: uniformity)
        }
        set {
            removeChildren { $0.name == "adjust-loudness" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-loudness")
            adjustElement.addAttribute(name: "amount", value: String(adjustment.amount))
            adjustElement.addAttribute(name: "uniformity", value: String(adjustment.uniformity))
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackNoiseReductionAdjustment: FinalCutPro.FCPXML.NoiseReductionAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-noiseReduction") else { return nil }
            let amountString = adjustElement.stringValue(forAttributeNamed: "amount") ?? "0"
            return FinalCutPro.FCPXML.NoiseReductionAdjustment(amount: Double(amountString) ?? 0)
        }
        set {
            removeChildren { $0.name == "adjust-noiseReduction" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-noiseReduction")
            adjustElement.addAttribute(name: "amount", value: String(adjustment.amount))
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackHumReductionAdjustment: FinalCutPro.FCPXML.HumReductionAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-humReduction") else { return nil }
            let frequencyString = adjustElement.stringValue(forAttributeNamed: "frequency") ?? "50"
            let frequency = FinalCutPro.FCPXML.HumReductionFrequency(rawValue: frequencyString) ?? .hz50
            return FinalCutPro.FCPXML.HumReductionAdjustment(frequency: frequency)
        }
        set {
            removeChildren { $0.name == "adjust-humReduction" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-humReduction")
            adjustElement.addAttribute(name: "frequency", value: adjustment.frequency.rawValue)
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackEqualizationAdjustment: FinalCutPro.FCPXML.EqualizationAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-EQ") else { return nil }
            let modeString = adjustElement.stringValue(forAttributeNamed: "mode") ?? "flat"
            let mode = FinalCutPro.FCPXML.EqualizationMode(rawValue: modeString) ?? .flat
            let parameters = Array(adjustElement.childElements
                .filter { $0.name == "param" }
                .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
            return FinalCutPro.FCPXML.EqualizationAdjustment(mode: mode, parameters: parameters)
        }
        set {
            removeChildren { $0.name == "adjust-EQ" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-EQ")
            adjustElement.addAttribute(name: "mode", value: adjustment.mode.rawValue)
            for param in adjustment.parameters {
                let paramElement = OFKXMLDefaultFactory().makeElement(name: "param")
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
                adjustElement.addChild(paramElement)
            }
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackMatchEqualizationAdjustment: FinalCutPro.FCPXML.MatchEqualizationAdjustment? {
        get {
            guard let adjustElement = firstChildElement(named: "adjust-matchEQ"),
                  let dataElement = adjustElement.firstChildElement(named: "data")
            else { return nil }
            let key = dataElement.stringValue(forAttributeNamed: "key")
            let value = dataElement.stringValue ?? ""
            return FinalCutPro.FCPXML.MatchEqualizationAdjustment(
                data: FinalCutPro.FCPXML.KeyedData(key: key, value: value)
            )
        }
        set {
            removeChildren { $0.name == "adjust-matchEQ" }
            guard let adjustment = newValue else { return }
            let adjustElement = OFKXMLDefaultFactory().makeElement(name: "adjust-matchEQ")
            let dataElement = OFKXMLDefaultFactory().makeElement(name: "data")
            if let key = adjustment.data.key {
                dataElement.addAttribute(name: "key", value: key)
            }
            dataElement.stringValue = adjustment.data.value
            adjustElement.addChild(dataElement)
            addChild(adjustElement)
        }
    }

    var fcpAudioPlaybackVoiceIsolationAdjustment: FinalCutPro.FCPXML.VoiceIsolationAdjustment? {
        get {
            guard let voiceEl = firstChildElement(named: "adjust-voiceIsolation"),
                  let amount = voiceEl.stringValue(forAttributeNamed: "amount")
            else { return nil }
            return FinalCutPro.FCPXML.VoiceIsolationAdjustment(amount: amount)
        }
        set {
            removeChildren { $0.name == "adjust-voiceIsolation" }
            guard let adjustment = newValue else { return }
            let voiceElement = OFKXMLDefaultFactory().makeElement(name: "adjust-voiceIsolation")
            voiceElement.addAttribute(name: "amount", value: adjustment.amount)
            addChild(voiceElement)
        }
    }

    var fcpAudioPlaybackFilters: [FinalCutPro.FCPXML.AudioFilter] {
        get {
            childElements
                .filter { $0.name == "filter-audio" }
                .compactMap { filterElement -> FinalCutPro.FCPXML.AudioFilter? in
                    guard let effectID = filterElement.stringValue(forAttributeNamed: "ref") else {
                        return nil
                    }
                    let name = filterElement.stringValue(forAttributeNamed: "name")
                    let presetID = filterElement.stringValue(forAttributeNamed: "presetID")
                    let enabledString = filterElement.stringValue(forAttributeNamed: "enabled") ?? "1"
                    let data = Array(filterElement.childElements
                        .filter { $0.name == "data" }
                        .compactMap { dataElement -> FinalCutPro.FCPXML.KeyedData? in
                            let key = dataElement.stringValue(forAttributeNamed: "key")
                            let value = dataElement.stringValue ?? ""
                            return FinalCutPro.FCPXML.KeyedData(key: key, value: value)
                        })
                    let parameters = Array(filterElement.childElements
                        .filter { $0.name == "param" }
                        .compactMap { FinalCutPro.FCPXML.FilterParameter(paramElement: $0) })
                    return FinalCutPro.FCPXML.AudioFilter(
                        effectID: effectID,
                        name: name,
                        isEnabled: enabledString == "1",
                        presetID: presetID,
                        data: data,
                        parameters: parameters
                    )
                }
        }
        set {
            removeChildren { $0.name == "filter-audio" }
            for filter in newValue {
                let filterElement = OFKXMLDefaultFactory().makeElement(name: "filter-audio")
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
                for datum in filter.data {
                    let dataElement = OFKXMLDefaultFactory().makeElement(name: "data")
                    if let key = datum.key {
                        dataElement.addAttribute(name: "key", value: key)
                    }
                    dataElement.stringValue = datum.value
                    filterElement.addChild(dataElement)
                }
                for param in filter.parameters {
                    let paramElement = OFKXMLDefaultFactory().makeElement(name: "param")
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
                addChild(filterElement)
            }
        }
    }
}
