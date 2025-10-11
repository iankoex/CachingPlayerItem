//
//  CacheManager+DataRange.swift
//  AudioVisualService
//
//  Created by ian on 10/10/2025.
//

import Foundation

extension CacheManager {
    /// Updates the cached data ranges to include a newly downloaded range.
    ///
    /// This method adds the specified range to the list of cached data ranges and
    /// merges any overlapping ranges to maintain a clean, non-overlapping representation.
    /// The updated ranges are persisted to disk as part of the response metadata.
    ///
    /// - Parameter range: The byte range that has been successfully cached.
    func updateCachedDataRanges(with range: NSRange) -> Int {
        if cachedCodableURLResponse == nil {
            cachedCodableURLResponse = getCachedResponse()
        }
        guard var cachedCodableURLResponse else {
            return 0
        }
        cachedCodableURLResponse.dataRanges.append(range)
        cachedCodableURLResponse.dataRanges.sort { $0.location < $1.location }
        cachedCodableURLResponse.dataRanges = mergeOverlappingRanges(in: cachedCodableURLResponse.dataRanges)
        self.cachedCodableURLResponse = cachedCodableURLResponse
        updateCachedURLResponse(with: cachedCodableURLResponse)
        return totalDataCached(from: cachedCodableURLResponse.dataRanges)
    }

    /// Merges overlapping and adjacent ranges in the provided array.
    ///
    /// This method takes an array of ranges and combines any that overlap or are
    /// contiguous (touching at the boundaries). The result is a sorted array of
    /// non-overlapping ranges that represent the same total coverage.
    ///
    /// - Parameter cachedDataRanges: An array of ranges to merge.
    /// - Returns: A new array of merged, non-overlapping ranges.
    private func mergeOverlappingRanges(in cachedDataRanges: [NSRange]) -> [NSRange] {
        guard cachedDataRanges.count > 1 else {
            return cachedDataRanges
        }
        let sortedRanges = cachedDataRanges.sorted { $0.location < $1.location }

        var mergedRanges: [NSRange] = []
        var currentMergedRange = sortedRanges[0]

        for i in 1..<sortedRanges.count {
            let nextRange = sortedRanges[i]
            // Calculate the end of the current merged range
            // NSRange's end is location + length.
            let currentEnd = currentMergedRange.location + currentMergedRange.length

            // Check if the ranges overlap or are contiguous (touching)
            // Overlap: nextRange.location < currentEnd
            // Contiguous: nextRange.location == currentEnd
            if nextRange.location <= currentEnd {
                // They overlap or touch: merge them by extending the current range
                let nextEnd = nextRange.location + nextRange.length
                let newEnd = max(currentEnd, nextEnd)
                let newLength = newEnd - currentMergedRange.location
                currentMergedRange = NSMakeRange(currentMergedRange.location, newLength)

            } else {
                mergedRanges.append(currentMergedRange)
                currentMergedRange = nextRange
            }
        }

        mergedRanges.append(currentMergedRange)
        return mergedRanges
    }

    func totalDataCached(from mergedRanges: [NSRange]) -> Int {
        var totalLength: Int = 0

        for range in mergedRanges {
            totalLength += range.length
        }

        return totalLength
    }

    /// Determines the available contiguous range starting from the requested location.
    ///
    /// This method checks if data is available starting at the requested location and
    /// returns the contiguous range that can be served from cache. If the requested
    /// location is not cached, it returns `nil`.
    ///
    /// - Parameter requested: The range for which to check availability.
    /// - Returns: The available contiguous range starting at the requested location, or `nil` if not available.
    func getAvailableRange(for requested: NSRange) -> NSRange? {
        guard requested.length > 0 else { return nil }

        if cachedCodableURLResponse == nil {
            cachedCodableURLResponse = getCachedResponse()
        }
        guard let cachedCodableURLResponse else {
            return nil
        }

        // Since cachedDataRanges are sorted and non-overlapping, we can iterate or binary search.
        // For simplicity, linear search (fine for small arrays).
        for cached in cachedCodableURLResponse.dataRanges {
            if cached.location <= requested.location && requested.location < cached.location + cached.length {
                // Start is covered; compute available length forward
                let availableEnd = cached.location + cached.length
                let availableLength = availableEnd - requested.location
                let clampedLength = min(requested.length, availableLength)
                return NSMakeRange(requested.location, clampedLength)
            }
        }

        // Start location not covered
        return nil
    }
}
