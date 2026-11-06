import SwiftUI

/// 製品版バトルアリーナ画面（KUMITE 11人勝ち抜き戦：立ち絵表情・HP3・4チャージ・手イラスト・必殺カットイン＆動画対応）
struct BattleView: View {
    @Bindable var engine: GameEngine
    @State private var isShowingRankingFallback: Bool = false

    var body: some View {
        ZStack {
            // MARK: 背景グラデーション
            LinearGradient(
                colors: [Color.cyberBlack, Color.cyberPanel, Color.cyberBlack],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if engine.beat == 3 {
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

    // MARK: - 1. Header Bar
    private var headerBar: some View {
        HStack {
            Button {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
                engine.returnToTitle()
            } label: {
                Text("◀ TITLE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.cyberCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: .cyberCyan,
                    secondaryColor: .cyberEmerald,
                    cutSize: 7,
                    fillOpacity: 0.16
                )
            )

            Spacer()

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

            Spacer()

            Text(AppVersion.displayText)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.65))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06), in: Capsule())
        }
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

            VStack(alignment: .leading, spacing: 7) {
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

                Text(engine.currentEnemy.titleLabel)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(1)

                HStack {
                    EnergyOrbView(
                        label: "CHARGE",
                        currentCharge: engine.cpuCharge,
                        maxCharge: engine.maxCharge,
                        accentColor: .cyberCyan
                    )
                    Spacer()
                    if engine.cpuCharge >= engine.maxCharge {
                        Text("⚠️ 必殺READY")
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

    // MARK: - 3. Center Hands & Rhythm Stage
    private var handsArenaStage: some View {
        VStack(spacing: 8) {
            // 3拍子ビートバー
            HStack(spacing: 14) {
                ForEach(1...3, id: \.self) { step in
                    let isActive = engine.beat == step
                    let activeColor: Color = (step == 3) ? .cyberEmerald : .cyberCyan

                    VStack(spacing: 3) {
                        CyberShape(cutSize: 4)
                            .fill(isActive ? activeColor : Color.white.opacity(0.12))
                            .frame(width: 62, height: 8)
                            .shadow(color: isActive ? activeColor.opacity(0.9) : .clear, radius: 6)

                        Text(step == 3 ? "ACTION!" : "BEAT \(step)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(isActive ? activeColor : Color.white.opacity(0.38))
                    }
                }
            }

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
                .foregroundStyle(Color.cyberEmerald)
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
                                colors: [Color.cyberCyan.opacity(0.5), Color.cyberEmerald.opacity(0.5)],
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

    // MARK: - 4. Player (Reo) Status & Command Buttons
    private var playerControlCard: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return VStack(spacing: 10) {
            // Reo ステータス行
            HStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    CyberShape(cutSize: 8)
                        .fill(Color.cyberEmerald.opacity(0.2))

                    Image(CharacterProfile.reo.standingAsset(for: engine.playerExpression))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 64)

                    CyberShape(cutSize: 8)
                        .strokeBorder(Color.cyberEmerald.opacity(0.6), lineWidth: 1)
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

                        let lacksEnergy = engine.playerCharge < engine.selectedAction.cost
                        Text(lacksEnergy ? "⚠️お手つき注意" : "予約:\(engine.selectedAction.emoji)\(engine.selectedAction.label)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(lacksEnergy ? Color.cyberDanger : Color.cyberCyan)
                    }
                }
            }

            // 4コマンドボタン
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(GameAction.allCases) { action in
                    BattleCommandButton(
                        action: action,
                        isSelected: engine.selectedAction == action,
                        playerCharge: engine.playerCharge
                    ) {
                        engine.selectCommand(action)
                    }
                }
            }
        }
        .padding(12)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel.opacity(0.92))
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberEmerald.opacity(0.42), lineWidth: 1.2)
                )
        )
    }

    // MARK: - 5. KUMITE Result Overlay (Stage Clear / Game Over + Retry Ad + World Ranking)
    private var kumiteResultOverlay: some View {
        let isStageClear: Bool = {
            if case .stageClear = engine.outcome { return true }
            return false
        }()

        let accent: Color = isStageClear ? .cyberEmerald : .cyberDanger
        let nextEnemyInfo = CharacterProfile.enemy(forStreak: engine.winStreak)

        return ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(isStageClear ? "STAGE CLEAR!!" : "DEFEATED...")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .italic()
                    .tracking(2)
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.9), radius: 14)

                if case .stageClear(_, let reason) = engine.outcome {
                    Text(reason)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 4) {
                        Text("🔥 現在 \(engine.winStreak) 連勝中！")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color.cyberAmber)
                        Text("次戦: \(nextEnemyInfo.profile.codeName)（ReoのHPは3に全回復します）")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    .padding(.vertical, 6)

                    Button {
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        engine.advanceToNextKumiteStage()
                    } label: {
                        Text("NEXT BATTLE ▶")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 52)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberEmerald,
                            secondaryColor: .cyberCyan,
                            cutSize: 12,
                            fillOpacity: 0.38
                        )
                    )
                } else if case .gameOver(let finalStreak, let reason) = engine.outcome {
                    Text(reason)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 4) {
                        Text("今回の記録: \(finalStreak) 連勝")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Color.cyberCyan)
                        Text("自己ベスト: \(GameCenterManager.shared.bestWinStreak) 連勝")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)
                    }
                    .padding(.vertical, 4)

                    // リトライボタン（2〜3回ごとにスキップ可能な全画面広告を表示後に再開）
                    Button {
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        AdManager.shared.handleRetryWithAdIfNeeded {
                            engine.startKumiteFromBeginning()
                        }
                    } label: {
                        Text("RETRY (最初から挑戦)")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 50)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberEmerald,
                            secondaryColor: .cyberCyan,
                            cutSize: 12,
                            fillOpacity: 0.36
                        )
                    )

                    Button {
                        HapticManager.playLight(enabled: engine.isHapticsEnabled)
                        if !GameCenterManager.shared.presentWorldRanking() {
                            isShowingRankingFallback = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                            Text("WORLD RANKING")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.cyberAmber)
                        .frame(width: 240, height: 42)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberAmber,
                            secondaryColor: .cyberCyan,
                            cutSize: 10,
                            fillOpacity: 0.18
                        )
                    )
                }

                Button {
                    HapticManager.playLight(enabled: engine.isHapticsEnabled)
                    engine.returnToTitle()
                } label: {
                    Text("◀ TITLE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color.cyberCyan)
                        .frame(width: 240, height: 42)
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
            .padding(24)
            .background(
                CyberShape(cutSize: 18)
                    .fill(Color.cyberPanel)
                    .overlay(
                        CyberShape(cutSize: 18)
                            .strokeBorder(accent, lineWidth: 2)
                    )
            )
            .shadow(color: accent.opacity(0.5), radius: 24)
            .padding(.horizontal, 24)
        }
    }
}

/// 共通のサイバーコマンド選択ボタン（BattleView / PracticeTutorialView 共用）
struct BattleCommandButton: View {
    let action: GameAction
    let isSelected: Bool
    let playerCharge: Int
    let onTap: () -> Void

    var body: some View {
        let isAffordable = playerCharge >= action.cost
        let borderColor: Color = {
            if isSelected && !isAffordable {
                return .cyberDanger
            }
            return isSelected ? action.accentColor : action.accentColor.opacity(isAffordable ? 0.6 : 0.25)
        }()

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(action.emoji)
                        .font(.system(size: 18))
                    Text(action.label)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(isAffordable ? .white : Color.white.opacity(0.5))
                    Spacer()
                }

                HStack {
                    Text(action.costBadge)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(isAffordable ? action.accentColor : Color.cyberDanger.opacity(0.85))

                    Spacer()

                    if isSelected {
                        Text(isAffordable ? "SET" : "不発注意")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(isAffordable ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                isAffordable ? action.accentColor : Color.cyberDanger,
                                in: Capsule()
                            )
                    } else if action == .megaBeam && isAffordable {
                        Text("一撃必殺OK!")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)
                    }
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    CyberShape(cutSize: 11)
                        .fill(
                            isSelected
                                ? (isAffordable ? action.accentColor.opacity(0.28) : Color.cyberDanger.opacity(0.24))
                                : Color.black.opacity(0.5)
                        )

                    CyberShape(cutSize: 11)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.2 : 1.1)
                }
            )
            .shadow(
                color: isSelected ? borderColor.opacity(0.65) : .clear,
                radius: isSelected ? 8 : 0
            )
        }
        .buttonStyle(.plain)
    }
}
