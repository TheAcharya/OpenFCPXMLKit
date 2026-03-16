//
//  FCPXMLProperties.swift
//  Pipeline Neo • https://github.com/TheAcharya/pipeline-neo
//  © 2026 • Licensed under MIT License
//

//
//	Utility properties for FCPXML root element accessors.
//

import Foundation
import SwiftTimecode
import SwiftExtensions

// MARK: - Main Public Model Getters

extension FinalCutPro.FCPXML {
    /// Utility:
    /// Returns the root `fcpxml` element.
    public var root: Root {
        get {
            if let existingElement = xml
                .childElements
                .first(whereFCPElement: .fcpxml)
            {
                return existingElement
            }

            // create new element and attach
            let newElement = FinalCutPro.FCPXML.Root()
            xml.setRootElement(newElement.element)
            return newElement
        }
        set {
            let current = root
            guard current.element.name == newValue.element.name,
                  current.element.xmlString == newValue.element.xmlString else {
                xml.setRootElement(newValue.element)
                return
            }
        }
    }
    
    /// Convenience:
    /// Returns all events that exist anywhere within the XML hierarchy.
    /// This is computed, so it is best to avoid repeat calls to this method.
    ///
    /// Events may exist within:
    /// - the `fcpxml` element
    /// - the `fcpxml/library` element if it exists
    public func allEvents() -> [Event] {
        // there is no appreciable gain by using lazy sequences here
        // so just return [PNXMLElement] array
        
        var events: [Event] = []
        
        let rootEvents = root.events
        events.append(contentsOf: rootEvents)
        
        // technically there can only be one or zero `library` elements,
        // and FCP will not allow exporting more than one library to FCPXML at a time.
        // but there is nothing stopping us from having more than one.
        if let libraryEvents = root.library?.events {
            events.append(contentsOf: libraryEvents)
        }
        
        return events
    }
    
    /// Convenience:
    /// Returns all projects that exist anywhere within the XML hierarchy.
    /// This is computed, so it is best to avoid repeat calls to this method.
    ///
    /// Projects may exist within:
    /// - the `fcpxml` element
    /// - an `fcpxml/event` element
    /// - an `fcpxml/library/event` element
    public func allProjects() -> [Project] {
        // there is no appreciable gain by using lazy sequences here
        // so just return [PNXMLElement] array
        
        var projects: [Project] = []
        
        let rootProjects = root.projects
        projects.append(contentsOf: rootProjects)
        
        // will get all events and return their projects
        let eventsProjects = allEvents().flatMap(\.projects)
        projects.append(contentsOf: eventsProjects)
        
        return projects
    }
    
    /// Returns the FCPXML format version.
    public var version: FinalCutPro.FCPXML.Version {
        root.version
    }
    
    /// Returns all top-level timelines (sequences, clips, etc.) found in the FCPXML in the order
    /// they are found, including from within events and projects.
    ///
    /// - root `fcpxml` can contain:
    ///   - `library` (one or zero)
    ///   - `event` (zero or more)
    ///   - `project` (zero or more)
    ///   - individual timelines/clips (zero or more)
    /// - the single optional `library` can contain:
    ///   - `event` (zero or more)
    ///   - `project` (zero or more)
    ///   - individual timelines/clips (zero or more)
    /// - an `event` can contain:
    ///   - `project` (zero or more)
    ///   - individual timelines/clips (zero or more)
    /// - a `project` must always contain:
    ///   - a single `sequence`
    public func allTimelines() -> [FinalCutPro.FCPXML.AnyTimeline] {
        root.element._fcpMetaTimelinesAsAnyTimelines()
    }
}

extension FinalCutPro.FCPXML.Library {
    /// Wraps child timeline(s) in a type-erased ``FinalCutPro/FCPXML/AnyTimeline`` instances.
    func childTimelinesAsAnyTimelines() -> [FinalCutPro.FCPXML.AnyTimeline] {
        element._fcpMetaTimelinesAsAnyTimelines()
    }
}

extension FinalCutPro.FCPXML.Event {
    /// Wraps child timeline(s) in a type-erased ``FinalCutPro/FCPXML/AnyTimeline`` instances.
    func childTimelinesAsAnyTimelines() -> [FinalCutPro.FCPXML.AnyTimeline] {
        element._fcpMetaTimelinesAsAnyTimelines()
    }
}

extension FinalCutPro.FCPXML.Project {
    /// Wraps child `sequence` element in a type-erased ``FinalCutPro/FCPXML/AnyTimeline`` instances.
    func sequenceAsAnyTimeline() -> FinalCutPro.FCPXML.AnyTimeline {
        .sequence(self.sequence)
    }
}
