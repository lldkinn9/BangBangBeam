import SwiftUI

/// 画面2: バトルアリーナ画面 (BattleView)
struct BattleView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        ZStack {
            // MARK: 背景（サイバーパンク・グリッドグラデーション）
            LinearGradient(
                colors: [
                    Color.cyberBlack,
                    Color.cyberPanel,
                    Color.cyberBlack
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 3拍目激突時のフラッシュエフェクト
            if engine.beat == 3 {
                RadialGradient(
                    colors: [
                        Color.cyberCyan.opacity(0.22),
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

            // MARK: メインレイアウト
            VStack(spacing: 12) {
                headerBar

                cpuStatusPanel

                Spacer(minLength: 4)

                rhythmCenterStage

                if engine.gameMode == .practice {
                    practiceControlBar
                }

                Spacer(minLength: 4)

                playerControlPanel
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // MARK: 勝敗リザルトオーバーレイ
            if engine.outcome.isFinished {
                resultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: engine.outcome)
    }

    // MARK: - 1. Header Bar (◀ TITLE + Mode Info + Version)
    private var headerBar: some View {
        HStack {
            Button {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
                engine.returnToTitle()
            } label: {
                HStack(spacing: 4) {
                    Text("◀ TITLE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.cyberCyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: .cyberCyan,
                    secondaryColor: .cyberEmerald,
                    cutSize: 8,
                    fillOpacity: 0.16
                )
            )

            Spacer()

            VStack(spacing: 2) {
                Text(engine.gameMode.title)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Text("BPM \(Int(engine.bpm))")
                    if engine.targetWins > 1 {
                        Text("• \(engine.playerScore)-\(engine.cpuScore) (\(engine.targetWins)先取)")
                    } else {
                        Text("• TURN \(engine.turnCount)")
                    }
                }
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.cyberEmerald)
            }

            Spacer()

            // ヘッダー右側の小型バージョン表示
            Text(AppVersion.displayText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.65))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06), in: Capsule())
        }
        .padding(.top, 4)
    }

    // MARK: - 2. CPU Status Panel
    private var cpuStatusPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Label("ENEMY AI // NEO-CPU", systemImage: "cpu.fill")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.cyberDanger.opacity(0.9))
                Spacer()
                if engine.cpuCharge >= 2 {
                    Text("⚠️ MEGA READY")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.cyberAmber.opacity(0.18), in: Capsule())
                }
            }

            EnergyOrbView(
                label: "CPU CHARGE",
                currentCharge: engine.cpuCharge,
                maxCharge: engine.maxCharge,
                accentColor: .cyberCyan
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            // CPUアクション表示ボックス（3拍目でオープン）
            HStack(spacing: 10) {
                if let cpuAct = engine.revealedCpuAction, engine.beat == 3 {
                    Text(cpuAct.emoji)
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cpuAct.label)
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(cpuAct.accentColor)
                        Text(cpuAct.codeName)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                } else {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.cyberCyan.opacity(0.7))
                    Text("SYNCING TACTICS...")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(
                CyberShape(cutSize: 10)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        CyberShape(cutSize: 10)
                            .strokeBorder(Color.cyberCyan.opacity(0.32), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel.opacity(0.85))
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberCyan.opacity(0.35), lineWidth: 1.2)
                )
        )
    }

    // MARK: - 3. Center Rhythm Stage (3拍子インジケーター & コール)
    private var rhythmCenterStage: some View {
        VStack(spacing: 14) {
            // 3拍子ビートインジケーター (1: バン / 2: バン / 3: ビーム)
            HStack(spacing: 16) {
                ForEach(1...3, id: \.self) { step in
                    let isActive = engine.beat == step
                    let activeColor: Color = (step == 3) ? .cyberEmerald : .cyberCyan

                    VStack(spacing: 4) {
                        CyberShape(cutSize: 5)
                            .fill(isActive ? activeColor : Color.white.opacity(0.12))
                            .frame(width: 64, height: 10)
                            .shadow(color: isActive ? activeColor.opacity(0.9) : .clear, radius: 8)

                        Text(step == 3 ? "ACTION!" : "BEAT \(step)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(isActive ? activeColor : Color.white.opacity(0.4))
                    }
                }
            }

            // メインリズムコール（「せっせっせーの...」「💥 バン！」「⚡️ ビーム！」）
            Text(engine.calloutText)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(
                    color: (engine.beat == 3 ? Color.cyberEmerald : Color.cyberCyan).opacity(0.85),
                    radius: 14
                )
                .scaleEffect(engine.beat == 3 ? 1.08 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.6), value: engine.beat)
                .multilineTextAlignment(.center)

            // 激突サブテキスト / 自分の出した手との対比
            if engine.beat == 3,
               let pAct = engine.revealedPlayerAction,
               let cAct = engine.revealedCpuAction {
                HStack(spacing: 14) {
                    clashBadge(prefix: "YOU", action: pAct)
                    Text("VS")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan)
                    clashBadge(prefix: "CPU", action: cAct)
                }
            }

            Text(engine.statusDetailText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.cyberEmerald)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            CyberShape(cutSize: 16)
                .fill(Color.black.opacity(0.42))
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

    private func clashBadge(prefix: String, action: GameAction) -> some View {
        HStack(spacing: 6) {
            Text(prefix)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.65))
            Text("\(action.emoji) \(action.label)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(action.accentColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.07), in: Capsule())
    }

    // MARK: - 4. Practice Mode Control Bar (手動1拍進行 + 自動再生切替)
    private var practiceControlBar: some View {
        HStack(spacing: 12) {
            Button {
                engine.stepBeatManually()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "forward.frame.fill")
                    Text("1拍進める (NEXT BEAT)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: .cyberEmerald,
                    secondaryColor: .cyberCyan,
                    cutSize: 10,
                    fillOpacity: 0.34
                )
            )
            .disabled(engine.isPracticeAutoPlay || engine.outcome.isFinished)
            .opacity(engine.isPracticeAutoPlay ? 0.45 : 1.0)

            Button {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
                engine.isPracticeAutoPlay.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: engine.isPracticeAutoPlay ? "pause.fill" : "play.fill")
                    Text(engine.isPracticeAutoPlay ? "AUTO" : "MANUAL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(engine.isPracticeAutoPlay ? Color.cyberAmber : Color.cyberCyan)
                .frame(width: 92, height: 44)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: engine.isPracticeAutoPlay ? .cyberAmber : .cyberCyan,
                    secondaryColor: .cyberEmerald,
                    cutSize: 10,
                    fillOpacity: 0.2
                )
            )
        }
    }

    // MARK: - 5. Player Control Panel (気力オーブ & 4コマンドボタン)
    private var playerControlPanel: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return VStack(spacing: 12) {
            HStack {
                EnergyOrbView(
                    label: "YOUR CHARGE",
                    currentCharge: engine.playerCharge,
                    maxCharge: engine.maxCharge,
                    accentColor: .cyberEmerald
                )

                Spacer()

                // 予約中コマンド表示（気力不足時はお手つき警告色）
                let lacksEnergy = engine.playerCharge < engine.selectedAction.cost
                Text(lacksEnergy ? "⚠️ 気力不足: \(engine.selectedAction.label)" : "予約: \(engine.selectedAction.emoji)\(engine.selectedAction.label)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(lacksEnergy ? Color.cyberDanger : Color.cyberCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (lacksEnergy ? Color.cyberDanger : Color.cyberCyan).opacity(0.15),
                        in: Capsule()
                    )
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(GameAction.allCases) { action in
                    commandButton(for: action)
                }
            }
        }
        .padding(14)
        .background(
            CyberShape(cutSize: 14)
                .fill(Color.cyberPanel.opacity(0.9))
                .overlay(
                    CyberShape(cutSize: 14)
                        .strokeBorder(Color.cyberEmerald.opacity(0.4), lineWidth: 1.2)
                )
        )
    }

    private func commandButton(for action: GameAction) -> some View {
        let isSelected = engine.selectedAction == action
        let isAffordable = engine.playerCharge >= action.cost
        let borderColor: Color = {
            if isSelected && !isAffordable {
                return .cyberDanger
            }
            return isSelected ? action.accentColor : action.accentColor.opacity(isAffordable ? 0.55 : 0.25)
        }()

        return Button {
            engine.selectCommand(action)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(action.emoji)
                        .font(.system(size: 20))
                    Text(action.label)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(isAffordable ? .white : Color.white.opacity(0.55))
                    Spacer()
                }

                HStack {
                    Text(action.costBadge)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(isAffordable ? action.accentColor : Color.cyberDanger.opacity(0.85))

                    Spacer()

                    if isSelected {
                        Text("SELECTED")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(isAffordable ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                isAffordable ? action.accentColor : Color.cyberDanger,
                                in: Capsule()
                            )
                    } else if action == .megaBeam && isAffordable {
                        Text("READY!")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberAmber)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(
                ZStack {
                    CyberShape(cutSize: 12)
                        .fill(
                            isSelected
                                ? (isAffordable ? action.accentColor.opacity(0.28) : Color.cyberDanger.opacity(0.24))
                                : Color.black.opacity(0.5)
                        )

                    CyberShape(cutSize: 12)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.4 : 1.2)
                }
            )
            .shadow(
                color: isSelected ? borderColor.opacity(0.65) : .clear,
                radius: isSelected ? 10 : 0
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 6. Result Overlay (勝敗決着モーダル)
    private var resultOverlay: some View {
        let isWin: Bool = {
            if case .playerWin = engine.outcome { return true }
            return false
        }()

        let headline: String = {
            switch engine.outcome {
            case .ongoing:
                return ""
            case .playerWin:
                return "YOU WIN"
            case .playerLose(_, let isFoul):
                return isFoul ? "FOUL LOSE" : "YOU LOSE"
            }
        }()

        let detail: String = {
            switch engine.outcome {
            case .ongoing:
                return ""
            case .playerWin(let reason):
                return reason
            case .playerLose(let reason, _):
                return reason
            }
        }()

        let accent: Color = isWin ? .cyberEmerald : .cyberDanger

        return ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(headline)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .italic()
                    .tracking(3)
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.9), radius: 16)

                Text(detail)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    Button {
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        engine.rematch()
                    } label: {
                        Text("PLAY AGAIN")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .frame(width: 230, height: 50)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberEmerald,
                            secondaryColor: .cyberCyan,
                            cutSize: 12,
                            fillOpacity: 0.35
                        )
                    )

                    Button {
                        HapticManager.playLight(enabled: engine.isHapticsEnabled)
                        engine.returnToTitle()
                    } label: {
                        Text("◀ TITLE")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Color.cyberCyan)
                            .frame(width: 230, height: 44)
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
                .padding(.top, 6)
            }
            .padding(28)
            .background(
                CyberShape(cutSize: 18)
                    .fill(Color.cyberPanel)
                    .overlay(
                        CyberShape(cutSize: 18)
                            .strokeBorder(accent, lineWidth: 2)
                    )
            )
            .shadow(color: accent.opacity(0.5), radius: 24)
            .padding(.horizontal, 28)
        }
    }
}
