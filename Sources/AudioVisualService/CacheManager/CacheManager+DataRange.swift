//
//  CacheManager+DataRange.swift
//  AudioVisualService
//
//  Created by ian on 10/10/2025.
//

import Foundation

extension CacheManager {
    func updateCachedDataRanges(with range: NSRange) {
        if cachedCodableURLResponse == nil {
            cachedCodableURLResponse = getCachedResponse()
        }
        guard var cachedCodableURLResponse else {
            return
        }
        cachedCodableURLResponse.dataRanges.append(range)
        cachedCodableURLResponse.dataRanges.sort { $0.location < $1.location }
        cachedCodableURLResponse.dataRanges = mergeOverlappingRanges(in: cachedCodableURLResponse.dataRanges)
        self.cachedCodableURLResponse = cachedCodableURLResponse
        updateCachedURLResponse(with: cachedCodableURLResponse)
    }

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

    func getAvailableRange(for requested: NSRange) -> NSRange? {
        guard requested.length > 0 else { return nil }

        if cachedCodableURLResponse == nil {
            cachedCodableURLResponse = getCachedResponse()
        }
        guard var cachedCodableURLResponse else {
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
