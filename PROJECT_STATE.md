# PROJECT_STATE.md - BangBangBeam 開発状況管理

最終更新日時: 2026-11-05 14:38 (JST / Asia/Tokyo)
現在バージョン: `v1.0.1`

---

## 1. プロジェクト概要・仕様サマリ

- **アプリ名称:** BangBangBeam（バンバンビーム）
- **対象OS / 技術スタック:** iOS 17.0+ (Xcode最新プロジェクト `project.xcproj` 同期対応) / SwiftUI / Swift Observation (`@Observable`)
- **Bundle Identifier:** `com.lldkinn9.BangBangBeam`
- **GitHub リポジトリ:** `https://github.com/lldkinn9/BangBangBeam.git`
- **世界観・カラー:** サイバーパンク（ネオ東京 2099）
  - ネオンシアン (`#06B6D4`) / エメラルドグリーン (`#10B981`) / サイバーブラック (`#05080F`)
- **主要機能:**
  1. **タイトル画面 (`TitleView`)**
     - `Assets.xcassets` の `"Title"` (`Title.imageset/Title.jpg`) を全画面表示、上下端のみ薄いグラデーション配置でキャラクター非干渉を実現。
     - 夜空エリアにネオンシアン発光ロゴ「BANG BANG BEAM」表示（余計なサブテキスト排除）。
     - 中央道路上に幅 `220px` の斜めポリゴンカット（`CyberShape`）STARTボタン＋パルス発光アニメーション。
     - STARTタップ時に黒スモーク（`Color.black.opacity(0.72)`）がフェードインし、`KUMITE` / `PRACTICE` / `SETTING` / `✕ BACK` が縦並び展開。
     - ヘッダー右上に小型バージョン表示（`v1.0.1`）。
  2. **バトル画面 (`BattleView`) & ゲームエンジン (`GameEngine`)**
     - 3拍子リズムループ（0拍目「せっせっせーの...」→ 1拍目「💥 バン！」→ 2拍目「💥 バン！」→ 3拍目「⚡️ ビーム！」）、デフォルト 88 BPM（約0.68秒/拍）。
     - 触覚フィードバック対応（1・2拍目: Light、コマンド選択: Medium、3拍目激突: Heavy、お手つき自滅: Rigid）。
     - 気力ストック（0〜5個）のオーブ可視化（`EnergyOrbView`）。
     - 4コマンド判定（チャージ・ビーム・バリア・メガビーム）および気力不足で3拍目を迎えた際の「お手つき自滅！YOU LOSE」即敗北ロジック。
     - 確率ベースCPU思考ロジック（気力0: チャージ70%/バリア30%、気力1以上＆相手気力あり: バリア40%/ビーム40%/チャージ20%、気力2以上: メガビーム55%）。
     - PRACTICEモードでの手動1拍進行（＋AUTO切替対応）。
     - ヘッダー左「◀ TITLE」ボタンおよびヘッダー右の小型バージョン表示（`v1.0.1`）。
  3. **設定シート (`SettingSheetView`)**
     - BPM速度変更（60〜140 BPM、標準88 BPMワンタップ復帰）、先取本数設定、触覚フィードバックON/OFF、ルールガイド表示。
  4. **アセット・バージョン管理機構**
     - `AppIcon.appiconset` にサイバーパンク手遊びビームの 1024x1024 アプリアイコン (`AppIcon.png`) を組み込み済み（Light / Dark / Tinted 対応）。
     - `Title.imageset` にタイトル背景 (`Title.jpg`) を組み込み済み。
     - `npm run version:bump`（`scripts/bump-version.js`）により `package.json`・`AppVersion.swift`・`project.xcproj` (`MARKETING_VERSION`) を `0.0.1` 刻みで自動更新。

---

## 2. ディレクトリ構成

```text
BangBangBeam/
├── GEMINI.md                                    # プロジェクト絶対遵守ルール
├── PROJECT_STATE.md                             # 開発進捗・仕様・履歴管理（本ファイル）
├── app_spec.md                                  # 詳細仕様書
├── package.json                                 # バージョン管理スクリプト定義 (v1.0.1)
├── scripts/
│   └── bump-version.js                          # 0.0.1 インクリメント自動化スクリプト
├── BangBangBeam.xcodeproj/                      # Xcode プロジェクト設定
│   └── project.xcproj
└── BangBangBeam/                                # iOS アプリ SwiftUI ソース & アセット一式
    ├── App/
    │   └── BangBangBeamApp.swift
    ├── Models/
    │   ├── AppVersion.swift
    │   ├── AppScreen.swift
    │   ├── GameMode.swift
    │   └── GameAction.swift
    ├── ViewModels/
    │   └── GameEngine.swift
    ├── Views/
    │   ├── Title/
    │   │   └── TitleView.swift
    │   ├── Battle/
    │   │   ├── BattleView.swift
    │   │   └── EnergyOrbView.swift
    │   ├── Settings/
    │   │   └── SettingSheetView.swift
    │   └── Components/
    │       ├── CyberTheme.swift
    │       ├── CyberShape.swift
    │       └── CyberButtonStyle.swift
    └── Assets.xcassets/
        ├── AppIcon.appiconset/ (AppIcon.png 1024x1024)
        └── Title.imageset/     (Title.jpg)
```

---

## 3. 開発進捗・残タスク

### 完了済み
- [x] `GEMINI.md`・`PROJECT_STATE.md`・`.gitignore` の整備
- [x] バージョン管理機構（ヘッダー小型表示 & `npm run version:bump` による `project.xcproj` 連動スクリプト）の実装
- [x] Models / ViewModels / Views / Components 分割構成によるコアアプリ一式の実装
- [x] Mac側の Xcode プロジェクト設定（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 等）に合わせた Concurrency 対応（`CyberShape`, `Identifiable`, `Equatable` の `nonisolated` 対応）
- [x] アプリアイコン (`AppIcon.png` 1024x1024) の新規作成および `Title.imageset` の `Assets.xcassets` への組み込み
- [x] `v1.0.1` バンプおよび GitHub リポジトリ (`main`) への統合コミット・プッシュ

### 残タスク（次フェーズ以降）
- [ ] Mac側で `git pull` を実行し、Xcode シミュレータ／実機でのビルド・UI表示・触覚フィードバック動作確認
- [ ] （拡張検討）`素材/` フォルダ内の BGM・SE・キャラクター立ち絵／カットイン演出の統合

---

## 4. 更新履歴 (JST)

- **2026-11-05 14:38 (`v1.0.1`)**
  - Mac側初回コミット (`BangBangBeam.xcodeproj`) を取り込み、初期テンプレート (`BangBangBeamApp.swift`, `ContentView.swift`) を整理して分割済み SwiftUI コード一式を統合。
  - Xcode の `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 設定に適合するよう、`CyberShape` / `GameMode` / `GameAction` / `BattleOutcome` のプロトコル準拠を `nonisolated` 化。
  - iPhone 画面向きを縦画面 (`Portrait`) に設定。
  - 1024x1024 専用アプリアイコン (`AppIcon.png`) の生成・登録、および `Title.imageset` (`Title.jpg`) の登録を実施。
  - `npm run version:bump` により `1.0.0 -> 1.0.1` へ更新し、GitHub `main` ブランチへプッシュ。
- **2026-11-05 13:59 (`v1.0.0`)**
  - 初版コアコード一式、`GEMINI.md`、`PROJECT_STATE.md`、バージョン自動更新スクリプトを作成。
