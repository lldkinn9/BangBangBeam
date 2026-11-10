import SwiftUI

/// PRACTICEモード（ルール学習 ➔ 標準速度での1戦練習バトル ➔ KUMITE・ランキング・テンポ変更ガイド）
/// - 初回アプリ起動時および設定画面から起動されるチュートリアル＆練習モード
/// - 実際の最新バトル画面UI上で吹き出し解説（全6ステップ）を学んだ後、「練習」ボタンで「標準」速度の1戦練習バトルを行い、終了後にKUMITE機能・ランキング制度・リズム高速化機能を紹介する
struct PracticeTutorialView: View {
    @Bindable var engine: GameEngine
    @Bindable private var lang = LanguageManager.shared

    private enum PracticePhase: Equatable {
        case ruleGuide
        case practiceBattle
    }

    @State private var phase: PracticePhase = .ruleGuide
    @State private var lessonStep: Int = 0
    @State private var showDemoUltimate: Bool = false

    private let enemyNeonMagenta = Color(red: 0.96, green: 0.26, blue: 0.88)
    private let dangerNeonRed = Color(red: 1.0, green: 0.08, blue: 0.18)

    /// 吹き出しのしっぽ（ポインター）の向きと水平位置
    private enum TailDirection {
        case up(xRatio: CGFloat)
        case down(xRatio: CGFloat)
    }

    /// 各ステップで実際のバトル画面に反映するシミュレーション状態＋吹き出し説明データ
    private struct PracticeLessonScenario {
        let badge: String
        let speaker: String
        let title: String
        let message: String
        let subTip: String
        let accentColor: Color
        let bubbleCenterYRatio: CGFloat
        let tailDirection: TailDirection

        // バトル画面の再現パラメータ
        let cpuHP: Int
        let cpuCharge: Int
        let cpuExpression: CharacterExpression
        let playerHP: Int
        let playerCharge: Int
        let playerExpression: CharacterExpression
        let selectedAction: GameAction
        let showTimeBar: Bool
        let timeBarFraction: CGFloat
        let showClappingHands: Bool
        let revealedCpuMove: ResolvedMove?
        let revealedPlayerMove: ResolvedMove?
        let callout: PlayerClashCallout?
    }

    private var scenarios: [PracticeLessonScenario] {
        [
            // STEP 1: 3拍のリズム＆時間バー＆コマンド選択
            PracticeLessonScenario(
                badge: "STEP 1 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("3拍のリズムで行動を選ぼう！", "Pick Your Move on the 3-Beat Rhythm!"),
                message: L10n(
                    "バン！バン！アクション！の3拍子のリズムで戦うサイバーバトル！\n中央の【時間バー】が右から左へ消えきる前に下の3つのボタンから1つを選択し、出す手を決めよう。",
                    "A cyber battle fought on a 3-beat rhythm: Bang! Bang! Action!\nBefore the center [Time Bar] runs out from right to left, tap one of the 3 buttons below to choose your move."
                ),
                subTip: L10n(
                    "💡 1・2拍目の手拍子の間にボタンをタップ！3拍目で両者の手が同時に公開されます。",
                    "💡 Tap a button during the 1st & 2nd claps! Both moves are revealed together on Beat 3."
                ),
                accentColor: .cyberCyan,
                bubbleCenterYRatio: 0.190,
                tailDirection: .down(xRatio: 0.50),
                cpuHP: 3,
                cpuCharge: 0,
                cpuExpression: .normal,
                playerHP: 3,
                playerCharge: 0,
                playerExpression: .normal,
                selectedAction: .charge,
                showTimeBar: true,
                timeBarFraction: 0.62,
                showClappingHands: true,
                revealedCpuMove: nil,
                revealedPlayerMove: nil,
                callout: nil
            ),
            // STEP 2: CHARGE（気力溜め）
            PracticeLessonScenario(
                badge: "STEP 2 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("まずは「CHARGE」で気力を溜めよう！", "Start with \"CHARGE\" to Build Energy!"),
                message: L10n(
                    "バトル開始時はバッテリー（気力）が 0 です。\n緑の【CHARGE】を選んで3拍目を迎えると、左下のバッテリーが 1つ溜まり「Charge」と表示されます！",
                    "You start every battle with 0 battery (charge).\nPick green [CHARGE] and reach Beat 3 to fill 1 battery cell at the bottom-left and trigger \"Charge\"!"
                ),
                subTip: L10n(
                    "💡 ビームを撃つにはバッテリーが必要です。まずは隙を見てチャージしましょう！",
                    "💡 Firing a Beam requires battery charge. Look for an opening to Charge first!"
                ),
                accentColor: .cyberEmerald,
                bubbleCenterYRatio: 0.205,
                tailDirection: .down(xRatio: 0.24),
                cpuHP: 3,
                cpuCharge: 1,
                cpuExpression: .normal,
                playerHP: 3,
                playerCharge: 1,
                playerExpression: .fun,
                selectedAction: .charge,
                showTimeBar: false,
                timeBarFraction: 0.0,
                showClappingHands: false,
                revealedCpuMove: .valid(.charge),
                revealedPlayerMove: .valid(.charge),
                callout: .chargeSuccess
            ),
            // STEP 3: BEAM（攻撃命中・Nice!!）
            PracticeLessonScenario(
                badge: "STEP 3 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("「BEAM」で相手を撃ち抜け！", "Strike Your Rival with \"BEAM\"!"),
                message: L10n(
                    "バッテリーを 1 消費して紫の【BEAM】を発射！\n相手がチャージ中（またはお手つき無防備）なら直撃して「Nice!!」！【相手のハート -1】さらに【相手のバッテリーも -1】削れます！",
                    "Spend 1 battery to fire a purple [BEAM]!\nIf your rival is Charging (or wide open), it's a direct hit — \"Nice!!\" — dealing [-1 Heart] AND [-1 Battery] to the enemy!"
                ),
                subTip: L10n(
                    "💡 体力は3ハート制！ビーム同士がぶつかった場合は相殺となりダメージはありません。",
                    "💡 Each side has 3 Hearts! If both sides fire Beams, they clash and cancel out with no damage."
                ),
                accentColor: Color(red: 1.0, green: 0.90, blue: 0.14),
                bubbleCenterYRatio: 0.642,
                tailDirection: .down(xRatio: 0.78),
                cpuHP: 2,
                cpuCharge: 0,
                cpuExpression: .sad,
                playerHP: 3,
                playerCharge: 1,
                playerExpression: .fun,
                selectedAction: .beam,
                showTimeBar: false,
                timeBarFraction: 0.0,
                showClappingHands: false,
                revealedCpuMove: .valid(.charge),
                revealedPlayerMove: .valid(.beam),
                callout: .niceHit
            ),
            // STEP 4: BARRIER（防御・Good!!）
            PracticeLessonScenario(
                badge: "STEP 4 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("「BARRIER」で相手のビームを防げ！", "Block Enemy Beams with \"BARRIER\"!"),
                message: L10n(
                    "相手のバッテリーが溜まっている時はビームの警戒時！\n水色の【BARRIER（消費0）】を出せば、相手の通常ビームをノーダメージで完全に防ぎ「Good!!」となります！",
                    "Watch out when your rival has battery charge!\nUse cyan [BARRIER (Cost 0)] to completely block normal enemy Beams with zero damage — \"Good!!\"!"
                ),
                subTip: L10n(
                    "💡 バリアは何回でもバッテリー消費0で使えます。相手の攻撃タイミングを読もう！",
                    "💡 Barrier costs 0 charge and can be used anytime. Read your opponent's attack timing!"
                ),
                accentColor: .cyberCyan,
                bubbleCenterYRatio: 0.205,
                tailDirection: .down(xRatio: 0.76),
                cpuHP: 2,
                cpuCharge: 0,
                cpuExpression: .normal,
                playerHP: 3,
                playerCharge: 1,
                playerExpression: .fun,
                selectedAction: .barrier,
                showTimeBar: false,
                timeBarFraction: 0.0,
                showClappingHands: false,
                revealedCpuMove: .valid(.beam),
                revealedPlayerMove: .valid(.barrier),
                callout: .goodGuard
            ),
            // STEP 5: お手つき不発（NO GUARD / Bad）＆ 残りHP1ピンチ状態
            PracticeLessonScenario(
                badge: "STEP 5 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("⚠️お手つき無防備とピンチ状態に注意！", "⚠️ Watch Out for Fumbles & Low HP!"),
                message: L10n(
                    "バッテリーが 0 なのに BEAM を選ぶと【NO GUARD（お手つき不発）】となり完全無防備になります！\n被弾すると「Bad」でハートとバッテリーが -1！残りハートが 1 になるとエリアが赤いネオンに染まりピンチ状態になります！",
                    "Picking BEAM with 0 battery causes [NO GUARD (Fumble)], leaving you wide open!\nTaking a hit triggers \"Bad\" (-1 Heart & -1 Battery)! At 1 Heart left, your area glows red in Danger mode!"
                ),
                subTip: L10n(
                    "⚠️ 下のボタンに「NO CHARGE」と出ている時は不発になります。バッテリー残量に注意！",
                    "⚠️ If \"NO CHARGE\" appears on the button, it will misfire. Keep an eye on your battery!"
                ),
                accentColor: .cyberDanger,
                bubbleCenterYRatio: 0.205,
                tailDirection: .down(xRatio: 0.50),
                cpuHP: 2,
                cpuCharge: 1,
                cpuExpression: .fun,
                playerHP: 1,
                playerCharge: 0,
                playerExpression: .sad,
                selectedAction: .beam,
                showTimeBar: false,
                timeBarFraction: 0.0,
                showClappingHands: false,
                revealedCpuMove: .valid(.beam),
                revealedPlayerMove: .fumble(attempted: .beam),
                callout: .badHit
            ),
            // STEP 6: 4チャージ到達・金色 ULTIMATE 一撃必殺 ➔ 「練習」ボタンで1戦練習バトルへ！
            PracticeLessonScenario(
                badge: "STEP 6 / 6",
                speaker: "REO // RULE GUIDE",
                title: L10n("🌟4チャージで一撃必殺「ULTIMATE」！！", "🌟 4 Charges: One-Hit KO \"ULTIMATE\"!!"),
                message: L10n(
                    "バッテリーを【4つ満タン】まで溜めると、下の3ボタンが黄金に輝く【ULTIMATE】ボタンに合体変化します！\nタップした瞬間にド派手なカットイン＆必殺技が発動し、相手のバリアや残りハートを貫通して一撃で勝利となります！",
                    "Fill all [4 Battery Cells] and the 3 buttons merge into a golden [ULTIMATE] button!\nTap it to unleash an instant cut-in & Ultimate attack that pierces enemy Barriers and remaining Hearts for an instant win!"
                ),
                subTip: L10n(
                    "👇「必殺技を見る」で演出を確認したら、「練習」ボタンでまずは1戦戦ってみよう！",
                    "👇 Tap \"Preview Ult\" to see the animation, then tap \"Practice\" to fight 1 match!"
                ),
                accentColor: .cyberAmber,
                bubbleCenterYRatio: 0.425,
                tailDirection: .down(xRatio: 0.50),
                cpuHP: 1,
                cpuCharge: 1,
                cpuExpression: .sad,
                playerHP: 3,
                playerCharge: 4,
                playerExpression: .fun,
                selectedAction: .charge,
                showTimeBar: false,
                timeBarFraction: 0.0,
                showClappingHands: false,
                revealedCpuMove: nil,
                revealedPlayerMove: nil,
                callout: nil
            )
        ]
    }

    var body: some View {
        let _ = lang.language
        ZStack {
            // ステータスバー背面領域を黒で保護
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)

                if phase == .ruleGuide {
                    ruleGuideCanvas(w: w, h: h)
                } else {
                    livePracticeBattleCanvas(w: w, h: h)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // ルール学習中の必殺技プレビュー
            if showDemoUltimate {
                UltimateCutinOverlayView(character: .reo, isPlayer: true) {
                    showDemoUltimate = false
                }
                .zIndex(30)
            }

            // 1戦練習バトル中の4チャージ必殺技カットイン＆動画演出
            if let ult = engine.activeUltimate {
                UltimateCutinOverlayView(
                    character: ult.character,
                    isPlayer: ult.isPlayer
                ) {
                    engine.completeUltimateSequence()
                }
                .zIndex(32)
            }
        }
        .animation(.easeInOut(duration: 0.24), value: lessonStep)
        .animation(.easeInOut(duration: 0.24), value: phase)
        .animation(.easeInOut(duration: 0.24), value: engine.outcome)
        .onAppear {
            engine.stopTimer()
            phase = .ruleGuide
            lessonStep = 0
            playStepTransitionSE(for: 0)
        }
    }

    // MARK: - Phase 1: Rule Guide Canvas (STEP 1/6 〜 STEP 6/6)
    private func ruleGuideCanvas(w: CGFloat, h: CGFloat) -> some View {
        let step = scenarios[lessonStep]
        let isUltReady = step.playerCharge >= engine.maxCharge
        let isCpuLowHP = (step.cpuHP == 1)
        let isPlayerLowHP = (step.playerHP == 1)
        let cpuDisplayExpression: CharacterExpression = isCpuLowHP ? .sad : step.cpuExpression
        let playerDisplayExpression: CharacterExpression = isPlayerLowHP ? .sad : step.playerExpression

        return ZStack {
            Color.black
                .ignoresSafeArea()

            Image("battle_screen_bg")
                .resizable()
                .interpolation(.high)
                .frame(width: w, height: h)

            if isCpuLowHP {
                practiceEnemyLowHpNeonRedBackdrop(w: w, h: h)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if isPlayerLowHP {
                practicePlayerLowHpNeonRedBackdrop(w: w, h: h)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if isUltReady {
                RadialGradient(
                    colors: [
                        Color.cyberAmber.opacity(0.26),
                        Color.cyberAmber.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: w * 0.85
                )
                .frame(width: w, height: h)
                .allowsHitTesting(false)
            }

            // 左上：敵キャラクター（GEEK）大型立ち絵
            ZStack {
                if isCpuLowHP {
                    RadialGradient(
                        colors: [
                            dangerNeonRed.opacity(0.72),
                            Color(red: 0.55, green: 0.0, blue: 0.08).opacity(0.55),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.22, y: 0.18),
                        startRadius: 8,
                        endRadius: w * 0.36
                    )
                }

                Image(CharacterProfile.baseKumiteRoster[0].standingAsset(for: cpuDisplayExpression))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: h * 0.565)
                    .scaleEffect(x: -1.0, y: 1.0)
                    .scaleEffect(
                        cpuDisplayExpression == .fun ? 1.05 : (cpuDisplayExpression == .sad ? 0.95 : 1.0)
                    )
                    .shadow(color: (isCpuLowHP ? dangerNeonRed : enemyNeonMagenta).opacity(0.80), radius: isCpuLowHP ? 16 : 12)
                    .position(x: w * 0.220, y: h * 0.285)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: cpuDisplayExpression)
            }
            .frame(width: w, height: h)
            .clipShape(PracticeTopLeftEnemyClipShape())
            .allowsHitTesting(false)

            Image("battle_enemy_frame_fg")
                .resizable()
                .interpolation(.high)
                .colorMultiply(isCpuLowHP ? Color(red: 1.0, green: 0.28, blue: 0.28) : .white)
                .shadow(color: isCpuLowHP ? dangerNeonRed : .clear, radius: 8)
                .frame(width: w, height: h)
                .allowsHitTesting(false)

            // 右上：敵ステータス
            practiceEnemyHudContents(
                w: w,
                h: h,
                hp: step.cpuHP,
                charge: step.cpuCharge,
                isLowHP: isCpuLowHP
            )

            // 右下：主人公 REO 大型立ち絵
            ZStack {
                if isPlayerLowHP {
                    RadialGradient(
                        colors: [
                            dangerNeonRed.opacity(0.75),
                            Color(red: 0.55, green: 0.0, blue: 0.08).opacity(0.55),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.78, y: 0.86),
                        startRadius: 10,
                        endRadius: w * 0.40
                    )
                }

                Image(CharacterProfile.reo.standingAsset(for: playerDisplayExpression))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: h * 0.625)
                    .scaleEffect(
                        playerDisplayExpression == .fun ? 1.05 : (playerDisplayExpression == .sad ? 0.95 : 1.0)
                    )
                    .shadow(color: (isPlayerLowHP ? dangerNeonRed : Color.cyberCyan).opacity(0.80), radius: isPlayerLowHP ? 16 : 12)
                    .position(x: w * 0.785, y: h * 1.002)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: playerDisplayExpression)
            }
            .frame(width: w, height: h)
            .clipped()
            .allowsHitTesting(false)

            // 左下：REO ステータス
            practicePlayerHudContents(
                w: w,
                h: h,
                hp: step.playerHP,
                charge: step.playerCharge,
                isLowHP: isPlayerLowHP
            )

            // Reo顔左の英字判定
            if let callout = step.callout {
                practiceReoLeftCalloutView(callout: callout, w: w, h: h)
            }

            // 中央アリーナ
            practiceArenaStage(step: step, w: w, h: h)
                .frame(width: w)
                .position(x: w * 0.50, y: h * 0.432)
                .allowsHitTesting(false)

            // 斜め3コマンドボタン ⇄ 金色 ULTIMATE
            practiceCommandDeck(step: step, isUltReady: isUltReady)
                .frame(width: w * 0.97)
                .position(x: w * 0.50, y: h * 0.648)

            // ハイライト枠
            stepTargetHighlightOverlay(stepIndex: lessonStep, accent: step.accentColor, w: w, h: h)
                .allowsHitTesting(false)

            // 最上部バー（SKIP / TITLE ＆ 進捗インジケータ）
            topFloatingBar(w: w, showStepDots: true)
                .position(x: w * 0.50, y: h * 0.032)

            // 吹き出しオーバーレイ
            speechBubbleOverlay(step: step, w: w, h: h)
                .position(x: w * 0.50, y: h * step.bubbleCenterYRatio)
                .id("practice-bubble-\(lessonStep)")
                .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .frame(width: w, height: h)
        .clipped()
    }

    // MARK: - Phase 2: Live 1-Match Practice Battle at Standard Speed ➔ Post-Practice Guide Overlay
    private func livePracticeBattleCanvas(w: CGFloat, h: CGFloat) -> some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge
        let isCpuLowHP = (engine.cpuHP == 1)
        let isPlayerLowHP = (engine.playerHP == 1)
        let cpuDisplayExpression: CharacterExpression = isCpuLowHP ? .sad : engine.cpuExpression
        let playerDisplayExpression: CharacterExpression = isPlayerLowHP ? .sad : engine.playerExpression

        return ZStack {
            Color.black
                .ignoresSafeArea()

            Image("battle_screen_bg")
                .resizable()
                .interpolation(.high)
                .frame(width: w, height: h)

            if isCpuLowHP {
                practiceEnemyLowHpNeonRedBackdrop(w: w, h: h)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if isPlayerLowHP {
                practicePlayerLowHpNeonRedBackdrop(w: w, h: h)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if isUltReady {
                RadialGradient(
                    colors: [
                        Color.cyberAmber.opacity(0.24),
                        Color.cyberAmber.opacity(0.06),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: w * 0.85
                )
                .frame(width: w, height: h)
                .allowsHitTesting(false)
            }

            // 左上：GEEK 大型立ち絵
            ZStack {
                if isCpuLowHP {
                    RadialGradient(
                        colors: [
                            dangerNeonRed.opacity(0.72),
                            Color(red: 0.55, green: 0.0, blue: 0.08).opacity(0.55),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.22, y: 0.18),
                        startRadius: 8,
                        endRadius: w * 0.36
                    )
                }

                Image(engine.currentEnemy.standingAsset(for: cpuDisplayExpression))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: h * 0.565)
                    .scaleEffect(x: -1.0, y: 1.0)
                    .scaleEffect(
                        cpuDisplayExpression == .fun ? 1.05 : (cpuDisplayExpression == .sad ? 0.95 : 1.0)
                    )
                    .shadow(color: (isCpuLowHP ? dangerNeonRed : enemyNeonMagenta).opacity(0.80), radius: isCpuLowHP ? 16 : 12)
                    .position(x: w * 0.220, y: h * 0.285)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: cpuDisplayExpression)
            }
            .frame(width: w, height: h)
            .clipShape(PracticeTopLeftEnemyClipShape())
            .allowsHitTesting(false)

            Image("battle_enemy_frame_fg")
                .resizable()
                .interpolation(.high)
                .colorMultiply(isCpuLowHP ? Color(red: 1.0, green: 0.28, blue: 0.28) : .white)
                .shadow(color: isCpuLowHP ? dangerNeonRed : .clear, radius: 8)
                .frame(width: w, height: h)
                .allowsHitTesting(false)

            // 右上：敵ステータス
            practiceEnemyHudContents(
                w: w,
                h: h,
                hp: engine.cpuHP,
                charge: engine.cpuCharge,
                isLowHP: isCpuLowHP
            )

            // 右下：主人公 REO 大型立ち絵
            ZStack {
                if isPlayerLowHP {
                    RadialGradient(
                        colors: [
                            dangerNeonRed.opacity(0.75),
                            Color(red: 0.55, green: 0.0, blue: 0.08).opacity(0.55),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.78, y: 0.86),
                        startRadius: 10,
                        endRadius: w * 0.40
                    )
                }

                Image(CharacterProfile.reo.standingAsset(for: playerDisplayExpression))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: h * 0.625)
                    .scaleEffect(
                        playerDisplayExpression == .fun ? 1.05 : (playerDisplayExpression == .sad ? 0.95 : 1.0)
                    )
                    .shadow(color: (isPlayerLowHP ? dangerNeonRed : Color.cyberCyan).opacity(0.80), radius: isPlayerLowHP ? 16 : 12)
                    .position(x: w * 0.785, y: h * 1.002)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: playerDisplayExpression)
            }
            .frame(width: w, height: h)
            .clipped()
            .allowsHitTesting(false)

            // 左下：REO ステータス
            practicePlayerHudContents(
                w: w,
                h: h,
                hp: engine.playerHP,
                charge: engine.playerCharge,
                isLowHP: isPlayerLowHP
            )

            // Reo顔左の英字判定（ライブ連動）
            if engine.preBattlePhase == .none,
               engine.beat == 3,
               let callout = engine.playerClashCallout {
                practiceReoLeftCalloutView(callout: callout, w: w, h: h)
                    .id("practice-live-callout-\(engine.turnCount)-\(callout.displayText)")
                    .transition(.scale(scale: 0.65).combined(with: .opacity))
            }

            // 中央アリーナ（Ready / Go!! / 赤タイムバー＆手拍子 / 上下2段の横帯手表示）
            livePracticeHandsArena(w: w, h: h)
                .frame(width: w)
                .position(x: w * 0.50, y: h * 0.432)

            // コマンドデッキ（実際の本番操作）
            BattleCommandDeckView(engine: engine)
                .frame(width: w * 0.97)
                .position(x: w * 0.50, y: h * 0.648)

            // 最上部バー（TITLEボタン ＋ 練習バトルバッジ）
            topFloatingBar(w: w, showStepDots: false)
                .position(x: w * 0.50, y: h * 0.032)

            // 練習バトル終了後：KUMITE機能の紹介・ランキング制度の紹介・リズム高速化の紹介オーバーレイ
            if case .practiceClear(let isWin, _) = engine.outcome, engine.activeUltimate == nil {
                postPracticeFeatureGuideOverlay(isWin: isWin, w: w)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(25)
            }
        }
        .frame(width: w, height: h)
        .clipped()
    }

    // MARK: - Live Practice Hands Arena (Identical to BattleView)
    private func livePracticeHandsArena(w: CGFloat, h: CGFloat) -> some View {
        let isShowingRevealedHands = (
            engine.preBattlePhase == .none &&
            engine.beat == 3 &&
            engine.revealedPlayerMove != nil &&
            engine.revealedCpuMove != nil
        )

        return VStack(spacing: h * 0.012) {
            if !isShowingRevealedHands {
                RhythmTimeBarView(engine: engine)
                    .padding(.horizontal, w * 0.06)
            }

            ZStack {
                if engine.preBattlePhase == .ready {
                    Text("Ready")
                        .font(.system(size: min(w * 0.14, 54), weight: .black, design: .rounded))
                        .italic()
                        .tracking(3)
                        .foregroundStyle(.white)
                        .shadow(color: Color.cyberCyan, radius: 14)
                        .shadow(color: Color.cyberCyan, radius: 28)
                        .transition(.scale(scale: 0.75).combined(with: .opacity))
                } else if engine.preBattlePhase == .go {
                    Text("Go!!")
                        .font(.system(size: min(w * 0.165, 64), weight: .black, design: .rounded))
                        .italic()
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 1.0, green: 0.92, blue: 0.35), Color.cyberAmber],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.cyberAmber, radius: 16)
                        .shadow(color: Color.cyberDanger, radius: 28)
                        .transition(.scale(scale: 1.25).combined(with: .opacity))
                } else if engine.beat == 1 || engine.beat == 2 {
                    ClappingHandBeatView(baseHeight: min(h * 0.125, 108))
                        .id("practice-live-clap-\(engine.turnCount)-\(engine.beat)")
                } else if engine.beat == 3,
                          let pMove = engine.revealedPlayerMove,
                          let cMove = engine.revealedCpuMove {
                    VStack(spacing: h * 0.010) {
                        practiceHandHorizontalBand(
                            owner: engine.currentEnemy.codeName,
                            move: cMove,
                            isEnemy: true,
                            w: w,
                            h: h
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                        practiceHandHorizontalBand(
                            owner: "REO",
                            move: pMove,
                            isEnemy: false,
                            w: w,
                            h: h
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                } else {
                    Image("hand_clap")
                        .resizable()
                        .scaledToFit()
                        .frame(height: min(h * 0.11, 92))
                        .opacity(0.55)
                }
            }
            .frame(height: isShowingRevealedHands ? min(h * 0.245, 206) : min(h * 0.16, 134))
            .animation(.spring(response: 0.24, dampingFraction: 0.76), value: engine.preBattlePhase)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: engine.beat)
        }
    }

    // MARK: - Post-Practice Feature Guide Overlay (KUMITE紹介・ランキング制度紹介・リズム速度変更紹介)
    private func postPracticeFeatureGuideOverlay(isWin: Bool, w: CGFloat) -> some View {
        let headerAccent: Color = isWin ? .cyberEmerald : .cyberCyan

        return ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                // 上段：練習バトル完了ヘッダー（REOアイコン付き）
                HStack(spacing: 12) {
                    Image("icon_reo_1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(headerAccent, lineWidth: 2)
                        )
                        .shadow(color: headerAccent.opacity(0.6), radius: 6)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            isWin
                                ? L10n("YOU WIN! 練習クリア！", "YOU WIN! Practice Clear!")
                                : L10n("練習バトル完了！", "Practice Complete!")
                        )
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .italic()
                            .foregroundStyle(headerAccent)
                            .shadow(color: headerAccent.opacity(0.8), radius: 8)

                        Text(L10n("いよいよ本番！ゲームの3つの特徴を紹介するよ！", "Ready for real combat! Here are 3 key features!"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.90))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }

                Divider()
                    .background(Color.cyberCyan.opacity(0.35))

                // 1. KUMITE機能の紹介
                featureIntroRow(
                    icon: "flame.fill",
                    accent: .cyberEmerald,
                    title: L10n("KUMITE（勝ち抜きサバイバル）", "KUMITE (Survival Gauntlet)"),
                    description: L10n(
                        "個性豊かなライバルたちと連戦するメインモード！1人撃破するごとにハートは3つに全回復します。何連勝できるか限界に挑もう！",
                        "Battle consecutive cyber rivals in the main survival mode! Your 3 Hearts fully restore after each victory. Push your win streak to the limit!"
                    )
                )

                // 2. ランキング制度の紹介
                featureIntroRow(
                    icon: "trophy.fill",
                    accent: .cyberAmber,
                    title: L10n("ワールドランキング制度", "World Ranking"),
                    description: L10n(
                        "KUMITEで達成した「最大連勝記録」で世界中のプレイヤーと順位を競えます！連勝を重ねると設定画面で新しいアイコンも解放！",
                        "Compete with players worldwide for the highest KUMITE win streak! Extending your streak also unlocks new player icons in SETTING!"
                    )
                )

                // 3. リズム速度（標準 / 速め）の紹介
                featureIntroRow(
                    icon: "metronome.fill",
                    accent: .cyberCyan,
                    title: L10n("リズム速度は「速め」にも変更可能！", "Switch Rhythm Tempo to \"Fast\"!"),
                    description: L10n(
                        "今の練習は「標準」速度でしたが、設定画面（SETTING）や勝利後の画面から、よりスリリングな「速め」に切り替えることもできます！",
                        "That match was at \"Standard\" speed, but you can switch to a thrilling \"Fast\" tempo anytime in SETTING or after winning a match!"
                    )
                )

                // 下段：アクションボタン（KUMITEへ / もう1戦練習 / TITLEへ）
                VStack(spacing: 10) {
                    Button {
                        HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                        SoundManager.shared.playButtonSE()
                        engine.startOrResumeKumite()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                            Text(L10n("KUMITE に挑戦する！", "Start KUMITE!"))
                        }
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberEmerald,
                            secondaryColor: .cyberCyan,
                            cutSize: 12,
                            fillOpacity: 0.42
                        )
                    )

                    HStack(spacing: 10) {
                        Button {
                            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                            engine.startPracticeBattleMatch()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.clockwise")
                                Text(L10n("もう1戦練習", "Practice Again"))
                            }
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                        }
                        .buttonStyle(
                            CyberButtonStyle(
                                primaryColor: .cyberCyan,
                                secondaryColor: .cyberEmerald,
                                cutSize: 10,
                                fillOpacity: 0.20
                            )
                        )

                        Button {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            SoundManager.shared.playButtonSE()
                            engine.returnToTitle()
                        } label: {
                            Text("◀ TITLE")
                                .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                                .tracking(1.2)
                                .foregroundStyle(Color.cyberCyan)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .buttonStyle(
                            CyberButtonStyle(
                                primaryColor: .cyberCyan,
                                secondaryColor: Color.white.opacity(0.6),
                                cutSize: 10,
                                fillOpacity: 0.14
                            )
                        )
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
            .frame(width: min(w * 0.93, 420))
            .background(
                CyberShape(cutSize: 18)
                    .fill(Color(red: 0.04, green: 0.08, blue: 0.16).opacity(0.96))
                    .overlay(
                        CyberShape(cutSize: 18)
                            .strokeBorder(headerAccent, lineWidth: 2.2)
                    )
            )
            .shadow(color: Color.black.opacity(0.85), radius: 20)
            .shadow(color: headerAccent.opacity(0.45), radius: 16)
        }
    }

    private func featureIntroRow(
        icon: String,
        accent: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(accent.opacity(0.55), lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(accent)

                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .lineSpacing(2.5)
                    .foregroundStyle(Color.white.opacity(0.90))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Step Transition Sound Feedback
    private func playStepTransitionSE(for stepIndex: Int) {
        switch stepIndex {
        case 0:
            SoundManager.shared.playSuperClapSE()
        case 1, 2, 3, 4:
            SoundManager.shared.playHandRevealSE()
        case 5:
            SoundManager.shared.playButtonSE()
        default:
            break
        }
    }

    // MARK: - Top Floating Header (SKIP / TITLE & Step Dots or Practice Match Badge)
    private func topFloatingBar(w: CGFloat, showStepDots: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
                SoundManager.shared.playButtonSE()
                engine.returnToTitle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .black))
                    Text(engine.isFirstLaunchTutorial ? "SKIP" : "TITLE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.cyberCyan)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.82))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.cyberCyan.opacity(0.75), lineWidth: 1.3)
                        )
                )
                .shadow(color: Color.cyberCyan.opacity(0.45), radius: 6)
            }
            .buttonStyle(.plain)

            Spacer()

            if showStepDots {
                HStack(spacing: 5) {
                    ForEach(0..<scenarios.count, id: \.self) { idx in
                        Capsule()
                            .fill(
                                idx == lessonStep
                                    ? scenarios[lessonStep].accentColor
                                    : (idx < lessonStep ? Color.cyberEmerald : Color.white.opacity(0.28))
                            )
                            .frame(width: idx == lessonStep ? 20 : 8, height: 6)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.75))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                        )
                )
            } else {
                Text(L10n("PRACTICE // 標準速度", "PRACTICE // Standard"))
                    .font(.system(size: 10.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyberEmerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.78))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.cyberEmerald.opacity(0.65), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 12)
        .frame(width: w)
    }

    // MARK: - Cyber Speech Bubble (吹き出し) Overlay
    private func speechBubbleOverlay(step: PracticeLessonScenario, w: CGFloat, h: CGFloat) -> some View {
        let bubbleWidth = min(w * 0.94, 420)

        return VStack(spacing: 0) {
            if case .up(let ratio) = step.tailDirection {
                SpeechBubbleTailTriangle(pointsUp: true)
                    .fill(Color(red: 0.04, green: 0.08, blue: 0.16).opacity(0.95))
                    .frame(width: 22, height: 12)
                    .overlay(
                        SpeechBubbleTailTriangle(pointsUp: true)
                            .stroke(step.accentColor, lineWidth: 2)
                    )
                    .frame(width: bubbleWidth, alignment: .leading)
                    .offset(x: max(20, min(bubbleWidth - 42, bubbleWidth * ratio - 11)), y: 1)
                    .zIndex(2)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Image("icon_reo_1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(step.accentColor, lineWidth: 1.5)
                        )

                    Text(step.badge)
                        .font(.system(size: 10.5, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(step.accentColor, in: Capsule())

                    Text(step.title)
                        .font(.system(size: min(w * 0.042, 16.5), weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)

                    Spacer(minLength: 0)
                }

                Text(step.message)
                    .font(.system(size: min(w * 0.033, 13.0), weight: .semibold))
                    .lineSpacing(2.5)
                    .foregroundStyle(Color.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.subTip)
                    .font(.system(size: min(w * 0.029, 11.5), weight: .bold))
                    .foregroundStyle(step.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(step.accentColor.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(step.accentColor.opacity(0.45), lineWidth: 1)
                            )
                    )

                // 吹き出し内の操作ボタン行（◀ 戻る / 次へ ▶ / 最終STEP 6: 必殺技を見る ＆ 「練習」ボタン）
                HStack(spacing: 8) {
                    if lessonStep > 0 {
                        Button {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            let prev = max(0, lessonStep - 1)
                            lessonStep = prev
                            playStepTransitionSE(for: prev)
                        } label: {
                            Text(L10n("◀ 戻る", "◀ Back"))
                                .font(.system(size: 12.5, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 78, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9)
                                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    if lessonStep < scenarios.count - 1 {
                        Button {
                            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                            let next = min(scenarios.count - 1, lessonStep + 1)
                            lessonStep = next
                            playStepTransitionSE(for: next)
                        } label: {
                            HStack(spacing: 6) {
                                Text(L10n("次へ（\(lessonStep + 2)/\(scenarios.count)）", "Next (\(lessonStep + 2)/\(scenarios.count))"))
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11, weight: .black))
                            }
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(step.accentColor)
                                    .shadow(color: step.accentColor.opacity(0.8), radius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // 最終ステップ：必殺技演出プレビュー ＆ 「練習」ボタン（標準速度で1戦練習バトルへ！）
                        Button {
                            HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                            showDemoUltimate = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text(L10n("必殺技を見る", "Preview Ult"))
                            }
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color.cyberAmber)
                                    .shadow(color: Color.cyberAmber.opacity(0.8), radius: 6)
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                            phase = .practiceBattle
                            engine.startPracticeBattleMatch()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .black))
                                Text(L10n("練習", "Practice"))
                            }
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color.cyberEmerald)
                                    .shadow(color: Color.cyberEmerald.opacity(0.85), radius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(width: bubbleWidth)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.04, green: 0.08, blue: 0.16).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(step.accentColor, lineWidth: 2.2)
                    )
                    .shadow(color: Color.black.opacity(0.85), radius: 14, x: 0, y: 6)
                    .shadow(color: step.accentColor.opacity(0.55), radius: 12)
            )

            if case .down(let ratio) = step.tailDirection {
                SpeechBubbleTailTriangle(pointsUp: false)
                    .fill(Color(red: 0.04, green: 0.08, blue: 0.16).opacity(0.95))
                    .frame(width: 22, height: 13)
                    .overlay(
                        SpeechBubbleTailTriangle(pointsUp: false)
                            .stroke(step.accentColor, lineWidth: 2)
                    )
                    .frame(width: bubbleWidth, alignment: .leading)
                    .offset(x: max(20, min(bubbleWidth - 42, bubbleWidth * ratio - 11)), y: -1)
                    .zIndex(2)
            }
        }
    }

    // MARK: - Highlight Frame Around Target Battle UI Area
    @ViewBuilder
    private func stepTargetHighlightOverlay(stepIndex: Int, accent: Color, w: CGFloat, h: CGFloat) -> some View {
        switch stepIndex {
        case 0:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(accent, style: StrokeStyle(lineWidth: 2.2, dash: [7, 4]))
                    .shadow(color: accent, radius: 8)
                    .frame(width: w * 0.92, height: 30)
                    .position(x: w * 0.50, y: h * 0.365)

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accent.opacity(0.85), style: StrokeStyle(lineWidth: 2.0, dash: [7, 4]))
                    .shadow(color: accent, radius: 8)
                    .frame(width: w * 0.96, height: 138)
                    .position(x: w * 0.50, y: h * 0.648)
            }
        case 1:
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(accent, lineWidth: 2.5)
                    .shadow(color: accent, radius: 10)
                    .frame(width: w * 0.32, height: 106)
                    .position(x: w * 0.18, y: h * 0.662)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(accent, lineWidth: 2.4)
                    .shadow(color: accent, radius: 10)
                    .frame(width: w * 0.25, height: h * 0.088)
                    .position(x: w * 0.440, y: h * 0.896)
            }
        case 2:
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accent, style: StrokeStyle(lineWidth: 2.4, dash: [7, 4]))
                .shadow(color: accent, radius: 10)
                .frame(width: w * 0.52, height: h * 0.145)
                .position(x: w * 0.692, y: h * 0.112)
        case 3:
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accent, lineWidth: 2.5)
                .shadow(color: accent, radius: 10)
                .frame(width: w * 0.32, height: 106)
                .position(x: w * 0.82, y: h * 0.630)
        case 4:
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accent, lineWidth: 2.5)
                .shadow(color: accent, radius: 10)
                .frame(width: w * 0.32, height: 106)
                .position(x: w * 0.50, y: h * 0.646)
        case 5:
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accent, style: StrokeStyle(lineWidth: 2.6, dash: [8, 4]))
                .shadow(color: accent, radius: 12)
                .frame(width: w * 0.96, height: 84)
                .position(x: w * 0.50, y: h * 0.648)
        default:
            EmptyView()
        }
    }

    // MARK: - Battle Screen Components (Identical Layout to BattleView.swift)
    private func practiceEnemyLowHpNeonRedBackdrop(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    dangerNeonRed.opacity(0.55),
                    Color(red: 0.72, green: 0.02, blue: 0.10).opacity(0.32),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.36)
            )

            PracticeEnemyLowHpPanelShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.02, blue: 0.08).opacity(0.68),
                            dangerNeonRed.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    PracticeEnemyLowHpPanelShape()
                        .stroke(dangerNeonRed, lineWidth: 2.4)
                        .shadow(color: dangerNeonRed, radius: 10)
                        .shadow(color: dangerNeonRed, radius: 18)
                )
        }
        .frame(width: w, height: h)
    }

    private func practicePlayerLowHpNeonRedBackdrop(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.72, green: 0.02, blue: 0.10).opacity(0.34),
                    dangerNeonRed.opacity(0.58)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.68),
                endPoint: .bottom
            )

            PracticePlayerLowHpPanelShape()
                .fill(
                    LinearGradient(
                        colors: [
                            dangerNeonRed.opacity(0.38),
                            Color(red: 0.58, green: 0.02, blue: 0.08).opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    PracticePlayerLowHpPanelShape()
                        .stroke(dangerNeonRed, lineWidth: 2.4)
                        .shadow(color: dangerNeonRed, radius: 10)
                        .shadow(color: dangerNeonRed, radius: 18)
                )
        }
        .frame(width: w, height: h)
    }

    private func practiceEnemyHudContents(w: CGFloat, h: CGFloat, hp: Int, charge: Int, isLowHP: Bool) -> some View {
        let hudAccent = isLowHP ? dangerNeonRed : enemyNeonMagenta
        return VStack(alignment: .leading, spacing: h * 0.008) {
            Text("GEEK")
                .font(.system(size: min(w * 0.060, h * 0.026), weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white)
                .shadow(color: hudAccent, radius: 7)
                .shadow(color: hudAccent, radius: 14)

            HealthBarView(
                currentHP: hp,
                maxHP: engine.maxHP,
                accentColor: hudAccent,
                heartSize: min(w * 0.050, h * 0.023)
            )

            EnergyOrbView(
                label: "",
                currentCharge: charge,
                maxCharge: engine.maxCharge,
                accentColor: Color(red: 0.48, green: 0.82, blue: 1.0),
                showLabel: false,
                cellWidth: min(w * 0.032, 16),
                cellHeight: min(h * 0.027, 25)
            )
        }
        .frame(width: w * 0.48, alignment: .leading)
        .position(x: w * 0.692, y: h * 0.104)
    }

    private func practicePlayerHudContents(w: CGFloat, h: CGFloat, hp: Int, charge: Int, isLowHP: Bool) -> some View {
        let hpAccent: Color = isLowHP ? dangerNeonRed : .cyberEmerald
        let nameGlowColor: Color = isLowHP ? dangerNeonRed : Color.cyberCyan
        return ZStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("REO")
                    .font(.system(size: min(w * 0.062, h * 0.027), weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .shadow(color: nameGlowColor, radius: 7)
                    .shadow(color: nameGlowColor, radius: 14)

                Text("(YOU)")
                    .font(.system(size: min(w * 0.052, h * 0.022), weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .shadow(color: nameGlowColor, radius: 7)
                    .shadow(color: nameGlowColor, radius: 14)
            }
            .frame(width: w * 0.24, alignment: .leading)
            .position(x: w * 0.195, y: h * 0.885)

            VStack(alignment: .trailing, spacing: h * 0.010) {
                HealthBarView(
                    currentHP: hp,
                    maxHP: engine.maxHP,
                    accentColor: hpAccent,
                    heartSize: min(w * 0.050, h * 0.023)
                )

                EnergyOrbView(
                    label: "",
                    currentCharge: charge,
                    maxCharge: engine.maxCharge,
                    accentColor: .cyberEmerald,
                    showLabel: false,
                    cellWidth: min(w * 0.034, 17),
                    cellHeight: min(h * 0.029, 27)
                )
                .padding(.trailing, w * 0.035)
            }
            .frame(width: w * 0.28, alignment: .trailing)
            .position(x: w * 0.440, y: h * 0.896)
        }
    }

    private func practiceReoLeftCalloutView(callout: PlayerClashCallout, w: CGFloat, h: CGFloat) -> some View {
        let fontSize = min(w * 0.135, 52)
        let outlineOffsets: [(CGFloat, CGFloat)] = [
            (-1.6, -1.6), (0.0, -1.8), (1.6, -1.6),
            (-1.8,  0.0),              (1.8,  0.0),
            (-1.6,  1.6), (0.0,  1.8), (1.6,  1.6)
        ]

        return ZStack {
            ForEach(0..<outlineOffsets.count, id: \.self) { idx in
                Text(callout.displayText)
                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                    .italic()
                    .tracking(1.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Color.white)
                    .offset(x: outlineOffsets[idx].0, y: outlineOffsets[idx].1)
            }

            Text(callout.displayText)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .italic()
                .tracking(1.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(callout.primaryColor)
        }
        .shadow(color: Color.black.opacity(0.95), radius: 2, x: 0, y: 2)
        .shadow(color: callout.primaryColor, radius: 10)
        .shadow(color: callout.primaryColor.opacity(0.85), radius: 20)
        .frame(width: w * 0.54, alignment: .center)
        .position(x: w * 0.355, y: h * 0.788)
        .allowsHitTesting(false)
    }

    private func practiceArenaStage(step: PracticeLessonScenario, w: CGFloat, h: CGFloat) -> some View {
        let isShowingRevealedHands = (step.revealedPlayerMove != nil && step.revealedCpuMove != nil)

        return VStack(spacing: h * 0.012) {
            if step.showTimeBar && !isShowingRevealedHands {
                practiceStaticTimeBar(fraction: step.timeBarFraction)
                    .padding(.horizontal, w * 0.06)
            }

            ZStack {
                if step.showClappingHands {
                    ClappingHandBeatView(baseHeight: min(h * 0.125, 108))
                        .id("practice-clap-step-\(lessonStep)")
                } else if let pMove = step.revealedPlayerMove,
                          let cMove = step.revealedCpuMove {
                    VStack(spacing: h * 0.010) {
                        practiceHandHorizontalBand(
                            owner: "GEEK",
                            move: cMove,
                            isEnemy: true,
                            w: w,
                            h: h
                        )
                        practiceHandHorizontalBand(
                            owner: "REO",
                            move: pMove,
                            isEnemy: false,
                            w: w,
                            h: h
                        )
                    }
                } else {
                    Image("hand_clap")
                        .resizable()
                        .scaledToFit()
                        .frame(height: min(h * 0.11, 92))
                        .opacity(0.55)
                }
            }
            .frame(height: isShowingRevealedHands ? min(h * 0.245, 206) : min(h * 0.16, 134))
        }
    }

    private func practiceStaticTimeBar(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let activeWidth = max(0.0, totalWidth * fraction)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.09))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                    )

                if activeWidth > 0.5 {
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.72, green: 0.05, blue: 0.12),
                                        Color.cyberDanger,
                                        Color(red: 1.0, green: 0.34, blue: 0.34)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        if activeWidth > 6 {
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.86, blue: 0.86))
                                .frame(width: 4, height: 12)
                                .shadow(color: .white, radius: 4)
                        }
                    }
                    .frame(width: activeWidth, height: 12)
                    .shadow(color: Color.cyberDanger.opacity(0.95), radius: 8)
                }
            }
        }
        .frame(height: 12)
    }

    private func practiceHandHorizontalBand(
        owner: String,
        move: ResolvedMove,
        isEnemy: Bool,
        w: CGFloat,
        h: CGFloat
    ) -> some View {
        let bandColor: Color = isEnemy ? enemyNeonMagenta : Color.cyberCyan
        let bandHeight: CGFloat = min(h * 0.112, 92)

        return ZStack {
            LinearGradient(
                colors: isEnemy
                    ? [
                        Color.black.opacity(0.45),
                        Color(red: 0.28, green: 0.04, blue: 0.34).opacity(0.82),
                        move.accentColor.opacity(0.32),
                        Color.black.opacity(0.45)
                    ]
                    : [
                        Color.black.opacity(0.45),
                        move.accentColor.opacity(0.32),
                        Color(red: 0.03, green: 0.24, blue: 0.32).opacity(0.82),
                        Color.black.opacity(0.45)
                    ],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                bandColor.opacity(0.25),
                                bandColor,
                                Color.white.opacity(0.9),
                                bandColor,
                                bandColor.opacity(0.25)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.8)
                    .shadow(color: bandColor, radius: 6)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                bandColor.opacity(0.25),
                                move.accentColor,
                                bandColor,
                                bandColor.opacity(0.25)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.8)
                    .shadow(color: bandColor, radius: 6)
            }

            HStack {
                if isEnemy {
                    Text(owner)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .shadow(color: bandColor, radius: 6)
                        .padding(.leading, 14)
                    Spacer()
                } else {
                    Spacer()
                    Text(owner)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .shadow(color: bandColor, radius: 6)
                        .padding(.trailing, 14)
                }
            }

            if let asset = move.handAssetName {
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: bandHeight * 0.90)
                    .scaleEffect(x: isEnemy ? -1.0 : 1.0, y: 1.0)
                    .shadow(color: move.accentColor.opacity(0.9), radius: 10)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.cyberDanger)
                    Text("NO GUARD")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberDanger)
                }
                .shadow(color: Color.cyberDanger.opacity(0.8), radius: 8)
            }
        }
        .frame(width: w, height: bandHeight)
        .clipped()
    }

    private func practiceCommandDeck(step: PracticeLessonScenario, isUltReady: Bool) -> some View {
        ZStack {
            if isUltReady {
                UltimateReadyButton {
                    HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                    showDemoUltimate = true
                }
            } else {
                HStack(spacing: 4) {
                    ForEach(GameAction.standardCommands) { action in
                        BattleCommandButton(
                            action: action,
                            isSelected: step.selectedAction == action,
                            playerCharge: step.playerCharge
                        ) {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            switch action {
                            case .charge:
                                lessonStep = 1
                                playStepTransitionSE(for: 1)
                            case .beam:
                                lessonStep = 2
                                playStepTransitionSE(for: 2)
                            case .barrier:
                                lessonStep = 3
                                playStepTransitionSE(for: 3)
                            case .megaBeam:
                                break
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 124)
    }
}

// MARK: - Shapes for Practice Battle Screen
private struct SpeechBubbleTailTriangle: Shape {
    let pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private struct PracticeTopLeftEnemyClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.256))
        path.addLine(to: CGPoint(x: w * 0.488, y: h * 0.256))
        path.addLine(to: CGPoint(x: w * 0.432, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.048, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.025, y: h * 0.273))
        path.addLine(to: CGPoint(x: 0, y: h * 0.273))
        path.closeSubpath()
        return path
    }
}

private struct PracticeEnemyLowHpPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.028, y: h * 0.052))
        path.addLine(to: CGPoint(x: w * 0.410, y: h * 0.052))
        path.addLine(to: CGPoint(x: w * 0.432, y: h * 0.036))
        path.addLine(to: CGPoint(x: w * 0.946, y: h * 0.036))
        path.addLine(to: CGPoint(x: w * 0.970, y: h * 0.050))
        path.addLine(to: CGPoint(x: w * 0.970, y: h * 0.238))
        path.addLine(to: CGPoint(x: w * 0.942, y: h * 0.256))
        path.addLine(to: CGPoint(x: w * 0.488, y: h * 0.256))
        path.addLine(to: CGPoint(x: w * 0.432, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.048, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.028, y: h * 0.273))
        path.closeSubpath()
        return path
    }
}

private struct PracticePlayerLowHpPanelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.028, y: h * 0.858))
        path.addLine(to: CGPoint(x: w * 0.052, y: h * 0.842))
        path.addLine(to: CGPoint(x: w * 0.194, y: h * 0.842))
        path.addLine(to: CGPoint(x: w * 0.260, y: h * 0.781))
        path.addLine(to: CGPoint(x: w * 0.572, y: h * 0.781))
        path.addLine(to: CGPoint(x: w * 0.608, y: h * 0.754))
        path.addLine(to: CGPoint(x: w * 0.966, y: h * 0.754))
        path.addLine(to: CGPoint(x: w * 0.986, y: h * 0.768))
        path.addLine(to: CGPoint(x: w * 0.986, y: h * 0.958))
        path.addLine(to: CGPoint(x: w * 0.962, y: h * 0.968))
        path.addLine(to: CGPoint(x: w * 0.054, y: h * 0.968))
        path.addLine(to: CGPoint(x: w * 0.028, y: h * 0.952))
        path.closeSubpath()
        return path
    }
}
