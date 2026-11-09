import SwiftUI

/// 製品版バトルアリーナ画面
/// - 添付2枚目の背景テンプレート（`battle_screen_bg`）をベースに、添付1枚目の配置・デザイン（左上:敵立ち絵＋右上:敵名/ハート/縦バッテリー、中央:赤タイムバー＋手イラスト激突、中下:斜め3コマンドボタン `CHARGE / BEAM / BARRIER` ⇄ 4チャージ金色 `ULTIMATE`、左下:`REO (YOU)`/緑ハート/緑4バッテリー＋右下:REO立ち絵）を忠実に再現
struct BattleView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared
    @Bindable private var soundManager = SoundManager.shared
    @State private var isShowingRankingFallback: Bool = false

    private let enemyNeonMagenta = Color(red: 0.96, green: 0.26, blue: 0.88)

    var body: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge

        ZStack {
            // iPhone最上部のステータスバー領域（時計・電波・バッテリー残量）の背面のみ黒で塗りつぶし、バトル画面UI本体はその下に配置
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                // MARK: 1. ベース背景画像（添付2枚目＋左下 `REO (YOU)` 組み込み済み、全機種100%画面フィット）
                Image("battle_screen_bg")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: w, height: h)

                // 4チャージ到達時の黄金アンビエント発光
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

                // MARK: 2. 左上：敵キャラクター大型立ち絵（右向きミラー・勝敗/被弾で normal / fun / sad に表情変化）
                ZStack {
                    Image(engine.currentEnemy.standingAsset(for: engine.cpuExpression))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: h * 0.565)
                        .scaleEffect(x: -1.0, y: 1.0)
                        .scaleEffect(
                            engine.cpuExpression == .fun ? 1.05 : (engine.cpuExpression == .sad ? 0.95 : 1.0)
                        )
                        .shadow(color: enemyNeonMagenta.opacity(0.65), radius: 12)
                        .position(x: w * 0.220, y: h * 0.285)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: engine.cpuExpression)
                }
                .frame(width: w, height: h)
                .clipShape(TopLeftBattleEnemyClipShape())
                .allowsHitTesting(false)

                // 左上敵フレーム下辺のマゼンタ発光ボーダー前景レイヤー（キャラの腰境界を自然にフレーム内へ収める）
                Image("battle_enemy_frame_fg")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)

                // MARK: 3. 右上マゼンタ枠内：敵名称・3ハート・4バッテリー（添付1枚目の座標に完全準拠）
                enemyHudContents(w: w, h: h)

                // MARK: 4. 右下：主人公 REO 大型立ち絵（勝敗/被弾で normal / fun / sad に表情変化）
                ZStack {
                    Image(CharacterProfile.reo.standingAsset(for: engine.playerExpression))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: h * 0.625)
                        .scaleEffect(
                            engine.playerExpression == .fun ? 1.05 : (engine.playerExpression == .sad ? 0.95 : 1.0)
                        )
                        .shadow(color: Color.cyberCyan.opacity(0.65), radius: 12)
                        .position(x: w * 0.785, y: h * 1.002)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: engine.playerExpression)
                }
                .frame(width: w, height: h)
                .clipped()
                .allowsHitTesting(false)

                // MARK: 5. 左下シアン枠内：3緑ハート・4緑バッテリー（4チャージで黄色発光＋電撃アニメーション）
                playerHudContents(w: w, h: h)

                // MARK: 6. 中央3Dグリッドアリーナ：1本の赤いタイムバー ＆ Ready/Go!!/上下2段の横帯手イラスト表示
                handsArenaStage(w: w, h: h)
                    .frame(width: w)
                    .position(x: w * 0.50, y: h * 0.432)

                // MARK: 7. 斜め3コマンドボタン（CHARGE / BEAM / BARRIER ⇄ 4チャージ金色 ULTIMATE）
                BattleCommandDeckView(engine: engine)
                    .frame(width: w * 0.97)
                    .position(x: w * 0.50, y: h * 0.648)

                // MARK: 8. 戦闘開始前の「事前画面（VS画面）」オーバーレイ
                if engine.preBattlePhase == .vsScreen {
                    PreBattleVsOverlayView(
                        enemy: engine.currentEnemy,
                        stageLabel: "STAGE \(engine.currentStageInLoop)/\(engine.totalStagesInCurrentLoop)",
                        winStreak: engine.winStreak,
                        isHapticsEnabled: engine.isHapticsEnabled,
                        onStartTapped: {
                            engine.confirmVsScreenStart()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(8)
                }

                // MARK: 9. 4チャージ一撃必殺 カットイン＆必殺動画オーバーレイ
                if let ult = engine.activeUltimate {
                    UltimateCutinOverlayView(
                        character: ult.character,
                        isPlayer: ult.isPlayer
                    ) {
                        engine.completeUltimateSequence()
                    }
                    .zIndex(10)
                }

                // MARK: 10. 勝敗・次ステージ遷移リザルトオーバーレイ
                if engine.outcome.isFinished && engine.activeUltimate == nil {
                    kumiteResultOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        .zIndex(20)
                }
            }
            .frame(width: w, height: h)
            .clipped()
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .animation(.easeInOut(duration: 0.22), value: engine.outcome)
        .animation(.easeInOut(duration: 0.22), value: engine.preBattlePhase)
        .sheet(isPresented: $isShowingRankingFallback) {
            RankingInfoSheetView()
        }
    }

    // MARK: - Top-Right Enemy HUD Box Contents (`x = 0.45..0.94 * w, y = 0.05..0.16 * h`)
    private func enemyHudContents(w: CGFloat, h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: h * 0.008) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(engine.currentEnemy.codeName)
                    .font(.system(size: min(w * 0.060, h * 0.026), weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .shadow(color: enemyNeonMagenta, radius: 7)
                    .shadow(color: enemyNeonMagenta, radius: 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 4)

                // ステージ＆連勝表示
                HStack(spacing: 5) {
                    if engine.currentLoopNumber > 1 {
                        Text("L\(engine.currentLoopNumber)")
                            .font(.system(size: 8.5, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.cyberAmber, in: Capsule())
                    }
                    Text("STAGE \(engine.currentStageInLoop)/\(engine.totalStagesInCurrentLoop)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.80))
                    Text("🔥\(engine.winStreak)")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberEmerald)
                }
            }

            HealthBarView(
                currentHP: engine.cpuHP,
                maxHP: engine.maxHP,
                accentColor: enemyNeonMagenta,
                heartSize: min(w * 0.050, h * 0.023)
            )

            EnergyOrbView(
                label: "",
                currentCharge: engine.cpuCharge,
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

    // MARK: - Bottom-Left Player HUD Box Contents (`REO (YOU)` の右隣にハート3つ＋バッテリー4つ)
    private func playerHudContents(w: CGFloat, h: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: h * 0.010) {
            HealthBarView(
                currentHP: engine.playerHP,
                maxHP: engine.maxHP,
                accentColor: .cyberEmerald,
                heartSize: min(w * 0.050, h * 0.023)
            )

            EnergyOrbView(
                label: "",
                currentCharge: engine.playerCharge,
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

    // MARK: - Center: Red Time Bar & Hand Clash (Full-Width Vertical Bands) / Ready-Go Arena
    private func handsArenaStage(w: CGFloat, h: CGFloat) -> some View {
        let isShowingRevealedHands = (
            engine.preBattlePhase == .none &&
            engine.beat == 3 &&
            engine.revealedPlayerMove != nil &&
            engine.revealedCpuMove != nil
        )

        return VStack(spacing: h * 0.012) {
            // お互いの手を表示している間（3拍目）は3拍の赤い時間バーを非表示にする
            if !isShowingRevealedHands {
                RhythmTimeBarView(engine: engine)
                    .padding(.horizontal, w * 0.06)
            }

            ZStack {
                if engine.preBattlePhase == .ready {
                    // 事前画面から切り替わった直後の「Ready」表示
                    Text("Ready")
                        .font(.system(size: min(w * 0.14, 54), weight: .black, design: .rounded))
                        .italic()
                        .tracking(3)
                        .foregroundStyle(.white)
                        .shadow(color: Color.cyberCyan, radius: 14)
                        .shadow(color: Color.cyberCyan, radius: 28)
                        .transition(.scale(scale: 0.75).combined(with: .opacity))
                } else if engine.preBattlePhase == .go {
                    // 「Go!!」表示（この直後に3拍開始）
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
                    // 1・2拍目：手拍子イラストのみ表示（「バン！」等の下部文字は非表示）
                    Image("hand_clap")
                        .resizable()
                        .scaledToFit()
                        .frame(height: min(h * 0.125, 108))
                        .shadow(color: Color.cyberCyan.opacity(0.85), radius: 14)
                        .scaleEffect(engine.beat == 2 ? 1.08 : 0.98)
                        .animation(.spring(response: 0.2, dampingFraction: 0.55), value: engine.beat)
                } else if engine.beat == 3,
                          let pMove = engine.revealedPlayerMove,
                          let cMove = engine.revealedCpuMove {
                    // 3拍目：画面横いっぱいの帯状に上下2段で表示（上段＝相手の手、下段＝自分の手）
                    VStack(spacing: h * 0.010) {
                        handMoveHorizontalBand(
                            owner: engine.currentEnemy.codeName,
                            move: cMove,
                            isEnemy: true,
                            w: w,
                            h: h
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                        handMoveHorizontalBand(
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

    /// 3拍目に出した手を画面横いっぱいのサイバー帯として上下に表示するコンポーネント
    private func handMoveHorizontalBand(
        owner: String,
        move: ResolvedMove,
        isEnemy: Bool,
        w: CGFloat,
        h: CGFloat
    ) -> some View {
        let bandColor: Color = isEnemy ? enemyNeonMagenta : Color.cyberCyan
        let bandHeight: CGFloat = min(h * 0.112, 92)

        return ZStack {
            // 横いっぱいの半透明サイバー帯背景
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

            // 上下の横いっぱいネオン境界ライン
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

            // 帯内のオーナー名ラベル（上段＝左端、下段＝右端）
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

            // 中央：出した手のイラスト（お手つき時は NO GUARD アイコン）
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

    // MARK: - KUMITE Result Overlay (YOU WIN / YOU LOSE...)
    private var kumiteResultOverlay: some View {
        let isStageClear: Bool = {
            if case .stageClear = engine.outcome { return true }
            return false
        }()

        let accent: Color = isStageClear ? .cyberEmerald : .cyberDanger

        return ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 勝敗にかかわらず表示される BGM ON/OFF（スピーカーアイコン）ボタン
                HStack {
                    Spacer()
                    resultBGMToggleButton
                }

                VStack(spacing: 14) {
                    Text(isStageClear ? "YOU WIN" : "YOU LOSE...")
                        .font(.system(size: 35, weight: .black, design: .rounded))
                        .italic()
                        .tracking(2)
                        .foregroundStyle(accent)
                        .shadow(color: accent.opacity(0.9), radius: 14)

                    if case .stageClear = engine.outcome {
                        HStack(alignment: .center, spacing: 12) {
                            Image("result_reo_happy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 104, height: 152)
                                .shadow(color: accent.opacity(0.45), radius: 8)

                            VStack(spacing: 12) {
                                Text("\(engine.winStreak)連勝")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.cyberAmber)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)

                                Button {
                                    HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                                    engine.advanceToNextKumiteStage()
                                } label: {
                                    Text("NEXT BATTLE ▶")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .tracking(1.2)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                }
                                .buttonStyle(
                                    CyberButtonStyle(
                                        primaryColor: .cyberEmerald,
                                        secondaryColor: .cyberCyan,
                                        cutSize: 11,
                                        fillOpacity: 0.38
                                    )
                                )

                                Button {
                                    HapticManager.playLight(enabled: engine.isHapticsEnabled)
                                    engine.returnToTitle()
                                } label: {
                                    Text("◀ TITLE")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .tracking(1.5)
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
                            .frame(maxWidth: .infinity)
                        }

                        // 次戦から反映されるテンポ切替（標準 / 速め）
                        VStack(spacing: 8) {
                            HStack {
                                Label("次戦のテンポ", systemImage: "metronome.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.85))
                                Spacer()
                                Text(engine.tempoPreset.title)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(Color.cyberCyan)
                            }

                            HStack(spacing: 10) {
                                ForEach(TempoPreset.allCases) { preset in
                                    let isSelected = (engine.tempoPreset == preset)
                                    Button {
                                        engine.tempoPreset = preset
                                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                                    } label: {
                                        Text(preset.title)
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundStyle(isSelected ? .black : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .background(
                                                RoundedRectangle(cornerRadius: 9)
                                                    .fill(isSelected ? Color.cyberCyan : Color.black.opacity(0.45))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 9)
                                                            .strokeBorder(
                                                                isSelected ? Color.cyberCyan : Color.white.opacity(0.22),
                                                                lineWidth: isSelected ? 1.8 : 1
                                                            )
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.black.opacity(0.32))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11)
                                        .strokeBorder(Color.cyberCyan.opacity(0.28), lineWidth: 1)
                                )
                        )

                        Text("※TITLEに戻っても現在の連勝状況と復活残り回数（あと\(engine.remainingRevives)回）は次回KUMITE開始時に引き継がれます")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                    } else if case .gameOver(let finalStreak, _) = engine.outcome {
                        HStack(alignment: .center, spacing: 12) {
                            Image("result_reo_lose")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 118, height: 72)
                                .shadow(color: accent.opacity(0.45), radius: 8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("今回の記録: \(finalStreak) 連勝")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.cyberCyan)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)

                                Text("自己ベスト: \(GameCenterManager.shared.bestWinStreak) 連勝")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.cyberAmber)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 2)

                        // 動画広告を見て復活（1回のKUMITE挑戦につき最大2回まで）
                        if engine.remainingRevives > 0 {
                            Button {
                                HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                                adManager.presentRewardedAdForRevive {
                                    engine.reviveCurrentKumiteMatch()
                                }
                            } label: {
                                VStack(spacing: 3) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.tv.fill")
                                        Text(adManager.isLoadingRewardedAd ? "動画広告を読み込み中..." : "動画広告を見て復活")
                                    }
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                    Text("連勝記録を維持して再戦（残り \(engine.remainingRevives) / \(engine.maxRevivesPerRun) 回）")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.cyberAmber)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                            }
                            .buttonStyle(
                                CyberButtonStyle(
                                    primaryColor: .cyberAmber,
                                    secondaryColor: .cyberEmerald,
                                    cutSize: 12,
                                    fillOpacity: 0.38
                                )
                            )
                            .disabled(adManager.isLoadingRewardedAd)

                            if let adError = adManager.rewardedAdStatusMessage {
                                Text(adError)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.cyberDanger)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            Text("※今回の挑戦での復活回数（最大\(engine.maxRevivesPerRun)回）を使い切りました")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                            engine.startKumiteFromBeginning()
                        } label: {
                            Text("RETRY (最初から挑戦)")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(
                            CyberButtonStyle(
                                primaryColor: .cyberEmerald,
                                secondaryColor: .cyberCyan,
                                cutSize: 12,
                                fillOpacity: 0.28
                            )
                        )

                        Button {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            isShowingRankingFallback = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                Text("WORLD RANKING")
                            }
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                        }
                        .buttonStyle(
                            CyberButtonStyle(
                                primaryColor: .cyberAmber,
                                secondaryColor: .cyberCyan,
                                cutSize: 10,
                                fillOpacity: 0.18
                            )
                        )

                        Button {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            engine.returnToTitle()
                        } label: {
                            Text("◀ TITLE")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Color.cyberCyan)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                        }
                        .buttonStyle(
                            CyberButtonStyle(
                                primaryColor: .cyberCyan,
                                secondaryColor: Color.white.opacity(0.6),
                                cutSize: 10,
                                fillOpacity: 0.14
                            )
                        )

                        if engine.remainingRevives > 0 && finalStreak > 0 {
                            Text("※復活回数が残っている間は、TITLEに戻っても現在の連勝記録（\(finalStreak)連勝）が保持されます")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.72))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(20)
                .background(
                    CyberShape(cutSize: 18)
                        .fill(Color.cyberPanel)
                        .overlay(
                            CyberShape(cutSize: 18)
                                .strokeBorder(accent, lineWidth: 2)
                        )
                )
                .shadow(color: accent.opacity(0.5), radius: 24)
            }
            .padding(.horizontal, 18)
        }
    }

    /// 戦闘結果画面（勝利・敗退共通）の BGM ON/OFF スピーカーアイコンボタン
    private var resultBGMToggleButton: some View {
        let isOn = soundManager.isBGMEnabled
        return Button {
            HapticManager.playLight(enabled: engine.isHapticsEnabled)
            soundManager.isBGMEnabled.toggle()
        } label: {
            Image(systemName: isOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isOn ? Color.cyberCyan : Color.white.opacity(0.45))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyberPanel.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isOn ? Color.cyberCyan.opacity(0.14) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isOn ? Color.cyberCyan : Color.white.opacity(0.25),
                                    lineWidth: isOn ? 1.5 : 1.1
                                )
                        )
                )
                .shadow(color: isOn ? Color.cyberCyan.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "BGMをオフにする" : "BGMをオンにする")
    }
}

/// 左上（敵立ち絵枠）の下辺ラインに沿ったクリップ形状（571×1024正規化座標）
private struct TopLeftBattleEnemyClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w * 0.45, y: 0))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.048, y: h * 0.286))
        path.addLine(to: CGPoint(x: w * 0.025, y: h * 0.273))
        path.addLine(to: CGPoint(x: 0, y: h * 0.273))
        path.closeSubpath()
        return path
    }
}

// MARK: - 1本の時間の赤いバー（右から左へ消えていく描写）
struct RhythmTimeBarView: View {
    var engine: GameEngine

    private func remainingFraction(at now: Date) -> CGFloat {
        if engine.preBattlePhase != .none {
            return 1.0
        }
        if engine.isRhythmRunning, let start = engine.turnWindowStartDate {
            let duration = max(0.2, engine.inputWindowDuration)
            let elapsed = max(0.0, now.timeIntervalSince(start))
            return CGFloat(max(0.0, min(1.0, 1.0 - (elapsed / duration))))
        }

        // 手動ステップモード（PRACTICE）および導入・解決フレーム
        switch engine.beat {
        case 0:
            return 1.0
        case 1:
            return 0.66
        case 2:
            return 0.33
        case 3:
            return 0.0
        default:
            return 0.0
        }
    }

    var body: some View {
        let shouldAnimateContinuously = engine.isRhythmRunning && engine.turnWindowStartDate != nil && engine.preBattlePhase == .none

        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !shouldAnimateContinuously)) { context in
            let fraction = remainingFraction(at: context.date)

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let activeWidth = max(0.0, totalWidth * fraction)

                ZStack(alignment: .leading) {
                    // ベースレール（消えた後の暗いトラック）
                    Capsule()
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    engine.beat == 3
                                        ? Color.cyberDanger.opacity(0.75)
                                        : Color.white.opacity(0.20),
                                    lineWidth: 1
                                )
                        )

                    // 右端から左端へ向かって減り消えていく1本の赤いタイムバー
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

                            // 右端の消失エッジ発光ハイライト
                            if activeWidth > 6 {
                                Capsule()
                                    .fill(Color(red: 1.0, green: 0.86, blue: 0.86))
                                    .frame(width: 4, height: 12)
                                    .shadow(color: .white, radius: 4)
                            }
                        }
                        .frame(width: activeWidth, height: 12)
                        .shadow(color: Color.cyberDanger.opacity(0.95), radius: 8)
                        .animation(
                            shouldAnimateContinuously ? nil : .easeOut(duration: 0.18),
                            value: engine.beat
                        )
                    }
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - コマンドデッキ（通常時: 添付1枚目の斜め3ボタン CHARGE / BEAM / BARRIER ⇄ 4チャージ時: 金色発光 ULTIMATE 1ボタン）
struct BattleCommandDeckView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge

        ZStack {
            if isUltReady {
                UltimateReadyButton {
                    engine.triggerPlayerUltimateImmediately()
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                HStack(spacing: 4) {
                    ForEach(GameAction.standardCommands) { action in
                        BattleCommandButton(
                            action: action,
                            isSelected: engine.selectedAction == action,
                            playerCharge: engine.playerCharge
                        ) {
                            engine.selectCommand(action)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(height: 124)
        .animation(.spring(response: 0.28, dampingFraction: 0.74), value: isUltReady)
    }
}

/// 添付1枚目のデザイン素材（`btn_battle_charge` / `btn_battle_beam` / `btn_battle_barrier`）を用いた斜め階段配置の3コマンド選択ボタン
struct BattleCommandButton: View {
    let action: GameAction
    let isSelected: Bool
    let playerCharge: Int
    let onTap: () -> Void

    private var buttonAssetName: String {
        switch action {
        case .charge:
            return "btn_battle_charge"
        case .beam:
            return "btn_battle_beam"
        case .barrier:
            return "btn_battle_barrier"
        case .megaBeam:
            return "btn_battle_beam"
        }
    }

    private var themeColor: Color {
        switch action {
        case .charge:
            return Color.cyberEmerald
        case .beam:
            return Color(red: 0.85, green: 0.26, blue: 0.98)
        case .barrier:
            return Color.cyberCyan
        case .megaBeam:
            return Color.cyberAmber
        }
    }

    /// 添付1枚目の左→右上がり斜めライン（CHARGE: 下、BEAM: 中央、BARRIER: 上）のYオフセット
    private var diagonalStepOffsetY: CGFloat {
        switch action {
        case .charge:
            return 14
        case .beam:
            return -2
        case .barrier:
            return -18
        case .megaBeam:
            return 0
        }
    }

    var body: some View {
        let isAffordable = playerCharge >= action.cost
        let activeColor: Color = (isSelected && !isAffordable) ? .cyberDanger : themeColor

        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                Image(buttonAssetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .saturation(isAffordable ? 1.05 : 0.45)
                    .brightness(isSelected ? 0.08 : (isAffordable ? 0.0 : -0.15))
                    .opacity(isSelected ? 1.0 : (isAffordable ? 0.88 : 0.52))
                    .shadow(
                        color: activeColor.opacity(isSelected ? 0.95 : 0.25),
                        radius: isSelected ? 14 : 4
                    )

                // 選択中インジケータピル
                if isSelected {
                    Text(isAffordable ? "SELECTED" : "NO CHARGE")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(isAffordable ? .black : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(activeColor, in: Capsule())
                        .shadow(color: activeColor, radius: 6)
                        .rotationEffect(.degrees(-7.5))
                        .offset(y: -4)
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.06 : 0.98)
            .offset(y: diagonalStepOffsetY)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// 4チャージ到達時に3つのボタンが統合されて出現する金色発光の横長1ボタン（ULTIMATE）
struct UltimateReadyButton: View {
    let onTap: () -> Void
    @State private var isGlowing: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 金色グラデーション本体
                CyberShape(cutSize: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.52),
                                Color(red: 1.0, green: 0.79, blue: 0.14),
                                Color.cyberAmber,
                                Color(red: 0.92, green: 0.56, blue: 0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 上部の光沢ハイライト
                CyberShape(cutSize: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isGlowing ? 0.50 : 0.22),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // 金白の発光エッジ枠
                CyberShape(cutSize: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 1.0, green: 0.94, blue: 0.55),
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.6
                    )

                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .black))
                    Text("ULTIMATE")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .italic()
                        .tracking(4)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .black))
                }
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.45, green: 0.22, blue: 0.0), radius: 2, x: 0, y: 1.5)
                .shadow(color: Color.white.opacity(0.8), radius: isGlowing ? 8 : 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .scaleEffect(isGlowing ? 1.015 : 0.995)
            .shadow(
                color: Color(red: 1.0, green: 0.85, blue: 0.22).opacity(isGlowing ? 0.95 : 0.62),
                radius: isGlowing ? 18 : 10
            )
            .shadow(
                color: Color.cyberAmber.opacity(isGlowing ? 0.78 : 0.42),
                radius: isGlowing ? 28 : 14
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.62).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}
