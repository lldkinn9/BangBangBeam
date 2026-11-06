# PROJECT_STATE.md - BangBangBeam 開発状況管理

最終更新日時: 2026-11-06 17:19 (JST / Asia/Tokyo)
現在バージョン: `v1.0.9`（全21キャラクターのネイティブ背景透過PNG画像差し替え反映 ＆ 設定画面BATTLE RULES表記更新）

---

## 1. プロジェクト概要・製品版実装済み仕様

- **アプリ名称:** BangBangBeam（バンバンビーム）
- **対象OS / 技術スタック:** **iOS 17.0+** (`IPHONEOS_DEPLOYMENT_TARGET = 17.0`) / SwiftUI / Swift Observation (`@Observable`) / AVFoundation / GameKit / AppTrackingTransparency
- **Bundle Identifier:** `com.lldkinn9.BangBangBeam`
- **GitHub リポジトリ:** `https://github.com/lldkinn9/BangBangBeam.git`

### 1.1 ゲームモード & 初回起動導線
1. **初回起動時フロー (`PracticeTutorialView`):**
   - 初回アプリ起動時は自動的に **PRACTICE（チュートリアル）モード** を起動（`UserDefaults` 管理）。
   - 専用UIにて「📘 ルール学習（全5ステップ・必殺プレビュー付き）」と「🎯 フリー実戦（1拍手動進行 / AUTO練習）」を切り替え可能。
2. **KUMITEモード（メイン：全20敵キャラ対応 勝ち抜きサバイバル）:**
   - プレイヤーは主人公 **`Reo` 固定**。
   - **1周目（1〜11人目）:** 基本敵11名が登場（`geek` → `boarder` → `JK` → `engineer` → `alice` → `defective` → `spy` → `Ninja` → `pirate` → `skin` → `oldman`）。
   - **2周目（12〜31人目）:** 前半12〜22人目は既存11名が登場し、**23〜31人目**から追加9名（`tt` → `mei` → `clown` → `owl` → `rondo` → `ive` → `joker` → `elf` → `rui`）が登場。
   - **3周目以降（32人目〜）:** 「既存11名 → 追加9名」の計20名サイクルを周回。
   - 敵AIはお手つきを一切行わず、キャラクターごとに `AITraits`（攻撃積極度・バリア警戒度・必殺指向・状況読み精度）を段階設定し明確な強弱を実現。
   - 敵を1人撃破するごとに Reo の体力（`HP = 3`）は全回復し、チャージは `0` にリセットして次戦へ進行。
   - **世界ランキング:** Apple 公式 **Game Center (`GameKit`)** 連携 (`GameCenterManager` / `RankingInfoSheetView`) により、最大連勝数の自動送信および「自分の順位 ＋ 世界 1位〜100位」のランキング一覧を表示（撃破キャラ一覧は廃止）。

### 1.2 バトルシステム・演出
- **体力（HP = 3）＆ 被弾チャージ減少:** 通常ビーム命中時、被弾側は **HP -1** かつ **蓄積チャージ -1**。3回被弾で敗退。
- **お手つき（無防備）仕様:** 気力不足でビーム／必殺ビームを選んで3拍目を迎えると **不発（無防備状態 `.fumble`）** となり、チャージ増加もガードもなく相手のビームが直撃する。
- **4チャージ一撃必殺（必殺ビーム）:** 4回チャージで解放。発動時は **目元カットイン演出 (`char_<id>_cutin`) → 必殺アニメーション動画 (`ult_<id>.mp4`)** を再生し、バリア・残りHPを貫通して一撃決着。
- **ビジュアル＆BGM (`SoundManager`):**
  - 全12キャラの背景透過立ち絵（通常・喜び・苦痛）＆カットイン画像、手イラスト4種（手拍子・チャージ・バリア・ビーム）、必殺動画12本を組み込み済み。
  - 非バトル画面で `Neon Overdrive`、バトル画面で `Seamless Looping Cyberpunk BGM` / `Cyber Velocity` をランダム選出しループ再生（設定画面で BGM ON/OFF 切替可能）。

### 1.3 収益化（Google AdMob 基盤 `AdManager`）
- **バナー広告 (`AdBannerFooterView`):** プレイ画面（`BattleView` / `PracticeTutorialView`）以外の全画面（タイトル・モード選択・設定・ランキングシート）の最下部に常設配置。
- **インタースティシャル広告:** KUMITE リトライ時に **3回につき1回** スキップ可能な全画面広告を表示。
- `#if canImport(GoogleMobileAds)` に対応済み。Xcode で `GoogleMobileAds` Swift Package を追加するだけで実テスト広告が配信され、リリース時は `Info.plist` キー（`ADMOB_BANNER_UNIT_ID` / `ADMOB_INTERSTITIAL_UNIT_ID` / `GADApplicationIdentifier`）で本番IDを安全に注入可能（コードへのハードコードなし）。

---

## 2. 開発進捗・残タスク

### 完了済み
- [x] **Phase 1:** 全67アセット（12キャラ透過立ち絵36枚・カットイン12枚・必殺動画12本・手イラスト4枚・BGM3曲）の最適化＆組み込み＋`SoundManager` 実装
- [x] **Phase 2:** 新ゲームエンジン（HP3・被弾チャージ-1・お手つき無防備・4チャージ一撃必殺・11キャラ段階別AI・撃破時HP全回復勝ち抜きループ）実装
- [x] **Phase 3:** 新 `BattleView` 演出（立ち絵表情連動・手イラスト変化・カットイン＋`mp4` 動画再生）＆初回起動対応 `PracticeTutorialView` 専用UI実装
- [x] **Phase 4:** `GameCenterManager` 連勝数世界ランキング連携＆撃破リストシート実装
- [x] **Phase 5 (基盤):** `AdManager`・非プレイ画面共通バナー枠・リトライ時全画面広告制御・ATT許可リクエスト実装
- [x] `v1.0.4` バージョンバンプおよび GitHub `main` ブランチへのプッシュ

### 残タスク（確認・ブラッシュアップ・リリース準備）
- [ ] Mac側で `git pull origin main` を実行し、シミュレータ／実機で新システム一式（初回チュートリアル・BGM・手イラスト・必殺カットイン＆動画・11人勝ち抜き）の動作確認とバランス・UI微調整
- [ ] Xcode から `GoogleMobileAds` Swift Package（`https://github.com/googleads/swift-package-manager-google-mobile-ads.git`）を追加し、テスト広告の描画確認（本番リリース前に AdMob 本番IDを設定）
- [ ] App Store Connect での Game Center Leaderboard（ID: `com.lldkinn9.BangBangBeam.kumite_streak`）登録および Archive 提出準備
- [ ] （任意）拍手音・ビーム音などの SE（効果音）音源追加

---

## 3. 更新履歴 (JST)

- **2026-11-06 17:19 (`v1.0.9`)**
  - **全21キャラ分の差し替え済みネイティブ背景透過PNG反映:** `素材/Characters/` 配下の全21キャラクター（主人公 `reo` ＋ 敵20名）の通常・喜び・苦痛（計63枚）を、オーナー差し替え済みのネイティブ透過PNG（`RGBA`）から直接リサイズ・トリミングして [`Assets.xcassets/Characters`](BangBangBeam/Assets.xcassets/Characters) に反映。
  - **設定画面 `BATTLE RULES` の表記刷新（アイコン削除）:** [`SettingSheetView.swift`](BangBangBeam/Views/Settings/SettingSheetView.swift) の `BATTLE RULES` セクションからアイコン・絵文字を削除し、指定文面（〇3ライフ体力制 / 〇チャージ / 〇ビーム / 〇バリア / 〇必殺技 / 〇お手付き）へ更新。
- **2026-11-06 16:52 (`v1.0.8`)**
  - **バージョン表示のタイトル右上限定化:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) および [`PracticeTutorialView.swift`](BangBangBeam/Views/Practice/PracticeTutorialView.swift) からバージョン表示を削除し、[`TitleView.swift`](BangBangBeam/Views/Title/TitleView.swift) の右上のみに表示するよう統一。
  - **モード選択メニューの表記変更:** `KUMITE`（勝ち抜きサバイバル（ランキング対象））、`PRACTICE`（ルール学習）、`RANKING`（世界ランキング）、`SETTING`（各種設定）へサブタイトル文言を更新。
  - **ランキング画面の刷新（自分の順位 ＋ 1〜100位表示）:** [`GameCenterManager.swift`](BangBangBeam/Services/GameCenterManager.swift) に `GKLeaderboard.loadEntries`（`1...100`）取得ロジックを実装し、[`RankingInfoSheetView.swift`](BangBangBeam/Views/Title/RankingInfoSheetView.swift) を「自分の順位・自己ベスト」と「1位〜100位リスト」のみの構成に刷新（撃破キャラクターリストを削除）。
- **2026-11-06 16:32 (`v1.0.7`)**
  - **敵AIのお手つき完全廃止:** [`CharacterProfile.swift`](BangBangBeam/Models/CharacterProfile.swift) と [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) から敵のお手つき確率・分岐を削除し、気力不足の行動を絶対に選択しない安全ガードを追加。
  - **設定画面のバージョン非表示化:** [`SettingSheetView.swift`](BangBangBeam/Views/Settings/SettingSheetView.swift) のナビゲーションバー左上からバージョン表記を削除。
  - **追加敵キャラクター9名の素材検証＆2周目（23人目以降）ループ統合:** 新規9名（`tt`, `mei`, `clown`, `owl`, `rondo`, `ive`, `joker`, `elf`, `rui`）の全45ファイルの整合性を確認し、背景透過立ち絵27枚・カットイン9枚・無音H.264動画9本を生成・登録。1〜11人目＝既存11名、12〜22人目＝既存11名、23〜31人目＝追加9名（`tt→mei→clown→owl→rondo→ive→joker→elf→rui`）、32人目以降＝「既存11名→追加9名」の20名ループとして統合。
- **2026-11-06 14:23 (`v1.0.6`)**
  - **必殺技アニメーションの完全無音化＆BGM継続再生:** 全12キャラクター分の `ult_*.mp4` から音声トラックを完全除去（`-an`）した上で、`AVPlayer` 側も常時ミュート固定（`isMuted = true`, `volume = 0`）に設定。さらに必殺技発動中の BGM 音量ダッキング処理を解除し、元々流れている BGM が音量変化なくそのまま継続再生されるように改修。
- **2026-11-06 13:34 (`v1.0.5`)**
  - **不具合修正（必殺アニメーション非表示）:** 元動画（Google Flow生成MP4）の映像コーデックタグが `hev1`（Apple `AVFoundation` / `AVPlayer` 非対応タグ）だったためデコードエラーとなっていた問題を特定。全12本の `ult_*.mp4` を iOS 完全互換の **`H.264 (avc1, yuv420p, +faststart)`** へ再エンコード。
  - 併せて [`UltimateCutinOverlayView.swift`](BangBangBeam/Views/Battle/UltimateCutinOverlayView.swift) の `AVPlayer` プリロード処理・`AVPlayerItem.status` 監視・動画尺（約10秒）に合わせたフォールバックタイムアウト（7秒→13.5秒）・カットイン横幅クリップ・BGM設定連動ミュート制御を改善。
- **2026-11-05 16:55 (`v1.0.4`)**
  - Phase 1〜5 の製品版コア機能・全アセット（キャラ12人・手4種・動画12本・BGM3曲）・新バトルルール・初回チュートリアルUI・Game Center世界ランキング・AdMob広告制御基盤を一括実装し、`v1.0.4` としてプッシュ。
- **2026-11-05 16:36 (`v1.0.3`)**
  - 製品版全仕様確定・実装計画書作成。
