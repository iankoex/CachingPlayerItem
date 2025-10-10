//
//  CodableURLResponse.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

/// A codable representation of URLResponse for persistent storage.
///
/// `CodableURLResponse` stores the essential information from a `URLResponse`
/// in a format that can be encoded/decoded using `Codable`. This allows
/// response metadata to be cached alongside the video data.
///
/// The struct preserves the content length, MIME type, and other response
/// properties needed for proper video playback and caching logic.
struct CodableURLResponse: Codable, Sendable {
    /// The expected length of the content in bytes.
    var expectedContentLength: Int

    /// The suggested filename for the content.
    var suggestedFilename: String?

    /// The MIME type of the content.
    var mimeType: String?

    /// The text encoding name for the content.
    var textEncodingName: String?

    /// The URL of the content.
    var url: URL?

    /// The ranges of data that have been successfully cached.
    var dataRanges: [NSRange] = []

    /// Converts the codable response back to a URLResponse.
    ///
    /// This computed property reconstructs a `URLResponse` from the stored
    /// codable properties. Note that some URLResponse properties may not
    /// be preserved in the conversion.
    var urlResponse: URLResponse {
        URLResponse(
            url: url ?? URL(string: "https://example.com")!,
            mimeType: mimeType,
            expectedContentLength: expectedContentLength,
            textEncodingName: textEncodingName
        )
    }

    /// Creates a CodableURLResponse from a URLResponse.
    ///
    /// This factory method extracts the relevant properties from a `URLResponse`
    /// and creates a codable representation suitable for storage.
    ///
    /// - Parameters:
    ///   - urlResponse: The URLResponse to convert.
    ///   - desiredExpectedContentLength: Optional override for the expected content length.
    /// - Returns: A new CodableURLResponse instance.
    static func from(_ urlResponse: URLResponse, with desiredExpectedContentLength: Int?) -> CodableURLResponse {
        return CodableURLResponse(
            expectedContentLength: desiredExpectedContentLength ?? Int(urlResponse.expectedContentLength),
            suggestedFilename: urlResponse.suggestedFilename,
            mimeType: urlResponse.mimeType,
            textEncodingName: urlResponse.textEncodingName,
            url: urlResponse.url
        )
    }
}
