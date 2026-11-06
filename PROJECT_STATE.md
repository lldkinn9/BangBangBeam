# PROJECT_STATE.md - BangBangBeam 開発状況管理

最終更新日時: 2026-11-06 22:09 (JST / Asia/Tokyo)
現在バージョン: `v1.0.21`（設定画面へのBGM・SE個別音量スライダー実装 ＆ SE音源音圧最適化）

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

### 1.3 収益化（Google AdMob 基盤 `AdManager`：バナー広告 ＋ 復活リワード動画広告）
- **バナー広告 (`AdBannerFooterView`):** プレイ画面（`BattleView` / `PracticeTutorialView`）以外の全画面（タイトル・モード選択・設定・アイコン設定・ランキングシート）の最下部に常設配置。
- **復活リワード動画広告 (`RewardedAd`):** KUMITE 敗北時の結果画面に「動画広告を見て復活」を搭載。**1回の KUMITE 挑戦につき最大2回まで**、動画広告を最後まで視聴することで現在の連勝記録を維持したまま負けたバトルをやり直し可能（従来のリトライ時インタースティシャル広告は廃止し、バナー＋リワード動画広告の2本柱に一本化）。
- `#if canImport(GoogleMobileAds)` に対応済み。Xcode で `GoogleMobileAds` Swift Package を追加するだけで実テスト広告が配信され、リリース時は `Info.plist` キー（`ADMOB_BANNER_UNIT_ID` / `ADMOB_REWARDED_UNIT_ID` / `GADApplicationIdentifier`）で本番IDを安全に注入可能（コードへのハードコードなし）。

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
- [ ] Mac側で `git pull origin main` を実行し、シミュレータ／実機で `v1.0.21`（設定画面のBGM・SE個別音量設定 ＆ OFF時の完全無音連動）の動作確認
- [ ] **【本番提出前必須】** ランキング画面の表示確認完了後、`GameCenterManager.useMockRankingForPreview` を `false` に切り替えて本番 Game Center 通信のみに戻す
- [ ] Xcode から `GoogleMobileAds` Swift Package（`https://github.com/googleads/swift-package-manager-google-mobile-ads.git`）を追加し、テスト用バナー広告＆リワード動画広告の描画確認（本番リリース前に AdMob 本番IDを設定）
- [ ] App Store Connect での Game Center Leaderboard（ID: `com.lldkinn9.BangBangBeam.kumite_streak`）登録および Archive 提出準備

---

## 3. 更新履歴 (JST)

- **2026-11-06 22:09 (`v1.0.21`)**
  - **設定画面に BGM 音量・SE（効果音）音量の個別スライダー実装 ＆ SE音圧の最適化:** [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift) に `bgmVolume`（初期値 45%）および `seVolume`（初期値 90%）の `UserDefaults` 永続化・リアルタイム反映処理を実装し、[`SettingSheetView.swift`](BangBangBeam/Views/Settings/SettingSheetView.swift) の `AUDIO & HAPTICS` セクションに 0%〜100%（5%刻み）の音量スライダーを追加（サウンド設定が OFF の場合はスライダー値にかかわらず BGM・SE ともに一切音が出ない仕様を維持）。あわせてバンドル内の `button.mp3` / `cutin.mp3` の音圧バランスも歪みなく最適化。

- **2026-11-06 21:55 (`v1.0.20`)**
  - **ボタン効果音（`button.mp3`）の対象限定 ＆ BGM OFF時の全SE消音連動化:** `button.mp3` が再生される対象を [`TitleView.swift`](BangBangBeam/Views/Title/TitleView.swift) の4ボタン（タイトル画面「`START`」、モード選択画面「`KUMITE`」「`RANKING`」「`SETTING`」）のみに限定（必殺技カットイン演出時の `cutin.mp3` は維持）。あわせて [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift) の共通SE再生基盤 `playSE(_:)` および `isBGMEnabled` 更新処理にて、BGM設定が OFF の時は今後追加されるものも含めすべての効果音（SE）が無音（再生中SEも即時停止）になるよう対応。

- **2026-11-06 21:33 (`v1.0.19`)**
  - **SE（効果音）アセット組み込み ＆ 各種ボタン押下時・必殺カットイン演出時の再生実装:** `素材/SE` の `button.mp3` および `cutin.mp3` を `BangBangBeam/Resources/SE/` へ組み込み、[`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift) に低遅延プリロード済み再生プール（`playButtonSE()` / `playCutinSE()`）を実装。全画面の各種ボタン押下時（タイトル・バトルコマンド・リザルト・設定・アイコン選択・ランキング・練習画面・広告確認枠）に `button.mp3` が、必殺技カットイン演出（[`UltimateCutinOverlayView.swift`](BangBangBeam/Views/Battle/UltimateCutinOverlayView.swift)）開始時に `cutin.mp3` が再生されるよう対応。

- **2026-11-06 21:21 (`v1.0.18`)**
  - **戦闘結果画面（勝敗共通）にBGMオンオフ（スピーカーアイコン）ボタンを実装:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の `kumiteResultOverlay` 右上に、勝利（`YOU WIN`）・敗退（`YOU LOSE...`）にかかわらず表示されるスピーカーアイコン切替ボタン（`speaker.wave.2.fill` / `speaker.slash.fill`）を追加。`SoundManager.shared.isBGMEnabled` と双方向連動し、その場でBGMの即時ミュート／再開および設定保存（`UserDefaults`）が可能。

- **2026-11-06 21:11 (`v1.0.17`)**
  - **戦闘画面HUDの不要テキスト整理:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) にて、敵キャラクター名の下に表示していた敵情報（肩書き・特性ラベル）を削除し、さらに自分（Reo）の体力バー下に表示していた `予約:⚡️チャージ` 等のテキスト表示も削除してシンプル化。

- **2026-11-06 21:07 (`v1.0.16`)**
  - **敵AIの初手確定チャージ化:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) の `selectCpuAction()` 先頭に `turnCount == 1` 判定を追加し、全敵キャラクターが初手（1ターン目）では必ず「チャージ」を選択するよう変更。

- **2026-11-06 20:57 (`v1.0.15`)**
  - **勝利リザルト画面（`YOU WIN`）に次戦テンポ変更ボタン（標準 / 速め）を実装:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の `YOU WIN` 枠内にテンポ選択パネル（`標準` / `速め`）を追加。選択すると `engine.tempoPreset`（および設定画面の選択状態・`UserDefaults`）が即時更新され、`NEXT BATTLE ▶` で始まる次の戦闘から新しいリズム速度が反映される仕様に対応。

- **2026-11-06 20:17 (`v1.0.14`)**
  - **バトル画面左上の `◀ TITLE` ボタン削除（バトル中離脱不可化）:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の `headerBar` から左上の `◀ TITLE` ボタンを削除し、バトル決着後のリザルト画面からのみタイトルへ戻れる仕様に変更。

- **2026-11-06 20:11 (`v1.0.13`)**
  - **モード選択メニューの `KUMITE` カード右上へ「〇連勝中」バッジ追加:** [`TitleView.swift`](BangBangBeam/Views/Title/TitleView.swift) にて、連勝継続状態（勝利後リザルトから Title に戻っている状態）のとき、`KUMITE` カード右上に `〇連勝中` バッジを表示するよう対応。
  - **勝敗リザルト画面のイラスト配置調整（「YOU」の左下あたりへ配置＆要素被り回避）:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の `YOU WIN` / `YOU LOSE...` リザルト枠内にて、`YOU` の左下あたりに `reo-huppy.png` / `lose.png` を配置し、連勝数・記録テキストやボタン類を右側および下側へずらして他要素と一切被らないレイアウトに調整。

- **2026-11-06 20:00 (`v1.0.12`)**
  - **次戦移行時のBGM継続再生化:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) の `advanceToNextKumiteStage()` で `playBattleBGM(forceNewRandom: false)` を呼ぶよう変更し、バトル後に次の試合へ進む際に BGM がリセット・曲変更されずシームレスに継続再生されるように修正。
  - **勝利後リザルトからの Title 帰還時における連勝状況＆復活回数の維持・再開機能:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) に中断セーブ処理（`saveKumiteSession` / `startOrResumeKumite`、`UserDefaults` 永続化）を実装し、勝利後リザルト画面から Title へ戻った場合は次回 `KUMITE` 開始時に連勝記録と動画広告による復活残り回数がそのまま引き継がれるように対応（勝利リザルト画面にもその旨の案内文を記載）。
  - **勝利・敗退リザルト画面の表記刷新 ＆ イラスト配置:** [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の勝利表記を `YOU WIN`（勝利理由と次戦説明文を削除し、`〇連勝` のシンプル表記へ変更）、敗退表記を `YOU LOSE...`（敗因理由を削除）に刷新。さらに `reo-huppy.png`（`result_reo_happy`）と `lose.png`（`result_reo_lose`）を組み込み、それぞれリザルト枠の下・左寄りに表示。

- **2026-11-06 19:09 (`v1.0.11`)**
  - **アイコン設定画面のヘッダー＆メッセージ枠固定化 ＆ `reo-icon3` 50連勝解放化:** [`IconSettingView.swift`](BangBangBeam/Views/Settings/IconSettingView.swift) の現在のアイコン表示枠とその下のメッセージ枠（未解放ガイド等）を `ScrollView` 外の上部へ固定表示に変更。[`PlayerIconManager.swift`](BangBangBeam/Services/PlayerIconManager.swift) の初期解放を `reo` の `icon1・2` のみに変更し、`icon3` は KUMITE 50連勝達成で解放されるよう変更（旧保存データの移行処理込み）。
  - **ランキング画面の自分の情報枠固定化:** [`RankingInfoSheetView.swift`](BangBangBeam/Views/Title/RankingInfoSheetView.swift) の「YOUR RANKING（自分の順位・自己ベスト・アイコン）」枠を上部固定とし、1〜100位リストのみがスクロールするように変更。
  - **モード選択メニューから `PRACTICE` を削除し、設定画面最下部へ「練習モードで1戦」ボタンを新設:** [`TitleView.swift`](BangBangBeam/Views/Title/TitleView.swift) から `PRACTICE` ボタンを削除し、[`SettingSheetView.swift`](BangBangBeam/Views/Settings/SettingSheetView.swift) の `BATTLE RULES` 最下部に「練習モードで1戦」ボタンを配置（タップで練習画面の実戦タブを起動）。
  - **KUMITE敗北時の「動画広告を見て復活（最大2回）」実装 ＆ 広告構成の一本化:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift)、[`AdManager.swift`](BangBangBeam/Services/AdManager.swift)、[`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) を更新し、1回のKUMITE挑戦につき2回までリワード動画広告（`RewardedAd`）視聴により連勝記録を維持したまま負けたバトルを再戦できる機能を実装。従来のリトライ時インタースティシャル広告を廃止し、「復活リワード動画広告 ＋ バナー広告」へ一本化。

- **2026-11-06 18:48 (`v1.0.10`)**
  - **TEMPO / BPM 設定の2択化（標準 / 速め）:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) に `TempoPreset`（`標準`: 88 BPM / `速め`: 116 BPM、`UserDefaults` 永続化）を追加し、[`SettingSheetView.swift`](BangBangBeam/Views/Settings/SettingSheetView.swift) のスライダーを「標準」「速め」の選択ボタンUIへ変更。
  - **設定画面最上部への「アイコン設定」機能実装（全84種・KUMITE周回解放・グレーシルエット表示）:**
    - 全21キャラクター分のアイコン画像（通常83個 ＋ 100連勝記念 `reo-icon100` ＝ 計84個）および未解放用のグレーシルエット画像84個を [`Assets.xcassets/Icons`](BangBangBeam/Assets.xcassets/Icons) に組み込み。
    - [`PlayerIconManager.swift`](BangBangBeam/Services/PlayerIconManager.swift) と [`IconSettingView.swift`](BangBangBeam/Views/Settings/IconSettingView.swift) を新規作成し、設定画面の最上部に配置。
    - 初期状態は `reo` の `icon1〜3` のみ選択可能。既存11キャラは KUMITE 1〜4周目撃破で `icon1〜4` 解放、2周目から出現する追加9キャラは 2〜5周目撃破で `icon1〜4` 解放、KUMITE 100連勝達成で `reo-icon100` 解放。未解放アイコンは選択不可のグレーシルエットで表示。
  - **ランキング画面への選択アイコン反映 ＆ 表示確認用モックデータ登録:** [`GameCenterManager.swift`](BangBangBeam/Services/GameCenterManager.swift) と [`RankingInfoSheetView.swift`](BangBangBeam/Views/Title/RankingInfoSheetView.swift) を更新し、「自分の順位」カードおよび「1〜100位」リストの各行にアイコンを表示（本番 Game Center でも `context` 値でアイコンIDを同期対応）。オーナー依頼に基づき確認用モックデータ（`useMockRankingForPreview = true`）を仮登録。

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
