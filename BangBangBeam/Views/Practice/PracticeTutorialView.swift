import SwiftUI

/// PRACTICEモード専用UI（初回アプリ起動時の自動チュートリアル ＆ 手動/自動フリー実戦練習）
struct PracticeTutorialView: View {
    @Bindable var engine: GameEngine

    private enum PracticeTab: String, CaseIterable {
        case guide = "📘 ルール学習"
        case sparring = "🎯 フリー実戦"
    }

    @State private var selectedTab: PracticeTab = .guide
    @State private var lessonStep: Int = 0
    @State private var showDemoUltimate: Bool = false

    private struct LessonItem {
        let badge: String
        let title: String
        let body: String
        let handAsset: String
        let highlightTip: String
    }

    private let lessons: [LessonItem] = [
        LessonItem(
            badge: "STEP 1 / 5",
            title: "3拍子のリズムに乗ろう！",
            body: "バンバンビームは「パン！(1拍目) → パン！(2拍目) → アクション！(3拍目)」の3拍子リズムバトルです。\n\n1拍目・2拍目の手拍子の間に、次の3拍目で出すコマンドボタンをタップして予約しましょう！",
            handAsset: "hand_clap",
            highlightTip: "💡 コツ：焦らず1・2拍目の間にボタンを1回タップするだけで予約できます。"
        ),
        LessonItem(
            badge: "STEP 2 / 5",
            title: "⚡️チャージ と 💥通常ビーム",
            body: "最初は気力（チャージ）が 0 です。まずは「⚡️チャージ」で気力を溜めましょう。\n\n気力を 1 消費して「💥ビーム」を撃ち、無防備な相手に命中すると【相手のHP -1】さらに【相手が溜めていたチャージも -1】削ることができます！",
            handAsset: "hand_beam",
            highlightTip: "💡 体力は3ライフ制！通常ビームを3回当てれば撃破勝利です。"
        ),
        LessonItem(
            badge: "STEP 3 / 5",
            title: "🛡️バリア と 💦お手つき無防備",
            body: "相手に気力がある時は「🛡️バリア（消費0）」で通常ビームをノーダメージで防げます！\n\n⚠️注意：気力が足りないのにビーム等を押して3拍目を迎えると「お手つき（不発）」となり、チャージも増えずガードもない【完全無防備状態】になります！",
            handAsset: "hand_barrier",
            highlightTip: "💡 お手つき中に相手のビームが来ると直撃ダメージを受けます。残りの気力をよく見よう！"
        ),
        LessonItem(
            badge: "STEP 4 / 5",
            title: "🌟 4チャージで一撃必殺！！",
            body: "気力を【4回チャージ】すると、超必殺技「🌟必殺ビーム」が解放されます！\n\n通常のバリアすら粉砕し、相手の残りHPに関係なくカットイン＆必殺アニメと共に【一撃必殺】で勝利が決まります！",
            handAsset: "hand_charge",
            highlightTip: "👇 下の「必殺演出をプレビュー」ボタンで実際の迫力を体験できます！"
        ),
        LessonItem(
            badge: "STEP 5 / 5",
            title: "準備完了！KUMITEへ挑め！",
            body: "メインモード「KUMITE」では、主人公 Reo となって11人の個性豊かな敵たちと順番に勝ち抜き戦を行います。\n\n敵を1人倒すごとにHPは3に全回復！連勝記録を伸ばして世界ランキング頂点を目指しましょう！",
            handAsset: "hand_beam",
            highlightTip: "🔥 上の「🎯 フリー実戦」タブで1拍ずつ手動練習することもできます！"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.cyberBlack, Color.cyberPanel, Color.cyberBlack],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                topHeader

                // モード切替タブ
                Picker("練習モード切替", selection: $selectedTab) {
                    ForEach(PracticeTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                if selectedTab == .guide {
                    guidedLessonBody
                } else {
                    freeSparringBody
                }
            }
            .padding(.bottom, 10)

            // Step 4 の必殺プレビュー または フリー実戦の必殺演出
            if showDemoUltimate {
                UltimateCutinOverlayView(character: .reo, isPlayer: true) {
                    showDemoUltimate = false
                }
                .zIndex(15)
            }

            if let ult = engine.activeUltimate {
                UltimateCutinOverlayView(character: ult.character, isPlayer: ult.isPlayer) {
                    engine.completeUltimateSequence()
                }
                .zIndex(16)
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .guide {
                engine.isPracticeAutoPlay = false
                engine.stopTimer()
            }
        }
    }

    // MARK: - Header
    private var topHeader: some View {
        ZStack {
            HStack {
                Button {
                    HapticManager.playLight(enabled: engine.isHapticsEnabled)
                    engine.returnToTitle()
                } label: {
                    Text(engine.isFirstLaunchTutorial ? "SKIP ▶ TITLE" : "◀ TITLE")
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
            }

            VStack(spacing: 1) {
                Text("PRACTICE // ACADEMY")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text(engine.isFirstLaunchTutorial ? "初回チュートリアル" : "ルール確認＆実戦トレーニング")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.cyberEmerald)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    // MARK: - Tab 1: Guided Interactive Lesson UI
    private var guidedLessonBody: some View {
        let item = lessons[lessonStep]

        return VStack(spacing: 14) {
            // 進捗ドット
            HStack(spacing: 8) {
                ForEach(0..<lessons.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx == lessonStep ? Color.cyberCyan : (idx < lessonStep ? Color.cyberEmerald : Color.white.opacity(0.18)))
                        .frame(width: idx == lessonStep ? 28 : 12, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: lessonStep)
                }
            }
            .padding(.top, 4)

            // レッスンメインカード
            ScrollView {
                VStack(spacing: 16) {
                    // ナビゲーター Reo + 手イラスト実演ヘッダー
                    HStack(spacing: 16) {
                        Image(CharacterProfile.reo.standingAsset(for: lessonStep == 4 ? .fun : .normal))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 116)
                            .shadow(color: Color.cyberEmerald.opacity(0.6), radius: 10)

                        Image(item.handAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 104)
                            .shadow(color: Color.cyberCyan.opacity(0.8), radius: 12)
                    }
                    .padding(.top, 6)

                    Text(item.badge)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.cyberCyan, in: Capsule())

                    Text(item.title)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(item.body)
                        .font(.system(size: 14, weight: .medium))
                        .lineSpacing(4)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.highlightTip)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cyberEmerald)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cyberEmerald.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                    if lessonStep == 3 {
                        Button {
                            HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                            showDemoUltimate = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles.tv.fill")
                                Text("必殺カットイン＆アニメ演出をプレビュー")
                            }
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.cyberAmber, in: Capsule())
                            .shadow(color: Color.cyberAmber.opacity(0.8), radius: 10)
                        }
                    }
                }
                .padding(18)
            }
            .background(
                CyberShape(cutSize: 16)
                    .fill(Color.cyberPanel.opacity(0.9))
                    .overlay(
                        CyberShape(cutSize: 16)
                            .strokeBorder(Color.cyberCyan.opacity(0.42), lineWidth: 1.4)
                    )
            )
            .padding(.horizontal, 16)

            // 下部ナビゲーションボタン
            HStack(spacing: 12) {
                if lessonStep > 0 {
                    Button {
                        HapticManager.playLight(enabled: engine.isHapticsEnabled)
                        withAnimation { lessonStep -= 1 }
                    } label: {
                        Text("◀ 戻る")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 96, height: 48)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: Color.white.opacity(0.5),
                            secondaryColor: .cyberCyan,
                            cutSize: 10,
                            fillOpacity: 0.14
                        )
                    )
                }

                if lessonStep < lessons.count - 1 {
                    Button {
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        withAnimation { lessonStep += 1 }
                    } label: {
                        Text("次へ進む ▶")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberCyan,
                            secondaryColor: .cyberEmerald,
                            cutSize: 12,
                            fillOpacity: 0.34
                        )
                    )
                } else {
                    Button {
                        HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                        selectedTab = .sparring
                    } label: {
                        Text("🎯 練習してみる")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberCyan,
                            secondaryColor: .cyberEmerald,
                            cutSize: 10,
                            fillOpacity: 0.25
                        )
                    )

                    Button {
                        HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                        engine.startKumiteFromBeginning()
                    } label: {
                        Text("🔥 KUMITE開始")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(
                        CyberButtonStyle(
                            primaryColor: .cyberEmerald,
                            secondaryColor: .cyberCyan,
                            cutSize: 10,
                            fillOpacity: 0.42
                        )
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab 2: Interactive Sparring Sandbox (1拍ずつ手動進行 / AUTO練習)
    private var freeSparringBody: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return VStack(spacing: 8) {
            // 練習相手ステータスバー
            HStack {
                Text("練習相手: GEEK")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                HealthBarView(currentHP: engine.cpuHP, maxHP: engine.maxHP, accentColor: .cyberDanger)
                Spacer()
                EnergyOrbView(label: "敵", currentCharge: engine.cpuCharge, maxCharge: engine.maxCharge, accentColor: .cyberCyan)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.cyberPanel.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)

            // 中央リズム＆手イラスト確認パネル
            VStack(spacing: 6) {
                if engine.beat == 1 || engine.beat == 2 {
                    Image("hand_clap")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 92)
                } else if engine.beat == 3, let pMove = engine.revealedPlayerMove {
                    if let hAsset = pMove.handAssetName {
                        Image(hAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 92)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.cyberDanger)
                            .frame(height: 92)
                    }
                } else {
                    Image("hand_clap")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 82)
                        .opacity(0.5)
                }

                Text(engine.calloutText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(engine.statusDetailText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cyberEmerald)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 14)

            // 手動1拍進行 ＆ AUTO切替 ＆ リセットバー
            HStack(spacing: 8) {
                if engine.outcome.isFinished {
                    Button {
                        engine.resetPracticeSparring()
                    } label: {
                        Text("🔄 もう一度練習する")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .buttonStyle(
                        CyberButtonStyle(primaryColor: .cyberEmerald, secondaryColor: .cyberCyan, cutSize: 10, fillOpacity: 0.35)
                    )
                } else {
                    Button {
                        engine.stepBeatManually()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.frame.fill")
                            Text("1拍進める (NEXT BEAT)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                    }
                    .buttonStyle(
                        CyberButtonStyle(primaryColor: .cyberEmerald, secondaryColor: .cyberCyan, cutSize: 10, fillOpacity: 0.34)
                    )
                    .disabled(engine.isPracticeAutoPlay)
                    .opacity(engine.isPracticeAutoPlay ? 0.45 : 1.0)
                }

                Button {
                    engine.isPracticeAutoPlay.toggle()
                } label: {
                    Text(engine.isPracticeAutoPlay ? "⏸ AUTO" : "▶ MANUAL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(engine.isPracticeAutoPlay ? Color.cyberAmber : Color.cyberCyan)
                        .frame(width: 88, height: 42)
                }
                .buttonStyle(
                    CyberButtonStyle(
                        primaryColor: engine.isPracticeAutoPlay ? .cyberAmber : .cyberCyan,
                        secondaryColor: .cyberEmerald,
                        cutSize: 9,
                        fillOpacity: 0.18
                    )
                )
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 0)

            // プレイヤーコマンドパネル
            VStack(spacing: 8) {
                HStack {
                    Text("REO")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                    HealthBarView(currentHP: engine.playerHP, maxHP: engine.maxHP, accentColor: .cyberEmerald)
                    Spacer()
                    EnergyOrbView(label: "気力", currentCharge: engine.playerCharge, maxCharge: engine.maxCharge, accentColor: .cyberEmerald)
                }

                LazyVGrid(columns: columns, spacing: 8) {
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
            .background(Color.cyberPanel.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 14)
        }
    }
}
