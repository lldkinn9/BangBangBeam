# PROJECT_STATE.md - BangBangBeam 開発状況管理

最終更新日時: 2026-11-09 22:16 (JST / Asia/Tokyo)
現在バージョン: `v1.0.35`（3拍の手拍子にネオングリーン＆シアン火花追加・勝敗英字判定の白枠追加・体力1時の `sad.png` 常時表示＆背景の赤ネオンカラー化）

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
- **1本赤タイムバー ＆ 横並び3コマンド／4チャージ金色 `ULTIMATE` 即時発動:** 3拍のリズムは中央上部の **1本の赤いタイムバー** が右から左へ滑らかに消えていく描写で表現。画面最下部のコマンドは横並び3つの **`CHARGE` / `BEAM` / `BARRIER`** とし、4回チャージが溜まると3ボタンが統合されて金色に発光する横長1つの **`ULTIMATE`** ボタンへ変化。タップした瞬間にリズム待機なしで **目元カットイン演出 (`char_<id>_cutin`) → 必殺アニメーション動画 (`ult_<id>.mp4`・音声付き)** が即時発動し、バリア・残りHPを貫通して一撃決着。
- **ビジュアル＆BGM・SE (`SoundManager`):**
  - 全21キャラの背景透過立ち絵（通常・喜び・苦痛）＆カットイン画像、手イラスト4種（手拍子・チャージ・バリア・ビーム）、音声付き必殺動画21本を組み込み済み。
  - 非バトル画面で `Neon Overdrive`、バトル画面で `Seamless Looping Cyberpunk BGM` / `Cyber Velocity` をランダム選出しループ再生（設定画面およびリザルト画面でサウンド ON/OFF 切替、設定画面で BGM / SE 個別音量調整可能）。

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
- [ ] Mac側で `git pull origin main` を実行し、シミュレータ／実機で `v1.0.35`（3拍の手拍子にネオングリーン＆シアン火花追加・勝敗英字判定の白枠追加・体力1時の `sad.png` 常時表示＆背景の赤ネオンカラー化）の動作確認
- [ ] **【本番提出前必須】** ランキング画面の表示確認完了後、`GameCenterManager.useMockRankingForPreview` を `false` に切り替えて本番 Game Center 通信のみに戻す
- [ ] Xcode から `GoogleMobileAds` Swift Package（`https://github.com/googleads/swift-package-manager-google-mobile-ads.git`）を追加し、テスト用バナー広告＆リワード動画広告の描画確認（本番リリース前に AdMob 本番IDを設定）
- [ ] App Store Connect での Game Center Leaderboard（ID: `com.lldkinn9.BangBangBeam.kumite_streak`）登録および Archive 提出準備

---

## 3. 更新履歴 (JST)

- **2026-11-09 22:16 (`v1.0.35`)**
  - **3拍の手拍子へのネオングリーン＆シアン火花追加・勝敗英字判定の白枠付与・体力1時の `sad.png` 常時表示＆背景赤ネオンカラー化:**
    1. **3拍の手拍子演出にネオングリーン＆シアンの火花を追加 ([`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** `ClappingHandBeatView` にて、手拍子の衝撃リングに加えて12方向のネオングリーン（`Color.cyberEmerald`）とシアン（`Color.cyberCyan`）の火花パーティクルが周囲へ飛び散る演出を追加。
    2. **勝敗英字（`Good!!` / `Nice!!` / `Charge` / `Bad`）に白枠を付与 ([`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** `reoLeftStatusCalloutView` にて、カラー英字の背面に8方向オフセットによるシャープな白枠（白縁取り）を追加し視認性を向上。
    3. **体力が残り1になった際の `sad.png` 表示＆背景の赤ネオンカラー化（敵・自分ともに対象） ([`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) / [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** 敵（`cpuHP == 1`）または自分（`playerHP == 1`）の体力が残り1になると、該当する側のキャラクター位置が常時 `sad.png`（`.sad` 立ち絵）になり、該当する側の背景パネル・背面ライト・枠線が赤いネオンカラー（`dangerNeonRed`）で発光表示されるよう実装。

- **2026-11-09 21:19 (`v1.0.34`)**
  - **VS画面SEの `cutin.mp3` 統一・バトル時3拍の手拍子演出＆ `super clap.mp3` 再生・Reo顔左スペースの勝敗英字判定実装:**
    1. **VS画面のSEに `cutin.mp3` を使用 ([`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift)):** `playVsAppearSE()` が `cutin.mp3`（`.cutin`）を再生するよう変更し、旧 `vs_appear.mp3` を削除。
    2. **バトル時3拍の手に実際に叩いて見える演出（大小・揺れ・衝撃波）＆ `super clap.mp3` 再生 ([`super clap.mp3`](BangBangBeam/Resources/SE/super%20clap.mp3) / [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) / [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) / [`PracticeTutorialView.swift`](BangBangBeam/Views/Practice/PracticeTutorialView.swift)):** `素材/SE/super clap.mp3` の冒頭無音をトリミング＆音圧最適化したうえでバンドルに組み込み、1拍目・2拍目の手拍子タイミングで `playSuperClapSE()` を再生。あわせて `ClappingHandBeatView` を実装し、拍ごとに手イラストが大小に弾けて揺れ、衝撃リングとスパークが広がる演出を追加。
    3. **Reoの顔の左側の空きスペースに勝敗に応じた英字判定を大きく表示 ([`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) / [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** 3拍目でお互いの手を出した際、Reoの顔の左側のスペース（`x: w * 0.355, y: h * 0.788`）に「ガードが成立 → `Good!!`（シアン）」「ビームが相手にあたる → `Nice!!`（黄色）」「チャージ成功 → `Charge`（ネオングリーン）」「相手のビーム被弾 → `Bad`（赤）」を大きく表示し、上記以外の状況では何も表示しない仕様（`PlayerClashCallout`）を実装。

- **2026-11-09 20:31 (`v1.0.33`)**
  - **Xcode ビルドエラー修正 ([`PracticeTutorialView.swift`](BangBangBeam/Views/Practice/PracticeTutorialView.swift)):** `practiceHandBand` の引数型を正しくは `ResolvedMove`（旧表記 `BattleMove` を修正）に、相手側アクセントカラー指定を `Color(red: 1.0, green: 0.16, blue: 0.88)`（未定義の `Color.cyberMagenta` を修正）に修正。

- **2026-11-09 20:24 (`v1.0.32`)**
  - **バトル画面における出した手の画面横いっぱい上下2段帯表示化・手の下の文字撤去・手表示中の3拍時間バー非表示化 ([`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) / [`PracticeTutorialView.swift`](BangBangBeam/Views/Practice/PracticeTutorialView.swift)):**
    1. **出した手の縦並び（上下2段・画面横いっぱいの帯状）表示:** 3拍目でお互いの手を表示する際、従来の左右横並びカード表示から、画面横幅いっぱい（`width: w`）のサイバー帯を上段（相手の手・マゼンタ枠帯）と下段（自分の手・シアン枠帯）に縦並びで上下表示するレイアウト（`handMoveHorizontalBand`）へ刷新。
    2. **手の下のテキスト表示の撤去:** 手の下に表示されていた `engine.calloutText`（「バン！」「チャージ！」など）および `engine.statusDetailText`（「読み合い継続！次の3拍へ」「ビーム直撃！」など）のテキスト表示を廃止。
    3. **お互いの手を表示している間の3拍時間バー非表示化:** 3拍目でお互いの手が表示されている間（`isShowingRevealedHands == true`）は、`RhythmTimeBarView`（3拍の赤い時間バー）を非表示にするよう変更。

- **2026-11-09 19:19 (`v1.0.31`)**
  - **VS画面SEのスタイリッシュ化・4チャージ電撃エフェクト廃止（黄色発光のみ化）・iPhone最上部ステータスバー非干渉レイアウト調整:**
    1. **VS画面キャラ登場SEのクリア＆スタイリッシュ化 ([`vs_appear.mp3`](BangBangBeam/Resources/SE/vs_appear.mp3)):** ノイズ成分やiPhoneスピーカーで歪む超低域を完全排除（`highpass=120Hz`・ノイズ生成器ゼロ）し、純粋な倍音シンセによるステレオピッチグライド＋クリスタルFMダブルロック音＋近未来Dm9ネオンシンセコード（`146Hz〜880Hz`）のスタイリッシュな0.95秒SEへ刷新。
    2. **4チャージ時のバッテリーゲージ電撃エフェクト廃止・黄色発光のみ化 ([`EnergyOrbView.swift`](BangBangBeam/Views/Battle/EnergyOrbView.swift)):** `ElectricChargeEffectOverlay`（稲妻・スパーク描画）を削除し、チャージが4つ溜まった際は全4セルが黄色く発光するシンプルな表現に変更。
    3. **iPhone最上部のステータスバー（時計・充電残量・電波表示）への非干渉化 ([`BangBangBeamApp.swift`](BangBangBeam/App/BangBangBeamApp.swift) / [`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift) / [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** 最上部ステータスバーの背面のみ黒背景（`ignoresSafeArea()`）で維持しつつ、各画面のメイン `GeometryReader` / コンテナは上部セーフエリア（`safeAreaInsets.top`）を尊重してステータスバーの下から描画されるよう変更（`ignoresSafeArea(edges: .bottom)` ＋ 上部余白 `4pt`）。

- **2026-11-09 18:56 (`v1.0.30`)**
  - **VS画面SEの重厚サイバーパンク化 ＆ 戦闘画面への指定背景テンプレート・3コマンドボタン素材の完全組み込み:**
    1. **VS画面キャラ登場SEの重厚化 ([`vs_appear.mp3`](BangBangBeam/Resources/SE/vs_appear.mp3)):** 高音チャイムを廃し、重低音サブベースドロップ（`125Hz → 36Hz`）＋ ダークなサイバーパンク Reese ブラス咆哮（`55Hz` A1 パワーフィフス）＋ 重量級メカニックゲートロック打撃音 ＋ 低域プラズマサージを合成した1.55秒の重厚な戦闘開始SEへ刷新。
    2. **戦闘画面用ベース背景＆ボタン素材の抽出・組み込み ([`Assets.xcassets/UI/battle_screen_bg.imageset`](BangBangBeam/Assets.xcassets/UI/battle_screen_bg.imageset) / [`battle_enemy_frame_fg.imageset`](BangBangBeam/Assets.xcassets/UI/battle_enemy_frame_fg.imageset) / [`btn_battle_charge.imageset`](BangBangBeam/Assets.xcassets/UI/btn_battle_charge.imageset) / [`btn_battle_beam.imageset`](BangBangBeam/Assets.xcassets/UI/btn_battle_beam.imageset) / [`btn_battle_barrier.imageset`](BangBangBeam/Assets.xcassets/UI/btn_battle_barrier.imageset) / [`AssetPrewarmer.swift`](BangBangBeam/Services/AssetPrewarmer.swift)):** オーナー指定の2枚目背景テンプレートをベースに、1枚目見本から `REO (YOU)` 表記および斜め3ボタン（`CHARGE` / `BEAM` / `BARRIER`）を高精度アルファマット抽出して組み込み、起動時プリウォーム対象に追加。
    3. **戦闘画面UIの1枚目見本準拠レイアウト実装 ([`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** `battle_screen_bg` 上の正規化座標に合わせて、左上フレーム内に右向きミラーの敵キャラ立ち絵（勝敗・被弾で表情変化＋フレーム下辺 `battle_enemy_frame_fg` 重ね）、右上マゼンタ枠内に敵名・3ハート・4バッテリー、中央3Dグリッド上に1本赤タイムバー＆`Ready`/`Go!!`/手イラスト激突、中下に斜め階段配置の `CHARGE / BEAM / BARRIER` ボタン（4チャージで金色発光 `ULTIMATE` に変化）、左下シアン枠内に3緑ハート・4緑バッテリー（4チャージで黄色発光＋電撃アニメーション）、右下にREO立ち絵（表情変化）を配置。

- **2026-11-09 18:34 (`v1.0.29`)**
  - **対戦直前VS画面の4点改善（機種別名前見切れ修正・キャラ登場SE導入・「START」ボタン待機化・サイバー揺れ＆放電演出追加）:**
    1. **全機種での名前見切れ修正 ([`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift)):** 9:19.5の縦長iPhoneでも左右のネーム枠が見切れないよう `canvasW = screenW`, `canvasH = screenH` の100%画面フィット座標に変更し、左上マゼンタ枠の敵名称（`enemy.codeName`）および右下シアン枠の `REO` / `(YOU)` を枠内中央に余白付きで収めるよう調整。
    2. **キャラ＆名称登場タイミングの専用SE導入 ([`vs_appear.mp3`](BangBangBeam/Resources/SE/vs_appear.mp3) / [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift)):** サイバーパンクな重低音インパクト＋斜め放電スラッシュ＋ネオンコードチャイムを合成した `vs_appear.mp3` を生成し、`SoundEffect.vsAppear`（`playVsAppearSE()`）として登録。BGM OFF時の完全無音化および設定画面のSE音量スライダーにも完全連動。
    3. **キャラ表示1秒後の「START」ボタン表示＆押下によるバトル開始 ([`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) / [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** 自動遷移を廃止し、キャラ＆名称が表示されてから1.0秒後に中央「`VS`」の直下へサイバー「`START`」ボタンを表示。タップ時に `button.mp3` を鳴らしてバトル画面（`Ready` → `Go!!` → 3拍開始）へ進むよう変更。
    4. **待機画面の画面揺れ＆サイバーチックなライブ演出 ([`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift)):** キャラ登場瞬間のインパクト・カメラシェイクに加え、待機中の常時サイバーカメラ浮遊揺れ、両キャラの呼吸フローティング、斜め境界のリアルタイム稲妻放電、中央 `VS` から飛び散る28個のネオンスパーク粒子、ホログラム走査線＆周期的グリッチスライスを30fps `TimelineView` で実装。

- **2026-11-09 18:09 (`v1.0.28`)**
  - **対戦直前のVS画面への指定背景素材組み込み ＆ 1枚目→2枚目キャラ・名称挿入アニメーション実装:**
    1. **VS画面ベース素材＆前景レイヤー組み込み ([`Assets.xcassets/UI/vs_screen_bg.imageset`](BangBangBeam/Assets.xcassets/UI/vs_screen_bg.imageset) / [`vs_screen_fg.imageset`](BangBangBeam/Assets.xcassets/UI/vs_screen_fg.imageset) / [`AssetPrewarmer.swift`](BangBangBeam/Services/AssetPrewarmer.swift)):** オーナー指定の1枚目素材を `vs_screen_bg` として組み込み、さらに2枚目見本と同様に中央「`VS`」ロゴと斜め稲妻がキャラクター境界の手前に重なる透過前景レイヤー `vs_screen_fg` を生成・プリウォーム対象に追加。
    2. **対戦相手に応じた動的キャラ・名称挿入 ＆ 1枚目→2枚目切替アニメーション ([`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift)):** 571×1024正規化キャンバス上で、まず1枚目（文字・キャラなしの背景素材）を表示した状態から、約0.42秒後に右上へ対戦相手の立ち絵（`enemy.standingAsset(for: .normal)`）・左上マゼンタ枠内へ対戦相手の名称（`enemy.codeName`）・左下へREO立ち絵・右下シアン枠内へ `REO (YOU)` が閃光とともにスライド挿入される2段階アニメーションを実装。

- **2026-11-09 17:22 (`v1.0.27`)**
  - **ゲーム画面UIデザインの全面刷新 ＆ 事前VS画面＋「Ready」「Go!!」導入 ＆ 4チャージ電撃バッテリーアニメーション実装:**
    1. **新バトル画面デザイン ([`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift)):** デザイン案に準拠し、左上に敵大型立ち絵＋右上にマゼンタ発光HUD（敵名・3ハート・4バッテリー）、中央に3Dパースペクティブグリッド＋1本赤タイムバー＋手激突演出、REO HUD直上に斜めカットの3コマンドボタン（緑 `CHARGE` / 紫マゼンタ `BEAM` / シアン `BARRIER`、4チャージ時は金色発光 `ULTIMATE`）、左下にシアン発光 `REO (YOU)` HUD＋右下にREO大型立ち絵を配置。出す手の勝敗・被弾による両キャラの表情変化（通常・喜び・ダメージ）も完全踏襲。
    2. **チャージゲージ4セル黄色発光＆電気エフェクトアニメーション ([`EnergyOrbView.swift`](BangBangBeam/Views/Battle/EnergyOrbView.swift)):** チャージゲージを縦型4連バッテリーデザインに刷新し、4つ溜まった時点で全セルが黄色く発光するとともに、周囲にバチバチと稲妻・スパークが走る電気エフェクトアニメーション（`ElectricChargeEffectOverlay`）を実装。
    3. **事前VS画面 → ゲーム画面切替 →「Ready」「Go!!」→ 3拍開始フロー ([`PreBattleVsOverlayView.swift`](BangBangBeam/Views/Battle/PreBattleVsOverlayView.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift)):** 戦闘開始時にまず斜め稲妻分割の「事前画面（VS画面）」（対戦相手に応じて敵名・敵立ち絵が動的に変化）を表示し、その後ゲーム画面へ切り替わって中央に「`Ready`」→「`Go!!`」を表示してから3拍のリズムループが開始されるよう実装。

- **2026-11-07 11:02 (`v1.0.26`)**
  - **戦闘画面UIの大幅刷新（1本の赤いタイムバー ＆ 横並び3ボタン `CHARGE / BEAM / BARRIER` ＆ 4チャージ金色発光 `ULTIMATE` 即時発動）:**
    1. [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift): 従来の独立3分割（Beat 1, 2, 3）インジケータを廃止し、1本の赤いタイムバーが右から左へ60fpsで滑らかに消えていく `RhythmTimeBarView` を実装。
    2. [`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) / [`GameAction.swift`](BangBangBeam/Models/GameAction.swift): 最下部のコマンド表示を2×2の4ボタンから、横並び3つの `CHARGE` / `BEAM` / `BARRIER`（`BattleCommandDeckView`）へ刷新。
    3. チャージが4回溜まると3つのボタンが金色に発光する横長1つの `ULTIMATE` ボタン（`UltimateReadyButton`）へ変化し、押した瞬間にリズム待機なしで即座にカットイン演出→必殺技アニメーション（音声付き `.mp4`）へ突入する仕様（`triggerPlayerUltimateImmediately()`）を実装。[`PracticeTutorialView.swift`](BangBangBeam/Views/Practice/PracticeTutorialView.swift) の練習画面・説明文も新UIへ統一。

- **2026-11-07 10:42 (`v1.0.25`)**
  - **全21キャラクターの刷新版必殺アニメーション `.mp4` 一括反映 ＆ 動画音声再生の安定化:** `素材/Characters/<各キャラ>/<キャラ>-anime.mp4` に差し替えられた最新21本（2026-11-07 更新分）を、元の AAC ステレオ音声トラック（48kHz / 2ch）を無劣化コピー維持したまま iOS `AVPlayer` 最適化済みの H.264 (`avc1`, `yuv420p`, `+faststart`) として [`BangBangBeam/Resources/Videos/`](BangBangBeam/Resources/Videos) の `ult_<id>.mp4` へ一括反映。あわせて [`UltimateCutinOverlayView.swift`](BangBangBeam/Views/Battle/UltimateCutinOverlayView.swift) と [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift) にて、プリロード段階からの音声パイプライン準備（冒頭音欠け防止）・`AVAudioSession` アクティブ維持・SE音量スライダーおよびサウンドON/OFF設定連動・再生中のBGM一時ダッキングを整備し、ワークスペース全体へ同期。

- **2026-11-06 23:14 (`v1.0.24`)**
  - **敗退後のタイトル帰還時における連勝保持（復活回数が残っている場合限定）＆ 再開確認ポップアップ実装:** [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift) にて、KUMITE 敗退後（1連勝以上）でも「動画広告を見て復活」の残り回数が 1回以上残っている場合に限り、タイトル画面へ戻っても連勝数・復活残り回数・敗退保留状態を `UserDefaults` に保持する仕様を実装（復活回数が残っていない場合や0連勝時はリセット）。また、敗退保留状態から次回「KUMITE」を押した際に [`BangBangBeamApp.swift`](BangBangBeam/App/BangBangBeamApp.swift) の `PendingRevivePromptOverlayView` 確認ポップアップを表示し、「動画広告を見て復活（連勝継続）」か「最初から挑戦（0連勝）」を選択できるように対応。[`BattleView.swift`](BangBangBeam/Views/Battle/BattleView.swift) の敗退画面にも復活残りあり時の保持案内文を追加。

- **2026-11-06 22:34 (`v1.0.23`)**
  - **全21キャラクターの更新版必殺アニメーション反映 ＆ アニメーション音声の再生対応:** `素材/Characters/<各キャラ>/<キャラ>-anime.mp4`（全21本）の最新動画を iOS `AVPlayer` 互換の H.264 (`avc1`) ＋ AAC (`48kHz` ステレオ) ＋ `faststart` 形式に変換して `BangBangBeam/Resources/Videos/ult_<id>.mp4` を一括更新。あわせて [`UltimateCutinOverlayView.swift`](BangBangBeam/Views/Battle/UltimateCutinOverlayView.swift) の無音固定を解除し、動画再生フェーズではアニメーションの音声が再生されるよう変更（SE音量スライダーおよびサウンドON/OFF設定に連動し、再生中はBGMを一時ダッキングして終了後に自動復帰）。

- **2026-11-06 22:26 (`v1.0.22`)**
  - **KUMITE 1戦目の動作安定化（BGM・画像・触覚の事前準備 ＆ 画面遷移・リズムタイマー改善）:**
    1. [`SoundManager.swift`](BangBangBeam/Services/SoundManager.swift): 全BGMトラック（約3.2〜3.8MB）の `AVAudioPlayer` を起動時に事前準備（`preloadBGMTracks`）し、1戦目開始時のディスク読み込み＆MP3デコーダ初期化ラグを解消。
    2. [`AssetPrewarmer.swift`](BangBangBeam/Services/AssetPrewarmer.swift)（新規）: 手イラスト4種・Reo立ち絵・現在／次戦の敵立ち絵PNGを `byPreparingForDisplay()` でバックグラウンド事前デコードし、1戦目1ターン目の初回描画カクつきを解消。
    3. [`CyberTheme.swift`](BangBangBeam/Views/Components/CyberTheme.swift): `HapticManager` のジェネレータを共有再利用＋事前ウォームアップ化し、Taptic Engine 初回起動時のメインスレッド詰まりを防止。
    4. [`BangBangBeamApp.swift`](BangBangBeam/App/BangBangBeamApp.swift) / [`TitleView.swift`](BangBangBeam/Views/Title/TitleView.swift) / [`GameEngine.swift`](BangBangBeam/ViewModels/GameEngine.swift): バナー枠の `safeAreaInset` をタイトル画面のみに限定して遷移中の再レイアウトを無くし、リズムタイマーを `RunLoop.common` 登録＋画面フェード完了後の開始に変更。

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
