//
//  FCPXMLVersion115Tests.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//


//
//	FCPXML 1.15 models, feature gate, and version-conversion stripping.
//

import Foundation
import Testing
@testable import OpenFCPXMLKit

@Suite("FCPXML 1.15")
struct FCPXMLVersion115Tests {
    private var service: FCPXMLService { FCPXMLService(versionConverter: FCPXMLVersionConverter()) }
    private let factory = FoundationXMLFactory()

    @Test("1.15 tokens and retime name")
    func tokensAndRetimeName() {
        #expect(FinalCutPro.FCPXML.FrameSampling.vsaMotionBlur.rawValue == "vsa-motion-blur")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.hold.rawValue == "hold")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.bezier.rawValue == "bezier")
        #expect(FinalCutPro.FCPXML.KeyframeInterpolation.passthrough.rawValue == "passthrough")
        #expect(
            FinalCutPro.FCPXML.SpeedChangeFormatting.retimeEffectName(for: .vsaMotionBlur)
                == "VSA Motion Blur Retime"
        )
        let at114 = FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
            onElement: "clip",
            at: .v1_14
        )
        #expect(at114.contains("flags"))
        #expect(
            FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
                onElement: "pan-rect",
                at: .v1_14
            ).contains("interp")
        )
        #expect(
            FinalCutPro.FCPXML.VersionFeatureGate.attributeNamesToOmit(
                onElement: "clip",
                at: .v1_15
            ).isEmpty
        )
    }

    @Test("Video natural motion blur round-trips")
    func videoNaturalMotionBlurRoundTrip() throws {
        let element = factory.makeElement(name: "video")
        element.addAttribute(name: "ref", value: "r1")
        element.addAttribute(name: "duration", value: "5s")
        let video = try #require(FinalCutPro.FCPXML.Video(element: element))
        video.naturalMotionBlurAdjustment = FinalCutPro.FCPXML.NaturalMotionBlurAdjustment(
            isEnabled: true,
            amount: "40"
        )

        let stored = try #require(video.naturalMotionBlurAdjustment)
        #expect(stored.amount == "40")
        #expect(stored.isEnabled)
        #expect(
            video.element.firstChildElement(named: "adjust-natural-motion-blur")?
                .attribute(forName: "amount") == "40"
        )

        video.naturalMotionBlurAdjustment = nil
        #expect(video.naturalMotionBlurAdjustment == nil)
    }

    @Test("Semantic mask round-trips on a clip")
    func semanticMaskRoundTrip() throws {
        let element = factory.makeElement(name: "clip")
        element.addAttribute(name: "duration", value: "5s")
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: element))
        let filter = FinalCutPro.FCPXML.VideoFilter(effectID: "r1")
        let semantic = FinalCutPro.FCPXML.MaskSemantic(
            name: "Person",
            blendMode: .add,
            type: "person"
        )
        clip.videoFilterMasks = [
            FinalCutPro.FCPXML.VideoFilterMask(
                primaryVideoFilter: filter,
                maskSemantics: [semantic]
            )
        ]

        let stored = try #require(clip.videoFilterMasks.first?.maskSemantics.first)
        #expect(stored.name == "Person")
        #expect(stored.type == "person")
        #expect(stored.blendMode == .add)
        #expect(
            clip.element.firstChildElement(named: "filter-video-mask")?
                .firstChildElement(named: "mask-semantic")?
                .attribute(forName: "type") == "person"
        )
    }

    @Test("Anchorable flags round-trip and clear")
    func anchorableFlagsRoundTrip() throws {
        let element = factory.makeElement(name: "clip")
        element.addAttribute(name: "duration", value: "5s")
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: element))
        clip.flags = "solo"
        #expect(clip.flags == "solo")
        #expect(clip.element.attribute(forName: "flags") == "solo")
        clip.flags = nil
        #expect(clip.flags == nil)
        #expect(clip.element.attribute(forName: "flags") == nil)
    }

    @Test("Pan rect interpolation round-trips")
    func panRectInterpolationRoundTrip() throws {
        let element = factory.makeElement(name: "clip")
        element.addAttribute(name: "duration", value: "5s")
        let clip = try #require(FinalCutPro.FCPXML.Clip(element: element))
        var crop = FinalCutPro.FCPXML.CropAdjustment(mode: .pan)
        crop.panRects = [
            FinalCutPro.FCPXML.CropAdjustment.PanRect(
                left: 0,
                top: 0,
                right: 1,
                bottom: 1,
                interpolation: .linear
            )
        ]
        clip.cropAdjustment = crop

        #expect(clip.cropAdjustment?.panRects?.first?.interpolation == .linear)
        #expect(
            clip.element.firstChildElement(named: "adjust-crop")?
                .firstChildElement(named: "pan-rect")?
                .attribute(forName: "interp") == "linear"
        )
    }

    @Test("Convert 1.15 to 1.14 strips new elements, attributes, and tokens")
    func convert1_15To1_14StripsNewFacts() throws {
        let doc = service.createFCPXMLDocument(version: "1.15")
        let root = try #require(doc.rootElement())

        let clip = factory.makeElement(name: "clip")
        clip.addAttribute(name: "duration", value: "5s")
        clip.addAttribute(name: "flags", value: "solo")

        let video = factory.makeElement(name: "video")
        video.addAttribute(name: "ref", value: "r1")
        video.addAttribute(name: "duration", value: "5s")
        let blur = factory.makeElement(name: "adjust-natural-motion-blur")
        blur.addAttribute(name: "amount", value: "40")
        video.addChild(blur)
        clip.addChild(video)

        let mask = factory.makeElement(name: "filter-video-mask")
        let semantic = factory.makeElement(name: "mask-semantic")
        semantic.addAttribute(name: "type", value: "person")
        let filter = factory.makeElement(name: "filter-video")
        filter.addAttribute(name: "ref", value: "r2")
        mask.addChild(semantic)
        mask.addChild(filter)
        clip.addChild(mask)

        let crop = factory.makeElement(name: "adjust-crop")
        crop.addAttribute(name: "mode", value: "pan")
        let pan = factory.makeElement(name: "pan-rect")
        pan.addAttribute(name: "left", value: "0")
        pan.addAttribute(name: "top", value: "0")
        pan.addAttribute(name: "right", value: "1")
        pan.addAttribute(name: "bottom", value: "1")
        pan.addAttribute(name: "interp", value: "linear")
        crop.addChild(pan)
        clip.addChild(crop)

        let keyframe = factory.makeElement(name: "keyframe")
        keyframe.addAttribute(name: "time", value: "0s")
        keyframe.addAttribute(name: "value", value: "1")
        keyframe.addAttribute(name: "interp", value: "bezier")
        clip.addChild(keyframe)

        let timeMap = factory.makeElement(name: "timeMap")
        timeMap.addAttribute(name: "frameSampling", value: "vsa-motion-blur")
        clip.addChild(timeMap)
        root.addChild(clip)

        let converted = try service.convertToVersion(doc, targetVersion: .v1_14)
        #expect(converted.rootElement()?.attribute(forName: "version") == "1.14")

        let convertedClip = try #require(findElement(named: "clip", in: converted))
        #expect(convertedClip.attribute(forName: "flags") == nil)
        #expect(findElement(named: "adjust-natural-motion-blur", in: converted) == nil)
        #expect(findElement(named: "mask-semantic", in: converted) == nil)
        #expect(findElement(named: "filter-video", in: converted) != nil)
        #expect(findElement(named: "pan-rect", in: converted)?.attribute(forName: "interp") == nil)
        #expect(findElement(named: "keyframe", in: converted)?.attribute(forName: "interp") == nil)
        #expect(findElement(named: "timeMap", in: converted)?.attribute(forName: "frameSampling") == nil)
    }

    @Test("Anchor flags bit 0 marks a disconnected clip")
    func anchorFlagsBit0MarksDisconnectedClip() {
        let clip = factory.makeElement(name: "title")
        #expect(clip.fcpIsDisconnectedFromAnchor == false)

        clip.addAttribute(name: "flags", value: "1")
        #expect(clip.fcpIsDisconnectedFromAnchor)

        clip.addAttribute(name: "flags", value: "2")
        #expect(clip.fcpIsDisconnectedFromAnchor == false)

        clip.addAttribute(name: "flags", value: "3")
        #expect(clip.fcpIsDisconnectedFromAnchor)

        clip.addAttribute(name: "flags", value: "solo")
        #expect(clip.fcpIsDisconnectedFromAnchor == false)
    }

    private func findElement(named name: String, in document: any OFKXMLDocument) -> (any OFKXMLElement)? {
        guard let root = document.rootElement() else { return nil }
        return findElement(named: name, in: root)
    }

    private func findElement(named name: String, in element: any OFKXMLElement) -> (any OFKXMLElement)? {
        if element.name == name { return element }
        for child in element.childElements {
            if let match = findElement(named: name, in: child) { return match }
        }
        return nil
    }
}
