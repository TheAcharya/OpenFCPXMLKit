//
//  FCPXMLFrameSampling.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Frame sampling attribute enum for frame rate conversion.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// `frameSampling` attribute value.
    /// Used in `conform-rate` and `timeMap` elements.
    public enum FrameSampling: String, Equatable, Hashable, CaseIterable, Sendable {
        case floor
        case nearestNeighbor = "nearest-neighbor"
        case frameBlending = "frame-blending"
        case opticalFlowClassic = "optical-flow-classic"
        case opticalFlow = "optical-flow"
        case opticalFlowFRC = "optical-flow-frc"
    }
}

extension FinalCutPro.FCPXML.FrameSampling: FCPXMLAttribute {
    public static let attributeName: String = "frameSampling"
}
