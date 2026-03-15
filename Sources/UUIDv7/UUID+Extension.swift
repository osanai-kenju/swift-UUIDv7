//
//  UUID+Extension.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/02/26.
//

import Foundation

extension UUID {
    public var timeStamp: Date? {
        let bytes = self.uuid
        
        // version 7 check
        guard (bytes.6 & 0xF0) == 0x70 else { return nil }
        
        let millis =
        (UInt64(bytes.0) << 40) |
        (UInt64(bytes.1) << 32) |
        (UInt64(bytes.2) << 24) |
        (UInt64(bytes.3) << 16) |
        (UInt64(bytes.4) << 8)  |
        UInt64(bytes.5)
        
        return Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
    }
}
