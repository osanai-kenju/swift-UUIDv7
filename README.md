# swift-UUIDv7

[![Test](https://github.com/osanai-kenju/swift-UUIDv7/actions/workflows/test.yml/badge.svg)](https://github.com/osanai-kenju/swift-UUIDv7/actions/workflows/test.yml)

RFC 9562のUUIDv7を生成するSwiftライブラリ。同一プロセス内で常に昇順になる。

## 使い方

```swift
import UUIDv7

let id = UUIDv7Generator.generate()

id.unixMilliseconds  // UInt64? — Unixエポックからのミリ秒。v7以外はnil
id.timestamp         // Date?   — 上をDateにしたもの。ミリ秒未満の精度はない
```

## 動作環境

Swift 6.2以上、iOS 18以上、macOS 15以上。
(`Synchronization`モジュールの`Atomic`を使っているため)

## 実装

- ビット構成: 48bitのミリ秒タイムスタンプ、バージョン(7)、12bitのカウンタ、バリアント(`10`)、62bitの乱数
- 状態(最後のタイムスタンプとカウンタ)を1つの`UInt64`にまとめ、`Atomic`のcompare-and-exchangeでロックなしに更新する

## 設計判断

- **カウンタは各ミリ秒の開始時に0から始める。** RFC 9562 §6.2のMethod 1(rand_aをカウンタとして使う方式)。RFCは新しいミリ秒ごとにランダムな値で初期化することを推奨しているが、個人利用で推測されにくさは重要でないため、単純さと1ミリ秒あたりの生成可能数を優先した。
- **カウンタが4095を超えたら、待たずにタイムスタンプを1ms進める。** ブロックも失敗もしない代わりに、極端な高頻度生成の間は、タイムスタンプが実時間より先行することがある。保証するのは「常に昇順」であり、「実時間との一致」ではない。
- **時計が逆行しても、最後に使ったタイムスタンプを使い続ける。** 昇順を保つため。

## 制限

- 昇順が保証されるのは、同一プロセスの中だけ。
- タイムスタンプは48bitなので、表現できるのは西暦10889年ごろまで。

## テスト

```bash
swift test
```

時刻を差し替えられる内部の型(`UUIDv7Core`)で、桁あふれや時計の逆行を、時刻を固定して決定的にテストしている。

## ライセンス

個人利用のために作成したもので、ライセンスは設定していません(All rights reserved)。

## 備考

ほとんどLLMの出力をそのまま使って制作しました。
