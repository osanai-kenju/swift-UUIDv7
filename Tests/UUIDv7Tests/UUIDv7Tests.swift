//
//  UUIDv7Tests.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/09/20.
//

import Foundation
import Synchronization
import Testing
@testable import UUIDv7

final class FakeClock: Sendable {
    private let ms: Atomic<UInt64>
    init(_ initial: UInt64) { ms = Atomic(initial) }
    func now() -> UInt64 { ms.load(ordering: .relaxed) }
    func set(_ value: UInt64) { ms.store(value, ordering: .relaxed) }
}

// for i in 1 2 3 4 5 6 7 8 9 10; do swift test -c release -Xswiftc -enable-testingが通ったので一旦コメントアウトしておく
//@Suite(.serialized)
struct UUIDv7Tests {
    // 1. 生成したUUIDのバージョンが7になっている
    @Test func versionIs7() {
        for _ in 0..<1000 {
            let id = UUIDv7Generator.generate()
            #expect(id.uuid.6 >> 4 == 7)
        }
    }
    
    // 2. バリアントの上位2bitが10になっている
    @Test func variantIsValid() {
        for _ in 0..<1000 {
            let id = UUIDv7Generator.generate()
            #expect(id.uuid.8 >> 6 == 2)
        }
    }
    
    // 3. 注入した時刻がそのままエンコードされる
    @Test func unixMillisecondsRoundTripsAtBitBoundaries() {
        var values: [UInt64] = [0, (1 << 48) - 1]
        for i in 0..<48 {
            values.append(1 << i)        // i ビット目だけが立っている
            values.append((1 << i) - 1)  // i ビット目より下が全部立っている
        }
        for T in values {
            let core = UUIDv7Core(clock: { T })
            #expect(core.generate().unixMilliseconds == T)
        }
    }
    
    // 4. 10万回連続で生成して、常に昇順になる
    @Test func monotonic() {
        let ids = (0..<100000).map { _ in
            UUIDv7Generator.generate()
        }
        
        #expect(zip(ids, ids.dropFirst()).allSatisfy(<))
    }
    
    // 5. カウンタが4095を超えても昇順が崩れない
    @Test func counterOverflowAdvancesTimestamp() {
        let T: UInt64 = 1_700_000_000_000
        let core = UUIDv7Core(clock: { T })   // 時刻は動かない

        let ids = (0..<4097).map { _ in core.generate() }

        #expect(zip(ids, ids.dropFirst()).allSatisfy(<))
        // 最初の4096個は T、4097個目は T+1 になっているはず
        let unixMillisecondsList = ids.map { $0.unixMilliseconds }
        #expect(unixMillisecondsList.dropLast(1).allSatisfy { $0 == T } && unixMillisecondsList.last! == T + 1)
    }
    
    // 6. TaskGroupで並列に生成しても重複しない
    @Test func noDuplicatesAcrossTasks() async {
        let taskCount = 8
        let perTask = 10000
        
        let all = await withTaskGroup { group in
            for _ in 0..<taskCount {
                group.addTask {
                    (0..<perTask).map { _ in UUIDv7Generator.generate() }
                }
            }
            var result = [UUID]()
            for await ids in group { result += ids }
            return result
        }
        
        #expect(Set(all).count == perTask * taskCount)
    }
    
    // 7. バージョン7以外のUUIDではtimestampがnilを返す
    @Test func timestampIsNilForNonV7() {
        let id = UUID()
        #expect(id.timestamp == nil)
        #expect(id.unixMilliseconds == nil)
    }
    
    // 8. 時計が逆行しても昇順が崩れない
    @Test func clockRollbackKeepsOrder() {
        let T: UInt64 = .random(in: 0..<(1 << 48 - 10))
        let clock = FakeClock(T + 10)
        let core = UUIDv7Core(clock: clock.now)
        
        let id = core.generate()
        
        clock.set(T)
        let retrogressed = core.generate()
        
        #expect(id < retrogressed)
        #expect(retrogressed.unixMilliseconds == T + 10)
    }
}
