//
//  UUIDv7Tests.swift
//  UUIDv7
//
//  Created by 長内健樹 on 2026/09/20.
//

import Testing
@testable import UUIDv7
import Foundation

@Suite(.serialized)
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
    
    // 3. timeStampが現在時刻とほぼ一致する
    // 時刻に依存するテストは別Issueで書き直す
//    @Test func timeStampIsCloseToNow() throws {
//        // _ = (0..<100_000).map { _ in UUIDv7Generator.generate() }
//        let before = Date()
//        let id = UUIDv7Generator.generate()
//        let after = Date()
//        
//        let timeStamp = try #require(id.timeStamp, "v7のUUIDなのにtimeStampがnilを返した")
//        
//        #expect(before - 1e-3 < timeStamp)
//        #expect(timeStamp < after + 1e-3)
//    }
    
    // 4. 10万回連続で生成して、常に昇順になる
    @Test func monotonic() {
        var ids = Array<UUID>()
        ids.reserveCapacity(100000)
        for _ in 0..<100000 {
            ids.append(UUIDv7Generator.generate())
        }
        
        #expect(zip(ids, ids.dropFirst()).allSatisfy(<))
    }
    
    // 5. カウンタが4095を超えても昇順が崩れない
    // 時刻に依存するテストは別Issueで書き直す
    
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
    
    // 7. バージョン7以外のUUIDではtimeStampがnilを返す
    @Test func timeStampIsNilForNonV7() {
        let id = UUID()
        #expect(id.timeStamp == nil)
    }
}
