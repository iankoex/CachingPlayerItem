//
//  CodableURLResponse.swift
//  AudioVisualService
//
//  Created by ian on 09/10/2025.
//

import Foundation

struct CodableURLResponse: Codable {
    var expectedContentLength: Int
    var suggestedFilename: String?
    var mimeType: String?
    var textEncodingName: String?
    var url: URL?
    var dataRanges: [NSRange] = []

    var urlResponse: URLResponse {
        URLResponse(
            url: url ?? URL(string: "https://example.com")!,
            mimeType: mimeType,
            expectedContentLength: expectedContentLength,
            textEncodingName: textEncodingName
        )
    }

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
