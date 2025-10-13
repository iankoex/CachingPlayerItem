//
//  URL+md5String.swift
//  Some
//
//  Created by ian on 03/10/2025.
//

import CryptoKit
import Foundation

@available(macOS 13, iOS 16, tvOS 14, watchOS 7, *)
extension URL {
    /// A MD5 hash of the URL's absolute string, suitable for use as a filename.
    ///
    /// This computed property generates an MD5 hash of the URL's absolute string
    /// representation. The resulting string is safe to use as a filename and
    /// provides a consistent way to map URLs to cache file names.
    ///
    /// - Returns: A lowercase hexadecimal string representing the MD5 hash of the URL.
    internal var md5String: String {
        guard let messageData = self.absoluteString.data(using: .utf8) else {
            return self.absoluteString
        }
        let digest = Insecure.MD5.hash(data: messageData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
