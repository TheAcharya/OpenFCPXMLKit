//
// FCPXMLTimingCache.swift
// OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
// © 2026 • Licensed under MIT License
//

//
//	Scoped memoisation of derived per-element timing values during read-only walks.
//

import Foundation

extension FinalCutPro.FCPXML {
    /// Memoises derived per-element timing values for the duration of a read-only walk.
    ///
    /// Resolving a `conform-rate` scaling factor walks an element's ancestors to find its
    /// containing timeline and then inspects that container's children. Every read of a time
    /// attribute (`start`, `offset`, `duration`, `tcStart`) performs that resolution, and walking
    /// a large timeline reads the same attributes millions of times, so the results are cached
    /// per element.
    ///
    /// A cached factor is only valid while the document is not mutated, so the cache is installed
    /// by read-only entry points via ``FinalCutPro/FCPXML/withTimingCache(_:)`` instead of being
    /// global. Writes (``OFKXMLElement/_fcpSet(fraction:forAttribute:scaled:)``) never consult it.
    final class TimingCache: @unchecked Sendable {
        private struct ConformRateKey: Hashable {
            let element: ObjectIdentifier
            let includingSelf: Bool
        }

        private let lock = NSLock()

        /// Cached scaling factors. The value is itself optional because "no scaling applies" is a
        /// meaningful result worth caching.
        private var conformRateScaling: [ConformRateKey: Double?] = [:]

        /// Keeps cached elements alive so that `ObjectIdentifier` values cannot be recycled by a
        /// different element allocated at the same address.
        private var retainedElements: [AnyObject] = []

        /// Returns the memoised conform-rate scaling factor, computing it on first request.
        ///
        /// Falls back to `compute()` uncached when the backend has no stable object identity.
        func conformRateScalingFactor(
            for element: any OFKXMLElement,
            includingSelf: Bool,
            compute: () -> Double?
        ) -> Double? {
            guard let backingObject = element.backingObject else { return compute() }

            let key = ConformRateKey(
                element: ObjectIdentifier(backingObject),
                includingSelf: includingSelf
            )

            lock.lock()
            if let cached = conformRateScaling[key] {
                lock.unlock()
                return cached
            }
            lock.unlock()

            let factor = compute()

            lock.lock()
            if conformRateScaling.updateValue(factor, forKey: key) == nil {
                retainedElements.append(backingObject)
            }
            lock.unlock()

            return factor
        }
    }

    /// Task-local storage for the active ``TimingCache``.
    enum TimingLocals {
        @TaskLocal static var timingCache: TimingCache?
    }

    /// Runs `body` with a ``TimingCache`` installed, reusing an already-installed cache if present.
    ///
    /// - Important: `body` must not mutate the document, because cached values are derived from
    ///   element ancestry and sibling `conform-rate` elements.
    static func withTimingCache<Result>(
        _ body: () async throws -> Result
    ) async rethrows -> Result {
        guard TimingLocals.timingCache == nil else { return try await body() }
        return try await TimingLocals.$timingCache.withValue(TimingCache()) {
            try await body()
        }
    }

    /// Runs `body` with a ``TimingCache`` installed, reusing an already-installed cache if present.
    ///
    /// - Important: `body` must not mutate the document, because cached values are derived from
    ///   element ancestry and sibling `conform-rate` elements.
    static func withTimingCacheSync<Result>(
        _ body: () throws -> Result
    ) rethrows -> Result {
        guard TimingLocals.timingCache == nil else { return try body() }
        return try TimingLocals.$timingCache.withValue(TimingCache()) {
            try body()
        }
    }
}

extension OFKXMLElement {
    /// FCPXML: Conform-rate scaling factor for this element, memoised when a
    /// ``FinalCutPro/FCPXML/TimingCache`` is installed.
    ///
    /// Only safe for reads that use the element's natural ancestry, which is what
    /// ``_fcpGetFraction(forAttribute:scaled:)`` does.
    func _fcpCachedConformRateScalingFactor(includingSelf: Bool) -> Double? {
        guard let cache = FinalCutPro.FCPXML.TimingLocals.timingCache else {
            return _fcpConformRateScalingFactor(includingSelf: includingSelf)
        }
        return cache.conformRateScalingFactor(for: self, includingSelf: includingSelf) {
            _fcpConformRateScalingFactor(includingSelf: includingSelf)
        }
    }
}
