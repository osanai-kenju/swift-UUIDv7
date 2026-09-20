//
//  UUID+Extension.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/02/26.
//

import Foundation

extension UUID {
    public var timeStamp: Date? {
        guard let millis = unixMilliseconds else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
    }
    
    public var unixMilliseconds: UInt64? {
        let bytes = self.uuid
        
        // version 7 check
        guard (bytes.6 & 0xF0) == 0x70, (bytes.8 & 0xC0) == 0x80 else { return nil }
        
        return (UInt64(bytes.0) << 40) |
        (UInt64(bytes.1) << 32) |
        (UInt64(bytes.2) << 24) |
        (UInt64(bytes.3) << 16) |
        (UInt64(bytes.4) << 8)  |
        UInt64(bytes.5)
    }
}
