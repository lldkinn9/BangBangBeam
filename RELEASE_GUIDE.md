# Bang Bang Beam — App Store Connect & Google AdMob リリース手順書

最終更新: 2026-11-10 (`v1.0.47`)

本ドキュメントには、**Google AdMob 本番収益化** および **Apple App Store Connect 審査提出** に必要なすべての設定手順と、そのままコピー＆ペーストして使える入力テンプレートをまとめています。

---

## 0. プロジェクト側で自動設定済みの項目（`v1.0.47`）

以下の必須ファイル・設定はすでにリポジトリへ組み込み済みです。

| 項目 | 組み込み先ファイル | 内容 |
| :--- | :--- | :--- |
| **Apple Privacy Manifest** | [`BangBangBeam/PrivacyInfo.xcprivacy`](BangBangBeam/PrivacyInfo.xcprivacy) | `UserDefaults` (`CA92.1`) 宣言および AdMob / Game Center のデータ収集・トラッキング宣言（`ITMS-91053` 対応済み） |
| **Game Center Entitlements** | [`Config/BangBangBeam.entitlements`](Config/BangBangBeam.entitlements) | `com.apple.developer.game-center = true`（Archive 時の Game Center 署名有効化） |
| **本番 Info.plist & SKAdNetwork** | [`Config/Info.plist`](Config/Info.plist) | `GADApplicationIdentifier`・`SKAdNetworkItems`（Google公式49ネットワーク）・暗号化輸出コンプライアンス免除（`ITSAppUsesNonExemptEncryption = false`）・`UIRequiredDeviceCapabilities`（`arm64`, `gamekit`） |
| **ATT 多言語許可メッセージ** | [`BangBangBeam/InfoPlist.xcstrings`](BangBangBeam/InfoPlist.xcstrings) | `NSUserTrackingUsageDescription` の日本語・英語ローカライズ |
| **ダミー表示の完全排除** | [`GameCenterManager.swift`](BangBangBeam/Services/GameCenterManager.swift) / [`AdManager.swift`](BangBangBeam/Services/AdManager.swift) | ランキングのモックデータおよび広告未リンク時のプレビュー用ダミー枠を完全削除済み |
| **App Icon 透過なし検証** | [`AppIcon.png`](BangBangBeam/Assets.xcassets/AppIcon.appiconset/AppIcon.png) | `1024×1024` / 24-bit RGB（アルファチャンネルなし）検証済み |

---

## 1. Google AdMob の準備と本番IDの反映

### Step 1-1: AdMob 管理画面でアプリと2つの広告ユニットを作成
1. [Google AdMob](https://apps.admob.com/) にサインインし、**「アプリ」＞「アプリを追加」** をクリックします。
   - プラットフォーム: **iOS**
   - アプリはサポートされているアプリストアに掲載されていますか？: **いいえ**（App Store 公開後に紐付けます）
   - アプリ名: `Bang Bang Beam`
   - 作成完了時に表示される **アプリ ID**（`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`）を控えます。
2. **「広告ユニット」＞「広告ユニットを追加」** から以下の **2種類** を作成します。
   - **① バナー（Banner）**
     - 広告ユニット名: `Main Bottom Banner`
     - 作成された **バナー広告ユニット ID**（`ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`）を控えます。
   - **② リワード（Rewarded）**
     - 広告ユニット名: `Kumite Revive Rewarded`
     - 報酬の設定: 報酬の量 `1` / 報酬のアイテム `Revive`
     - 作成された **リワード広告ユニット ID**（`ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW`）を控えます。

### Step 1-2: Xcode に `GoogleMobileAds` Swift Package を追加（未追加の場合）
1. Mac で `~/Documents/BangBangBeam/BangBangBeam.xcodeproj` を開きます。
2. メニューバー **File ＞ Add Package Dependencies...** を選択します。
3. 右上の検索欄に以下の URL を入力します：
   ```text
   https://github.com/googleads/swift-package-manager-google-mobile-ads.git
   ```
4. **Add Package** を押し、`GoogleMobileAds` にチェックを入れてターゲット **`BangBangBeam`** に追加します。

### Step 1-3: Xcode の Build Settings に本番 AdMob ID を入力
> **セキュリティ保護:** ソースコード（`.swift`）を書き換える必要はありません。`DEBUG` ビルド（開発中の実機実行）では自動的に Google 公式テスト広告が使われ、`Release` ビルド（App Store 提出用 Archive）でのみ以下の本番IDが使用されます。

1. Xcode 左ペイン最上部のプロジェクト **`BangBangBeam`** を選択 ＞ **TARGETS `BangBangBeam`** ＞ **Build Settings** タブを開きます。
2. 右上の検索バーに `ADMOB_` と入力すると、最下部の **User-Defined** セクションに以下の3項目が表示されます。それぞれを Step 1-1 で控えた **ご自身の本番ID** に書き換えます：
   - **`ADMOB_APP_ID`**: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`（※記号はチルダ `~`）
   - **`ADMOB_BANNER_UNIT_ID`**: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`（※記号はスラッシュ `/`）
   - **`ADMOB_REWARDED_UNIT_ID`**: `ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW`（※記号はスラッシュ `/`）

---

## 2. App Store Connect の設定手順

### Step 2-1: 新規アプリ登録
1. [App Store Connect](https://appstoreconnect.apple.com/) ＞ **「アプリ」＞「＋（新規アプリ）」** を開きます。
2. 以下のように入力して作成します：
   - **プラットフォーム:** iOS
   - **名前:** `Bang Bang Beam`（すでに同名が使われている場合は `Bang Bang Beam - Cyber Battle` 等）
   - **プライマリ言語:** 日本語
   - **バンドル ID:** `com.lldkinn9.BangBangBeam`
   - **SKU:** `bangbangbeam-ios-001`
   - **ユーザーアクセス:** フルアクセス

### Step 2-2: Game Center（世界ランキング Leaderboard）の作成【重要】
1. App Store Connect の対象アプリ画面 ＞ 上部または左メニューの **「Game Center」** を開きます。
2. **「Leaderboard」** セクションの **「＋」**＞ **「クラシック Leaderboard（単一）」** を選択します。
3. 以下の通り入力します（コード内の [`GameCenterManager.leaderboardID`](BangBangBeam/Services/GameCenterManager.swift#L67-L73) と完全一致させます）：
   - **Leaderboard 参照名:** `KUMITE Win Streak`
   - **Leaderboard ID:** `com.lldkinn9.BangBangBeam.kumite_streak`
   - **スコアフォーマットタイプ:** `整数`（Integer）
   - **スコアの送信タイプ:** `ベストスコア`（Best Score）
   - **並べ替え順:** `高い順`（High to Low）
   - **スコアの範囲:** `0` から `999999`
4. **「Leaderboard のローカライズ」** で **日本語** と **英語 (U.S.)** の2言語を追加します：
   - **日本語:**
     - 表示名: `KUMITE 最大連勝記録`
     - スコアのフォーマットサフィックス（単数・複数とも）: `連勝`
   - **英語 (U.S.):**
     - 表示名: `KUMITE Win Streak`
     - スコアのフォーマットサフィックス（単数）: `Win`
     - スコアのフォーマットサフィックス（複数）: `Wins`
5. ⚠️ **【提出前の必須チェック】**
   左メニュー **「iOS App ＞ 1.0 提出準備中」** 画面を下へスクロールし、**「Game Center」** セクションにチェックを入れ、**「Leaderboard」の「＋」から作成した `KUMITE Win Streak` を必ず追加**してください（これを忘れると本番でランキングが有効化されません）。

---

## 3. App Store Connect「App のプライバシー」回答内容

左メニュー **「App のプライバシー」** で以下の通り回答します（[`PrivacyInfo.xcprivacy`](BangBangBeam/PrivacyInfo.xcprivacy) と完全一致しています）：

1. **プライバシーポリシー URL:** ご自身の Web サイト／Notion／GitHub Pages 等のプライバシーポリシー URL を登録
2. **データ収集の有無:** **「はい、この App からデータを収集します」**
3. **収集するデータの種類（4項目にチェック）:**
   - **位置情報 ＞ おおよその位置情報**
     - 用途: **サードパーティ広告** / ユーザーに関連付け: **いいえ** / トラッキング: **いいえ**
   - **ユーザーコンテンツ ＞ ゲームプレイのコンテンツ**（Game Center 連勝記録）
     - 用途: **App の機能** / ユーザーに関連付け: **はい** / トラッキング: **いいえ**
   - **ID ＞ デバイス ID**（AdMob 広告識別子 IDFA）
     - 用途: **サードパーティ広告** / ユーザーに関連付け: **いいえ** / トラッキング: **はい**
   - **使用状況データ ＞ 製品とのやり取り ＆ 広告データ**
     - 用途: **サードパーティ広告・アナリティクス** / ユーザーに関連付け: **いいえ** / トラッキング: **はい**

---

## 4. App Store 掲載情報テンプレート（日本語 ＆ 英語）

App Store Connect の **「1.0 提出準備中」** および **「App 情報」** でそのままコピー＆ペーストしてご利用いただけます（右上の言語切替から「日本語」と「英語 (U.S.)」の両方に設定可能です）。

### 🇯🇵 日本語（プライマリ言語）
- **名前:** `Bang Bang Beam`
- **サブタイトル（30文字以内）:** `3拍子のリズムで撃ち抜くサイバー読み合いバトル！`
- **カテゴリ:** 第1カテゴリ：`ゲーム`（サブカテゴリ：`アクション`、`ミュージック`）
- **プロモーション用テキスト（170文字以内）:**
  ```text
  「バン！バン！アクション！」の3拍子リズムでチャージ・ビーム・バリアを繰り出すサイバーパンク読み合いバトル！4チャージでド派手な一撃必殺「ULTIMATE」が炸裂！連続撃破モード「KUMITE」で世界中のライバルと最大連勝記録を競い合おう！
  ```
- **概要（説明文）:**
  ```text
  「バン！バン！アクション！」
  3拍子のリズムに合わせて出す手を決める、新感覚サイバーパンク・リズム読み合いバトル『Bang Bang Beam』！

  ■ シンプル＆奥深い3拍子バトルルール
  中央の時間バーが消えきる前に、下の3つのコマンドから1つを選択！
  ・CHARGE（チャージ）：バッテリーを1つ溜める（チャージ中はビームに無防備！）
  ・BEAM（ビーム）：バッテリーを1消費して攻撃！相手のハートとバッテリーを1削る！
  ・BARRIER（バリア）：消費0で相手の通常ビームを完全防御！

  ■ 4チャージで一撃必殺「ULTIMATE」発動！
  バッテリーを4つ満タンまで溜めると、コマンドが黄金に輝く「ULTIMATE」ボタンに合体変化！
  タップした瞬間にド派手なカットイン＆必殺アニメーションが発動し、相手のバリアや残り体力を貫通して一撃で勝利！

  ■ 勝ち抜きサバイバル「KUMITE」＆世界ランキング
  個性豊かな20人のサイバーライバルたちと連戦するメインモード「KUMITE」！
  勝利するたびに獲得できるポイントで、ハート・電池・防弾チョッキ・回復薬・エナジードリンク・救急キットなどのアイテムを交換可能！
  最大連勝記録で競う「WORLD RANKING（Game Center 対応）」や、条件達成で解放される全84種類のプレイヤーアイコン収集、リズム速度（標準／速め）の切り替えにも対応しています。
  ```
- **キーワード（カンマ区切り・100文字以内）:**
  ```text
  リズムゲーム,サイバーパンク,読み合い,じゃんけん,手遊び,反射神経,アクション,対戦,ランキング,無料ゲーム,CCレモン
  ```

### 🇺🇸 英語 (U.S.)（セカンダリ言語）
- **Name:** `Bang Bang Beam`
- **Subtitle (Max 30 chars):** `3-Beat Cyber Rhythm Battle!`
- **Promotional Text (Max 170 chars):**
  ```text
  Fight to the 3-beat rhythm: Bang! Bang! Action! Outsmart rivals with Charge, Beam, and Barrier, unleash 4-Charge ULTIMATE finishers, and climb the Global Leaderboard!
  ```
- **Description:**
  ```text
  "Bang! Bang! Action!"
  Welcome to Bang Bang Beam — a high-voltage cyberpunk rhythm mind-game fought on a 3-beat clap!

  ■ Fast & Tactical 3-Beat Combat
  Before the center Time Bar runs out, choose one of three commands on the beat:
  - CHARGE: Store +1 battery cell (leaves you open to enemy Beams!).
  - BEAM: Spend 1 battery to strike! Deals -1 Heart AND -1 Battery to an open rival!
  - BARRIER: Block normal enemy Beams with 0 battery cost!

  ■ 4 Charges = One-Hit KO "ULTIMATE"!
  Fill all 4 battery cells to merge your controls into a golden ULTIMATE button!
  Tap it to trigger an instant anime cut-in and finisher animation that pierces enemy Barriers and remaining Hearts for an instant victory!

  ■ "KUMITE" Survival Mode & World Ranking
  Face off against 20 unique cyber rivals in consecutive KUMITE survival battles!
  Earn 1 Point per victory to exchange for tactical items (Heart, Battery, Bulletproof Vest, Healing Potion, Energy Drink, and Medkits).
  Compete globally on the Game Center World Leaderboard, unlock 84 player icons, and switch between Standard and Fast rhythm tempos!
  ```
- **Keywords (Max 100 chars):**
  ```text
  rhythm,cyberpunk,battle,reflex,arcade,action,strategy,survival,leaderboard,quick,anime,clash
  ```

### App Review 審査情報（メモ欄用テンプレート）
- **サインイン情報:** 「サインインは不要です」（チェックを外す）
- **メモ（Notes）:**
  ```text
  Thank you for reviewing Bang Bang Beam!
  - Language Selection: On first launch (and anytime in SETTING), you can switch all UI text between Japanese and English.
  - Tutorial: First launch opens PRACTICE mode where you can learn the 3-beat rules in 6 steps and play 1 practice match.
  - KUMITE & World Ranking: Main survival mode submits the best win streak to Apple Game Center Leaderboard (ID: com.lldkinn9.BangBangBeam.kumite_streak).
  - Ads: Uses Google AdMob Banner Ads on non-battle screens and optional Rewarded Video Ads to revive after losing a KUMITE match (up to the run's reset limit). App Tracking Transparency (ATT) permission is requested before personalized ad serving.
  ```

---

## 5. Xcode からの Archive ＆ App Store Connect アップロード手順

1. Mac のターミナルで最新コードを取得します：
   ```bash
   cd ~/Documents/BangBangBeam
   git pull origin main
   ```
2. Xcode で `BangBangBeam.xcodeproj` を開き、上部中央のデバイス選択を **「Any iOS Device (arm64)」** に切り替えます。
3. メニューバー **Product ＞ Archive** をクリックします。
4. Archive 完了後、自動的に **Organizer** ウィンドウが開きます。
5. 作成されたアーカイブを選択し、右側の **「Distribute App」** ＞ **「App Store Connect」** ＞ **「Upload」** を選択してアップロードを完了します。
6. 数分〜15分ほどで App Store Connect の「1.0 提出準備中 ＞ ビルド」に選択可能として表示されます。ビルドを選択し、**「審査へ提出」** を押せば完了です！
