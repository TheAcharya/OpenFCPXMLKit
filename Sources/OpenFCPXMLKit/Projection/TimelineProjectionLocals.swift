//
// TimelineProjectionLocals.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//


//
//	Task-local sink for clip marker/keyword annotations during a projection walk.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Collects ``ProjectedClipAnnotations`` without threading callbacks through every walk.
    final class ClipAnnotationCollector: @unchecked Sendable {
        private(set) var items: [ProjectedClipAnnotations] = []

        func append(_ item: ProjectedClipAnnotations) {
            items.append(item)
        }
    }

    enum TimelineProjectionLocals {
        @TaskLocal static var clipAnnotationCollector: ClipAnnotationCollector?
    }
}
