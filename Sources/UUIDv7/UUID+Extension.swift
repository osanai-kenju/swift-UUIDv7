//
//  UUID+Extension.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/02/26.
//

import Foundation

extension UUID {
    /// UUIDv7に埋め込まれた生成時刻(Unixエポックからの絶対時刻)。v7以外はnil。
    /// ミリ秒未満の精度はない。厳密な整数値が必要なら `unixMilliseconds` を使う。
    public var timestamp: Date? {
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
