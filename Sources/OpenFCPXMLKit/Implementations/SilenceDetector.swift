//
//  SilenceDetector.swift
//  OpenFCPXMLKit • https://github.com/TheAcharya/OpenFCPXMLKit
//  © 2026 • Licensed under MIT License
//

//
//	Default implementation of silence detection using AVFoundation.
//

#if canImport(AVFoundation)
import Foundation
import CoreMedia
import AVFoundation
#endif

#if canImport(AVFoundation)
/// Default implementation of silence detection using AVFoundation.
@available(macOS 26.0, *)
public struct SilenceDetector: SilenceDetection, SilenceDetectionSync, Sendable {
    
    public init() {}
    
    // MARK: - Async Implementation
    
    /// Detects silence at the beginning and end of an audio file.
    ///
    /// Uses AVAssetReader to analyze audio samples and detect periods of silence
    /// (audio below the specified threshold) at the start and end of the file.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file.
    ///   - threshold: Audio level threshold in dB (default: -90dB for near-zero detection).
    ///   - progress: Optional progress reporter.
    /// - Returns: Result containing duration and trim points.
    /// - Throws: Error if detection fails.
    public func detectSilence(
        at url: URL,
        threshold: Float = -90.0,
        progress: ProgressReporter? = nil
    ) async throws -> SilenceDetectionResult {
        let asset = AVURLAsset(url: url)
        
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            // No audio track - return zero trim
            let duration = try await asset.load(.duration).seconds
            return SilenceDetectionResult(duration: duration, trimStart: 0, trimEnd: 0)
        }
        
        let duration = try await asset.load(.duration).seconds
        
        // Use AVAssetReader to analyze audio samples
        guard let reader = try? AVAssetReader(asset: asset) else {
            // Can't read asset - return zero trim
            return SilenceDetectionResult(duration: duration, trimStart: 0, trimEnd: 0)
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(readerOutput)
        
        guard reader.startReading() else {
            // Can't start reading - return zero trim
            return SilenceDetectionResult(duration: duration, trimStart: 0, trimEnd: 0)
        }
        
        defer {
            reader.cancelReading()
        }
        
        let sampleRate = try await audioTrack.load(.naturalTimeScale)
        let linearThreshold = pow(10.0, threshold / 20.0) * Float(Int16.max)
        
        var trimStart: Double = 0
        var trimEnd: Double = 0
        var foundNonSilence = false
        var currentTime: Double = 0
        var lastNonSilentTime: Double = 0
        
        // Read audio samples and detect silence
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            // Note: ProgressReporter doesn't have cancellation, but we can check if needed
            
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            
            var length: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            
            CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer
            )
            
            guard let data = dataPointer else { continue }
            
            let sampleCount = length / MemoryLayout<Int16>.size
            let samples = UnsafeBufferPointer(
                start: data.withMemoryRebound(to: Int16.self, capacity: sampleCount) { $0 },
                count: sampleCount
            )
            
            // Check if this buffer contains non-silent audio
            let hasAudio = samples.contains { abs(Float($0)) > linearThreshold }
            
            let bufferDuration = Double(sampleCount) / Double(sampleRate)
            
            if hasAudio {
                if !foundNonSilence {
                    // Found first non-silent sample
                    trimStart = currentTime
                    foundNonSilence = true
                }
                lastNonSilentTime = currentTime + bufferDuration
            }
            
            currentTime += bufferDuration
            
            // Update progress (advance by 1 for each buffer processed)
            progress?.advance(by: 1)
        }
        
        // Calculate trim from end
        if foundNonSilence {
            trimEnd = max(0, duration - lastNonSilentTime)
        } else {
            // Entire file is silence - trim all from start
            return SilenceDetectionResult(duration: duration, trimStart: duration, trimEnd: 0)
        }
        
        return SilenceDetectionResult(duration: duration, trimStart: trimStart, trimEnd: trimEnd)
    }
    
    // MARK: - Sync Implementation
    
    /// Detects silence at the beginning and end of an audio file (synchronous).
    ///
    /// This is a convenience wrapper that runs the async version synchronously.
    /// For better performance and cancellation support, use the async version.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file.
    ///   - threshold: Audio level threshold in dB (default: -90dB for near-zero detection).
    /// - Returns: Result containing duration and trim points.
    /// - Throws: Error if detection fails.
    public func detectSilence(
        at url: URL,
        threshold: Float = -90.0
    ) throws -> SilenceDetectionResult {
        // Use a thread-safe wrapper to bridge async to sync
        final class ResultBox: @unchecked Sendable {
            var result: SilenceDetectionResult?
            var error: Error?
        }
        
        let box = ResultBox()
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                box.result = try await detectSilence(at: url, threshold: threshold, progress: nil)
            } catch {
                box.error = error
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = box.error {
            throw error
        }
        
        guard let result = box.result else {
            throw FCPXMLError.documentOperationFailed("Silence detection failed")
        }
        
        return result
    }
}
#endif
