import SwiftUI

/// 製品版バトルアリーナ画面（新サイバーHUDデザイン・事前VS画面＆Ready/Go!!導入・4チャージ電撃バッテリー・斜め3ボタン＆金色ULTIMATE対応）
struct BattleView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared
    @Bindable private var soundManager = SoundManager.shared
    @State private var isShowingRankingFallback: Bool = false

    private let enemyNeonMagenta = Color(red: 0.94, green: 0.20, blue: 0.84)
    private let enemyNeonPurple = Color(red: 0.68, green: 0.22, blue: 0.96)

    var body: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge

        ZStack {
            // MARK: 1. サイバー都市＆3Dパースペクティブグリッド背景
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.06, green: 0.10, blue: 0.20),
                    Color(red: 0.03, green: 0.05, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            BattlePerspectiveGridView(gridColor: Color.cyberCyan.opacity(0.24))
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if isUltReady {
                RadialGradient(
                    colors: [
                        Color.cyberAmber.opacity(0.22),
                        Color.cyberAmber.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 360
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // MARK: 2. メイン4段構成（上部:敵HUD → 中央:リズム＆手激突 → 中下:斜め3コマンド/ULTIMATE → 下部:REO HUD）
            VStack(spacing: 4) {
                enemyFighterHUD

                Spacer(minLength: 0)

                handsArenaStage

                Spacer(minLength: 2)

                // 画面下部 REO HUD の直上に配置されたコマンドデッキ（CHARGE / BEAM / BARRIER ⇄ 金色 ULTIMATE）
                BattleCommandDeckView(engine: engine)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)

                playerFighterHUD
            }
            .padding(.horizontal, 10)
            .padding(.top, 2)
            .padding(.bottom, 4)

            // MARK: 3. 戦闘開始前の「事前画面（VS画面）」オーバーレイ
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

            // MARK: 4. 4チャージ一撃必殺 カットイン＆必殺動画オーバーレイ
            if let ult = engine.activeUltimate {
                UltimateCutinOverlayView(
                    character: ult.character,
                    isPlayer: ult.isPlayer
                ) {
                    engine.completeUltimateSequence()
                }
                .zIndex(10)
            }

            // MARK: 5. 勝敗・次ステージ遷移リザルトオーバーレイ
            if engine.outcome.isFinished && engine.activeUltimate == nil {
                kumiteResultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: engine.outcome)
        .animation(.easeInOut(duration: 0.22), value: engine.preBattlePhase)
        .sheet(isPresented: $isShowingRankingFallback) {
            RankingInfoSheetView()
        }
    }

    // MARK: - Top: Enemy Fighter HUD (左上: 大型キャラ立ち絵[表情変化] ＋ 右上: マゼンタサイバーHUD枠)
    private var enemyFighterHUD: some View {
        ZStack(alignment: .topLeading) {
            // 右側：マゼンタ発光サイバーHUDボックス
            VStack(alignment: .trailing, spacing: 3) {
                // 上部ステージ・連勝マイクロバー
                HStack(spacing: 8) {
                    if engine.currentLoopNumber > 1 {
                        Text("LOOP \(engine.currentLoopNumber)")
                            .font(.system(size: 8.5, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.cyberAmber, in: Capsule())
                    }
                    Text("STAGE \(engine.currentStageInLoop)/\(engine.totalStagesInCurrentLoop)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text("🔥\(engine.winStreak)連勝")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberEmerald)
                }
                .padding(.trailing, 8)

                ZStack(alignment: .leading) {
                    CyberShape(cutSize: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.04, blue: 0.26).opacity(0.92),
                                    Color(red: 0.10, green: 0.02, blue: 0.16).opacity(0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    CyberShape(cutSize: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [enemyNeonMagenta, enemyNeonPurple, enemyNeonMagenta.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )

                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(engine.currentEnemy.codeName)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white)
                                .shadow(color: enemyNeonMagenta, radius: 8)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)

                            Spacer()

                            Text("////// 05-B")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(enemyNeonMagenta.opacity(0.7))
                        }

                        HealthBarView(
                            currentHP: engine.cpuHP,
                            maxHP: engine.maxHP,
                            accentColor: enemyNeonMagenta,
                            heartSize: 18
                        )

                        EnergyOrbView(
                            label: "",
                            currentCharge: engine.cpuCharge,
                            maxCharge: engine.maxCharge,
                            accentColor: .cyberCyan,
                            showLabel: false,
                            cellWidth: 16,
                            cellHeight: 24
                        )
                    }
                    .padding(.leading, 36)
                    .padding(.trailing, 14)
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 102)
                .shadow(color: enemyNeonMagenta.opacity(0.48), radius: 12)

                // 下部サイバー装飾ライン
                HStack(spacing: 6) {
                    Capsule()
                        .fill(enemyNeonMagenta.opacity(0.55))
                        .frame(width: 48, height: 3)
                    Capsule()
                        .fill(enemyNeonPurple.opacity(0.35))
                        .frame(width: 24, height: 3)
                }
                .padding(.trailing, 12)
            }

            // 左上：敵キャラクター大型立ち絵（勝敗・被弾で normal / fun / sad に表情変化）
            Image(engine.currentEnemy.standingAsset(for: engine.cpuExpression))
                .resizable()
                .scaledToFit()
                .frame(width: 138, height: 156)
                .shadow(color: enemyNeonMagenta.opacity(0.65), radius: 12)
                .offset(x: -2, y: 2)
                .scaleEffect(engine.cpuExpression == .fun ? 1.05 : (engine.cpuExpression == .sad ? 0.95 : 1.0))
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: engine.cpuExpression)
        }
        .frame(height: 156)
    }

    // MARK: - Center: Red Time Bar & Hand Clash / Ready-Go Arena
    private var handsArenaStage: some View {
        VStack(spacing: 8) {
            // 1本の時間の赤いバー（右から左へ消えていく描写）
            RhythmTimeBarView(engine: engine)
                .padding(.horizontal, 12)

            ZStack {
                if engine.preBattlePhase == .ready {
                    // 事前画面から切り替わった直後の「Ready」表示
                    Text("Ready")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .italic()
                        .tracking(3)
                        .foregroundStyle(.white)
                        .shadow(color: Color.cyberCyan, radius: 14)
                        .shadow(color: Color.cyberCyan, radius: 28)
                        .transition(.scale(scale: 0.75).combined(with: .opacity))
                } else if engine.preBattlePhase == .go {
                    // 「Go!!」表示（この直後に3拍開始）
                    Text("Go!!")
                        .font(.system(size: 64, weight: .black, design: .rounded))
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
                    // 1・2拍目：手拍子イラスト
                    VStack(spacing: 4) {
                        Image("hand_clap")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .shadow(color: Color.cyberCyan.opacity(0.85), radius: 14)
                            .scaleEffect(engine.beat == 2 ? 1.08 : 0.98)
                            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: engine.beat)

                        Text(engine.calloutText)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberCyan, radius: 10)
                    }
                } else if engine.beat == 3,
                          let pMove = engine.revealedPlayerMove,
                          let cMove = engine.revealedCpuMove {
                    // 3拍目：両者の手イラスト激突表示
                    VStack(spacing: 4) {
                        HStack(spacing: 12) {
                            handMoveCard(owner: "REO", move: pMove)
                            Text("VS")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .italic()
                                .foregroundStyle(Color.cyberCyan)
                                .shadow(color: Color.cyberCyan, radius: 8)
                            handMoveCard(owner: engine.currentEnemy.codeName, move: cMove)
                        }

                        Text(engine.calloutText)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberEmerald, radius: 10)
                    }
                } else {
                    VStack(spacing: 6) {
                        Image("hand_clap")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 86)
                            .opacity(0.55)

                        Text(engine.calloutText)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberCyan, radius: 10)
                    }
                }
            }
            .frame(height: 132)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: engine.preBattlePhase)

            Text(engine.statusDetailText)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(engine.playerCharge >= engine.maxCharge ? Color.cyberAmber : Color.cyberCyan)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func handMoveCard(owner: String, move: ResolvedMove) -> some View {
        VStack(spacing: 3) {
            Text(owner)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.7))

            if let asset = move.handAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 102, height: 68)
                    .shadow(color: move.accentColor.opacity(0.85), radius: 8)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.cyberDanger)
                    Text("NO GUARD")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberDanger)
                }
                .frame(width: 102, height: 68)
            }

            Text(move.displayLabel)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(move.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(move.accentColor.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Bottom: Player (REO) HUD (左下: シアンサイバーHUD枠 ＋ 右下: 大型REO立ち絵[表情変化])
    private var playerFighterHUD: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge
        let hudBorderColor: Color = isUltReady ? .cyberAmber : .cyberCyan

        return ZStack(alignment: .bottomTrailing) {
            // 左側：シアン／ティール発光サイバーHUDボックス
            VStack(alignment: .leading, spacing: 3) {
                // 上部サイバー装飾テレメトリライン
                HStack(spacing: 5) {
                    ForEach(0..<6, id: \.self) { _ in
                        Capsule()
                            .fill(Color.cyberCyan.opacity(0.65))
                            .frame(width: 7, height: 2.5)
                    }
                    Text("SYS // REO-01")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan.opacity(0.65))
                }
                .padding(.leading, 8)

                ZStack(alignment: .leading) {
                    CyberShape(cutSize: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.02, green: 0.19, blue: 0.26).opacity(0.92),
                                    Color(red: 0.01, green: 0.10, blue: 0.16).opacity(0.90)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    CyberShape(cutSize: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [hudBorderColor, Color.cyberEmerald, hudBorderColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isUltReady ? 2.2 : 2.0
                        )

                    HStack(alignment: .center, spacing: 12) {
                        // 左列：REO / (YOU)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("REO")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white)
                                .shadow(color: Color.cyberCyan, radius: 8)

                            Text("(YOU)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .shadow(color: Color.cyberCyan, radius: 6)
                        }

                        // 右列：ハート3つ（上段）＋ 縦型バッテリー4セル（下段）
                        VStack(alignment: .leading, spacing: 8) {
                            HealthBarView(
                                currentHP: engine.playerHP,
                                maxHP: engine.maxHP,
                                accentColor: .cyberEmerald,
                                heartSize: 18
                            )

                            EnergyOrbView(
                                label: "",
                                currentCharge: engine.playerCharge,
                                maxCharge: engine.maxCharge,
                                accentColor: .cyberEmerald,
                                showLabel: false,
                                cellWidth: 16,
                                cellHeight: 24
                            )
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 34)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, 102)
                .shadow(color: hudBorderColor.opacity(0.45), radius: 12)
            }

            // 右下：主人公 REO 大型立ち絵（勝敗・被弾で normal / fun / sad に表情変化）
            Image(CharacterProfile.reo.standingAsset(for: engine.playerExpression))
                .resizable()
                .scaledToFit()
                .frame(width: 142, height: 162)
                .shadow(color: Color.cyberCyan.opacity(0.65), radius: 12)
                .offset(x: 4, y: 4)
                .scaleEffect(engine.playerExpression == .fun ? 1.05 : (engine.playerExpression == .sad ? 0.95 : 1.0))
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: engine.playerExpression)
        }
        .frame(height: 154)
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

// MARK: - コマンドデッキ（通常時: 斜め3ボタン CHARGE / BEAM / BARRIER ⇄ 4チャージ時: 金色発光 ULTIMATE 1ボタン）
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
                HStack(spacing: 10) {
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
        .frame(height: 76)
        .animation(.spring(response: 0.28, dampingFraction: 0.74), value: isUltReady)
    }
}

/// デザイン案準拠の斜めカット・サイバーコマンドボタン形状
private struct SlantedCyberButtonShape: Shape {
    var slantDrop: CGFloat = 11
    var cornerCut: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let s = min(slantDrop, h * 0.25)
        let c = min(cornerCut, min(w, h) * 0.2)

        var path = Path()
        // 左上（少し下がった位置から面取り開始）
        path.move(to: CGPoint(x: 0, y: s + c))
        path.addLine(to: CGPoint(x: c, y: s))
        // 右上（斜め上へ上がる）
        path.addLine(to: CGPoint(x: w - c, y: 0))
        path.addLine(to: CGPoint(x: w, y: c))
        // 右下（斜めラインと平行に上がる）
        path.addLine(to: CGPoint(x: w, y: h - s - c))
        path.addLine(to: CGPoint(x: w - c, y: h - s))
        // 左下
        path.addLine(to: CGPoint(x: c, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - c))
        path.closeSubpath()
        return path
    }
}

/// 横並び3列用の斜めサイバーコマンド選択ボタン（CHARGE: 緑 / BEAM: 紫マゼンタ / BARRIER: シアン）
struct BattleCommandButton: View {
    let action: GameAction
    let isSelected: Bool
    let playerCharge: Int
    let onTap: () -> Void

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

    private var iconSymbolName: String {
        switch action {
        case .charge:
            return "bolt.circle"
        case .beam:
            return "burst.fill"
        case .barrier:
            return "shield.fill"
        case .megaBeam:
            return "sparkles"
        }
    }

    var body: some View {
        let isAffordable = playerCharge >= action.cost
        let activeColor: Color = (isSelected && !isAffordable) ? .cyberDanger : themeColor

        Button(action: onTap) {
            ZStack {
                // 背面ダークプレート＋選択時ネオングロー充填
                SlantedCyberButtonShape()
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    activeColor.opacity(0.42),
                                    activeColor.opacity(0.18),
                                    Color(red: 0.04, green: 0.08, blue: 0.16).opacity(0.92)
                                ]
                                : [
                                    activeColor.opacity(isAffordable ? 0.18 : 0.06),
                                    Color(red: 0.04, green: 0.07, blue: 0.14).opacity(0.90)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 外枠ネオンライン
                SlantedCyberButtonShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                isSelected ? Color.white : activeColor.opacity(isAffordable ? 0.95 : 0.42),
                                activeColor.opacity(isAffordable ? 0.85 : 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2.6 : 1.8
                    )

                // 内側メカニック二重枠
                SlantedCyberButtonShape()
                    .inset(by: 4)
                    .stroke(
                        activeColor.opacity(isSelected ? 0.65 : 0.28),
                        lineWidth: 0.9
                    )

                // 右上アイコン ＋ 中央斜めテキスト ＋ 選択インジケータ
                VStack(spacing: 2) {
                    HStack {
                        Spacer()
                        Image(systemName: iconSymbolName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isAffordable ? Color.white.opacity(0.92) : Color.white.opacity(0.38))
                            .shadow(color: activeColor, radius: 5)
                    }
                    .padding(.trailing, 10)
                    .padding(.top, 4)

                    Text(action.codeName)
                        .font(.system(size: 15.5, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(isAffordable ? .white : Color.white.opacity(0.45))
                        .shadow(color: activeColor.opacity(0.9), radius: isSelected ? 8 : 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .rotationEffect(.degrees(-5.5))
                        .offset(y: -2)

                    if isSelected {
                        Text(isAffordable ? "READY" : "不発注意")
                            .font(.system(size: 8.5, weight: .black, design: .monospaced))
                            .foregroundStyle(isAffordable ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(activeColor, in: Capsule())
                            .rotationEffect(.degrees(-5.5))
                    } else {
                        Spacer(minLength: 8)
                    }
                }
                .padding(.horizontal, 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(
                color: activeColor.opacity(isSelected ? 0.82 : (isAffordable ? 0.42 : 0.12)),
                radius: isSelected ? 12 : 6
            )
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

extension Shape {
    fileprivate func inset(by amount: CGFloat) -> some Shape {
        InsettableWrapperShape(base: self, insetAmount: amount)
    }
}

private struct InsettableWrapperShape<Base: Shape>: Shape {
    let base: Base
    let insetAmount: CGFloat

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard insetRect.width > 0, insetRect.height > 0 else { return Path() }
        return base.path(in: insetRect)
    }
}
