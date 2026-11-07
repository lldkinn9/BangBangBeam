import SwiftUI

/// 製品版バトルアリーナ画面（1本赤タイムバー・横並び3コマンド CHARGE / BEAM / BARRIER・4チャージ金色発光 ULTIMATE 即時発動対応）
struct BattleView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared
    @Bindable private var soundManager = SoundManager.shared
    @State private var isShowingRankingFallback: Bool = false

    var body: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge

        ZStack {
            // MARK: 背景グラデーション
            LinearGradient(
                colors: [Color.cyberBlack, Color.cyberPanel, Color.cyberBlack],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isUltReady {
                RadialGradient(
                    colors: [
                        Color.cyberAmber.opacity(0.22),
                        Color.cyberAmber.opacity(0.05),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 20,
                    endRadius: 380
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            } else if engine.beat == 3 {
                RadialGradient(
                    colors: [
                        Color.cyberCyan.opacity(0.24),
                        Color.cyberEmerald.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 340
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // MARK: メイン3段レイアウト
            VStack(spacing: 8) {
                headerBar

                enemyFighterCard

                Spacer(minLength: 2)

                handsArenaStage

                Spacer(minLength: 2)

                playerControlCard
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // MARK: 4チャージ一撃必殺 カットイン＆必殺動画オーバーレイ
            if let ult = engine.activeUltimate {
                UltimateCutinOverlayView(
                    character: ult.character,
                    isPlayer: ult.isPlayer
                ) {
                    engine.completeUltimateSequence()
                }
                .zIndex(10)
            }

            // MARK: 勝敗・次ステージ遷移リザルトオーバーレイ
            if engine.outcome.isFinished && engine.activeUltimate == nil {
                kumiteResultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: engine.outcome)
        .sheet(isPresented: $isShowingRankingFallback) {
            RankingInfoSheetView()
        }
    }

    // MARK: - 1. Header Bar（バトル中はタイトルへ戻れない仕様）
    private var headerBar: some View {
        VStack(spacing: 1) {
            HStack(spacing: 6) {
                if engine.currentLoopNumber > 1 {
                    Text("LOOP \(engine.currentLoopNumber)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.cyberAmber, in: Capsule())
                }
                Text("STAGE \(engine.currentStageInLoop)/\(engine.totalStagesInCurrentLoop)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Text("🔥 WIN STREAK: \(engine.winStreak)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.cyberEmerald)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    // MARK: - 2. Enemy Fighter Card (立ち絵 + HP3 + チャージ0〜4)
    private var enemyFighterCard: some View {
        HStack(spacing: 12) {
            // 敵キャラクター透過立ち絵ポートレート
            ZStack(alignment: .bottom) {
                CyberShape(cutSize: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyberDanger.opacity(0.24), Color.black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(engine.currentEnemy.standingAsset(for: engine.cpuExpression))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 92)
                    .padding(.top, 4)

                CyberShape(cutSize: 10)
                    .strokeBorder(Color.cyberDanger.opacity(0.55), lineWidth: 1.2)
            }
            .frame(width: 84, height: 96)
            .clipShape(CyberShape(cutSize: 10))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(engine.currentEnemy.codeName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    HealthBarView(
                        currentHP: engine.cpuHP,
                        maxHP: engine.maxHP,
                        accentColor: .cyberDanger
                    )
                }

                HStack {
                    EnergyOrbView(
                        label: "CHARGE",
                        currentCharge: engine.cpuCharge,
                        maxCharge: engine.maxCharge,
                        accentColor: .cyberCyan
                    )
                    Spacer()
                    if engine.cpuCharge >= engine.maxCharge {
                        Text("⚠️ ULTIMATE READY")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)
                    }
                }
            }
        }
        .padding(10)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel.opacity(0.88))
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberDanger.opacity(0.4), lineWidth: 1.2)
                )
        )
    }

    // MARK: - 3. Center Hands & Red Time Bar Stage
    private var handsArenaStage: some View {
        VStack(spacing: 10) {
            // 1本の赤いタイムバー（右から左へ滑らかに消えていく描写）
            RhythmTimeBarView(engine: engine)
                .padding(.horizontal, 14)
                .padding(.top, 2)

            // 手イラスト演出エリア
            ZStack {
                if engine.beat == 1 || engine.beat == 2 {
                    // 1・2拍目：手拍子イラスト
                    VStack(spacing: 4) {
                        Image("hand_clap")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 112)
                            .shadow(color: Color.cyberCyan.opacity(0.8), radius: 14)
                            .scaleEffect(engine.beat == 2 ? 1.08 : 0.98)
                            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: engine.beat)

                        Text(engine.calloutText)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberCyan, radius: 10)
                    }
                } else if engine.beat == 3,
                          let pMove = engine.revealedPlayerMove,
                          let cMove = engine.revealedCpuMove {
                    // 3拍目：両者の手イラスト激突表示
                    VStack(spacing: 6) {
                        HStack(spacing: 12) {
                            handMoveCard(owner: "REO", move: pMove)
                            Text("VS")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .italic()
                                .foregroundStyle(Color.cyberCyan)
                            handMoveCard(owner: engine.currentEnemy.codeName, move: cMove)
                        }

                        Text(engine.calloutText)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberEmerald, radius: 10)
                    }
                } else {
                    // 0拍目：導入
                    VStack(spacing: 8) {
                        Image("hand_clap")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 92)
                            .opacity(0.55)

                        Text(engine.calloutText)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.cyberCyan, radius: 10)
                    }
                }
            }
            .frame(height: 148)

            Text(engine.statusDetailText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(engine.playerCharge >= engine.maxCharge ? Color.cyberAmber : Color.cyberEmerald)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            CyberShape(cutSize: 16)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    CyberShape(cutSize: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.cyberDanger.opacity(0.55), Color.cyberCyan.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
    }

    private func handMoveCard(owner: String, move: ResolvedMove) -> some View {
        VStack(spacing: 4) {
            Text(owner)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.65))

            if let asset = move.handAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 105, height: 74)
                    .shadow(color: move.accentColor.opacity(0.85), radius: 8)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.cyberDanger)
                    Text("NO GUARD")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberDanger)
                }
                .frame(width: 105, height: 74)
            }

            Text(move.displayLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(move.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 4. Player (Reo) Status & Bottom Command Deck
    private var playerControlCard: some View {
        let isUltReady = engine.playerCharge >= engine.maxCharge
        let cardAccent: Color = isUltReady ? .cyberAmber : .cyberEmerald

        return VStack(spacing: 10) {
            // Reo ステータス行
            HStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    CyberShape(cutSize: 8)
                        .fill(cardAccent.opacity(0.2))

                    Image(CharacterProfile.reo.standingAsset(for: engine.playerExpression))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 64)

                    CyberShape(cutSize: 8)
                        .strokeBorder(cardAccent.opacity(0.65), lineWidth: 1)
                }
                .frame(width: 58, height: 66)
                .clipShape(CyberShape(cutSize: 8))

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("REO (YOU)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        HealthBarView(
                            currentHP: engine.playerHP,
                            maxHP: engine.maxHP,
                            accentColor: .cyberEmerald
                        )
                    }

                    HStack {
                        EnergyOrbView(
                            label: "CHARGE",
                            currentCharge: engine.playerCharge,
                            maxCharge: engine.maxCharge,
                            accentColor: .cyberEmerald
                        )

                        Spacer()
                    }
                }
            }

            // 最下部コマンドデッキ（横並び3つ CHARGE / BEAM / BARRIER ⇄ 4チャージ時は金色発光横長1つ ULTIMATE）
            BattleCommandDeckView(engine: engine)
        }
        .padding(12)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel.opacity(0.92))
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(cardAccent.opacity(isUltReady ? 0.8 : 0.42), lineWidth: isUltReady ? 1.8 : 1.2)
                )
        )
        .shadow(color: isUltReady ? Color.cyberAmber.opacity(0.28) : .clear, radius: 14)
    }

    // MARK: - 5. KUMITE Result Overlay (YOU WIN / YOU LOSE...)
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
        let shouldAnimateContinuously = engine.isRhythmRunning && engine.turnWindowStartDate != nil

        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !shouldAnimateContinuously)) { context in
            let fraction = remainingFraction(at: context.date)

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let activeWidth = max(0.0, totalWidth * fraction)

                ZStack(alignment: .leading) {
                    // ベースレール（消えた後の暗いトラック）
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    engine.beat == 3
                                        ? Color.cyberDanger.opacity(0.7)
                                        : Color.white.opacity(0.18),
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

// MARK: - 最下部コマンドデッキ（通常時: 横並び3つ CHARGE / BEAM / BARRIER ⇄ 4チャージ時: 金色発光 ULTIMATE 1ボタン）
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
                HStack(spacing: 8) {
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
        .frame(height: 64)
        .animation(.spring(response: 0.28, dampingFraction: 0.74), value: isUltReady)
    }
}

/// 横並び3列用のサイバーコマンド選択ボタン（CHARGE / BEAM / BARRIER）
struct BattleCommandButton: View {
    let action: GameAction
    let isSelected: Bool
    let playerCharge: Int
    let onTap: () -> Void

    private var subCaption: String {
        switch action {
        case .charge:   return "+1 CHARGE"
        case .beam:     return "COST 1"
        case .barrier:  return "GUARD"
        case .megaBeam: return "MAX"
        }
    }

    var body: some View {
        let isAffordable = playerCharge >= action.cost
        let borderColor: Color = {
            if isSelected && !isAffordable {
                return .cyberDanger
            }
            return isSelected ? action.accentColor : action.accentColor.opacity(isAffordable ? 0.62 : 0.28)
        }()

        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(action.codeName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(isAffordable ? .white : Color.white.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if isSelected {
                    Text(isAffordable ? "SELECTED" : "不発注意")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(isAffordable ? .black : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            isAffordable ? action.accentColor : Color.cyberDanger,
                            in: Capsule()
                        )
                } else {
                    Text(subCaption)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(isAffordable ? action.accentColor.opacity(0.88) : Color.cyberDanger.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    CyberShape(cutSize: 10)
                        .fill(
                            isSelected
                                ? (isAffordable ? action.accentColor.opacity(0.28) : Color.cyberDanger.opacity(0.24))
                                : Color.black.opacity(0.52)
                        )

                    CyberShape(cutSize: 10)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.2 : 1.1)
                }
            )
            .shadow(
                color: isSelected ? borderColor.opacity(0.68) : .clear,
                radius: isSelected ? 8 : 0
            )
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
                CyberShape(cutSize: 13)
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
                CyberShape(cutSize: 13)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isGlowing ? 0.48 : 0.22),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // 金白の発光エッジ枠
                CyberShape(cutSize: 13)
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
                        lineWidth: 2.5
                    )

                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .black))
                    Text("ULTIMATE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .italic()
                        .tracking(4)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .black))
                }
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.45, green: 0.22, blue: 0.0), radius: 2, x: 0, y: 1.5)
                .shadow(color: Color.white.opacity(0.75), radius: isGlowing ? 8 : 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
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
