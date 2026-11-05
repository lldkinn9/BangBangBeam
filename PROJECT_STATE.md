# PROJECT_STATE.md - BangBangBeam 開発状況管理

最終更新日時: 2026-11-05 14:54 (JST / Asia/Tokyo)
現在バージョン: `v1.0.2`

---

## 1. プロジェクト概要・仕様サマリ

- **アプリ名称:** BangBangBeam（バンバンビーム）
- **対象OS / 技術スタック:** **iOS 17.0+** (`IPHONEOS_DEPLOYMENT_TARGET = 17.0`) / SwiftUI / Swift Observation (`@Observable`)
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
     - ヘッダー右上に小型バージョン表示（`v1.0.2`）。
  2. **バトル画面 (`BattleView`) & ゲームエンジン (`GameEngine`)**
     - 3拍子リズムループ（0拍目「せっせっせーの...」→ 1拍目「💥 バン！」→ 2拍目「💥 バン！」→ 3拍目「⚡️ ビーム！」）、デフォルト 88 BPM（約0.68秒/拍）。
     - 触覚フィードバック対応（1・2拍目: Light、コマンド選択: Medium、3拍目激突: Heavy、お手つき自滅: Rigid）。
     - 気力ストック（0〜5個）のオーブ可視化（`EnergyOrbView`）。
     - 4コマンド判定（チャージ・ビーム・バリア・メガビーム）および気力不足で3拍目を迎えた際の「お手つき自滅！YOU LOSE」即敗北ロジック。
     - 確率ベースCPU思考ロジック（気力0: チャージ70%/バリア30%、気力1以上＆相手気力あり: バリア40%/ビーム40%/チャージ20%、気力2以上: メガビーム55%）。
     - PRACTICEモードでの手動1拍進行（＋AUTO切替対応）。
     - ヘッダー左「◀ TITLE」ボタンおよびヘッダー右の小型バージョン表示（`v1.0.2`）。
  3. **設定シート (`SettingSheetView`)**
     - BPM速度変更（60〜140 BPM、標準88 BPMワンタップ復帰）、先取本数設定、触覚フィードバックON/OFF、ルールガイド表示。
  4. **アセット・バージョン管理機構**
     - `AppIcon.appiconset` に主人公（レオ）がビームを放つアップ構図の 1024x1024 アプリアイコン (`AppIcon.png`) を組み込み済み（Light / Dark / Tinted 対応）。
     - `Title.imageset` にタイトル背景 (`Title.jpg`) を組み込み済み。
     - `npm run version:bump`（`scripts/bump-version.js`）により `package.json`・`AppVersion.swift`・`project.xcproj` (`MARKETING_VERSION`) を `0.0.1` 刻みで自動更新。

---

## 2. ディレクトリ構成

```text
BangBangBeam/
├── GEMINI.md                                    # プロジェクト絶対遵守ルール
├── PROJECT_STATE.md                             # 開発進捗・仕様・履歴管理（本ファイル）
├── app_spec.md                                  # 詳細仕様書
├── package.json                                 # バージョン管理スクリプト定義 (v1.0.2)
├── scripts/
│   └── bump-version.js                          # 0.0.1 インクリメント自動化スクリプト
├── BangBangBeam.xcodeproj/                      # Xcode プロジェクト設定 (iOS 17.0+)
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
        ├── AppIcon.appiconset/ (AppIcon.png 1024x1024 - 主人公レオ版)
        └── Title.imageset/     (Title.jpg)
```

---

## 3. 開発進捗・残タスク

### 完了済み
- [x] `GEMINI.md`・`PROJECT_STATE.md`・`.gitignore` の整備
- [x] バージョン管理機構（ヘッダー小型表示 & `npm run version:bump` による `project.xcproj` 連動スクリプト）の実装
- [x] Models / ViewModels / Views / Components 分割構成によるコアアプリ一式の実装
- [x] Mac側の Xcode プロジェクト設定（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 等）に合わせた Concurrency 対応
- [x] リリース向けに Minimum Deployments（対象OS）を `iOS 17.0` へ変更
- [x] 主人公（レオ）アップ構図の新アプリアイコン (`AppIcon.png` 1024x1024) 生成および差し替え完了
- [x] `v1.0.2` バンプおよび GitHub リポジトリ (`main`) へのコミット・プッシュ

### 残タスク（次フェーズ以降）
- [ ] Mac側で `git pull origin main` を実行し、Xcode 上でのビルド（`⌘ + R`）およびシミュレータ／実機での動作確認
- [ ] （拡張検討）`素材/` フォルダ内の BGM・SE・キャラクター立ち絵／カットイン演出・手イラストの統合

---

## 4. 更新履歴 (JST)

- **2026-11-05 14:54 (`v1.0.2`)**
  - リリース対象ユーザー拡大のため、`BangBangBeam.xcodeproj/project.xcproj` の `IPHONEOS_DEPLOYMENT_TARGET` を `27.2` から `17.0` へ変更。
  - `Title.jpg` の絵柄・世界観を維持した主人公（レオ）アップ構図の新アプリアイコン (`AppIcon.png` 1024x1024) を作成・差し替え。
  - `npm run version:bump` により `1.0.1 -> 1.0.2` へ更新し、GitHub `main` ブランチへプッシュ。
- **2026-11-05 14:42 (`v1.0.1`)**
  - Mac側ターミナルにて `git pull origin main` が正常完了したことを確認。
- **2026-11-05 14:38 (`v1.0.1`)**
  - Mac側初回コミットを取り込み、分割済み SwiftUI コード一式・`Title.imageset`・初期アイコンを統合し `v1.0.1` としてプッシュ。
- **2026-11-05 13:59 (`v1.0.0`)**
  - 初版コアコード一式、`GEMINI.md`、`PROJECT_STATE.md`、バージョン自動更新スクリプトを作成。
