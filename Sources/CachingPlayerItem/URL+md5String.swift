//
//  URL+md5String.swift
//  Some
//
//  Created by ian on 03/10/2025.
//

import CryptoKit
import Foundation

extension URL {
    internal var md5String: String {
        guard let messageData = self.absoluteString.data(using: .utf8) else {
            return self.absoluteString
        }
        let digest = Insecure.MD5.hash(data: messageData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
