//
//  UUIDv7Generator.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/02/26.
//

import Foundation
import Synchronization // Swift 6+ & iOS 18+ / macOS 15+

final class UUIDv7Core: Sendable {
    private let state = Atomic<UInt64>(0)
    private let clock: @Sendable () -> UInt64

    init(clock: @escaping @Sendable () -> UInt64 = UUIDv7Core.systemClock) {
        self.clock = clock
    }

    static func systemClock() -> UInt64 {
        var ts = timespec()
        clock_gettime(CLOCK_REALTIME, &ts)
        return UInt64(ts.tv_sec) * 1000 + UInt64(ts.tv_nsec) / 1_000_000
    }

    func generate() -> UUID {
        var current = state.load(ordering: .relaxed)
        var nextTs: UInt64 = 0
        var nextSeq: UInt64 = 0
        
        while true {
            let lastTs = current >> 12
            let lastSeq = current & 0x0FFF
            
            let now = clock()
            
            if now > lastTs {
                nextTs = now
                nextSeq = 0
            } else {
                // 同一ミリ秒内の連続生成、または時計の逆行への対処
                nextTs = lastTs
                nextSeq = lastSeq + 1
                
                // 12ビット(4095)を超えたらミリ秒を強制的に進める
                if nextSeq > 0x0FFF {
                    nextTs += 1
                    nextSeq = 0
                }
            }
            
            let nextState = (nextTs << 12) | nextSeq
            
            // 期待値(current)と一致していれば書き換える
            let result = state.compareExchange(
                expected: current,
                desired: nextState,
                successOrdering: .acquiringAndReleasing,
                failureOrdering: .relaxed
            )
            
            if result.exchanged { break }
            current = result.original // 失敗した場合は最新の値でリトライ
        }
        
        var rng = SystemRandomNumberGenerator()
        let rand = rng.next()

        return UUID(uuid: (
            UInt8((nextTs >> 40) & 0xFF),
            UInt8((nextTs >> 32) & 0xFF),
            UInt8((nextTs >> 24) & 0xFF),
            UInt8((nextTs >> 16) & 0xFF),
            UInt8((nextTs >> 8) & 0xFF),
            UInt8(nextTs & 0xFF),
            UInt8(0x70 | ((nextSeq >> 8) & 0x0F)),
            UInt8(nextSeq & 0xFF),
            UInt8(0x80 | ((rand >> 56) & 0x3F)),
            UInt8((rand >> 48) & 0xFF),
            UInt8((rand >> 40) & 0xFF),
            UInt8((rand >> 32) & 0xFF),
            UInt8((rand >> 24) & 0xFF),
            UInt8((rand >> 16) & 0xFF),
            UInt8((rand >> 8) & 0xFF),
            UInt8(rand & 0xFF)
        ))
    }
}

public enum UUIDv7Generator {
    private static let core = UUIDv7Core()

    public static func generate() -> UUID {
        core.generate()
    }
}
