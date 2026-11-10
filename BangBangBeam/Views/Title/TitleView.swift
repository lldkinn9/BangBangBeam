import SwiftUI

/// 画面1: タイトル画面 (TitleView)
struct TitleView: View {
    @Bindable var engine: GameEngine
    @Bindable private var itemManager = ItemManager.shared
    @Bindable private var lang = LanguageManager.shared

    @State private var isMenuExpanded: Bool = false
    @State private var isShowingItemSheet: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var isShowingRankingSheet: Bool = false
    @State private var isPulsing: Bool = false

    var body: some View {
        ZStack {
            // MARK: 1. 最上部・最下部のみの薄いグラデーション（キャラクターを遮らない）
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.62),
                        Color.black.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)

                Spacer()

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.28),
                        Color.black.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // MARK: 2. STARTタップ時の黒スモークオーバーレイ (Color.black.opacity(0.72))
            if isMenuExpanded {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            isMenuExpanded = false
                        }
                    }
            }

            // MARK: 3. メインUIレイヤー
            VStack(spacing: 0) {
                // ヘッダー: 自己ベスト連勝バッジ + 小型バージョン表示
                HStack {
                    if GameCenterManager.shared.bestWinStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.cyberAmber)
                            Text("BEST \(GameCenterManager.shared.bestWinStreak)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.5), in: Capsule())
                    }

                    Spacer()

                    Text(AppVersion.displayText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.45), in: Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)

                // 上部ロゴ: 少年の頭上の夜空エリアに配置
                Text("BANG BANG BEAM")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .italic()
                    .tracking(2.2)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyberCyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.cyberCyan.opacity(0.95), radius: 8, x: 0, y: 0)
                    .shadow(color: Color.cyberCyan.opacity(0.75), radius: 18, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.85), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                Spacer()

                if isMenuExpanded {
                    modeMenuPanel
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.94)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            )
                        )
                        .padding(.bottom, 22)
                } else {
                    startButton
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .padding(.bottom, 18)
                }
            }
        }
        .background {
            Image("Title")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingItemSheet) {
            ItemShopSheetView(engine: engine)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingSheetView(engine: engine)
        }
        .sheet(isPresented: $isShowingRankingSheet) {
            RankingInfoSheetView()
        }
        .onAppear {
            isMenuExpanded = false
            SoundManager.shared.playTitleBGM()
            HapticManager.warmUp(enabled: engine.isHapticsEnabled)
            AssetPrewarmer.warmUpForInitialLaunch(startingStreak: engine.winStreak)
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - Compact START Button (Width: 220px on Center Road)
    private var startButton: some View {
        Button {
            SoundManager.shared.playButtonSE()
            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
            withAnimation(.easeInOut(duration: 0.30)) {
                isMenuExpanded = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("START")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .tracking(4)
            }
            .foregroundStyle(.white)
            .frame(width: 220, height: 52)
            .background(
                ZStack {
                    CyberShape(cutSize: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyberEmerald.opacity(isPulsing ? 0.88 : 0.68),
                                    Color.cyberCyan.opacity(isPulsing ? 0.92 : 0.72)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    CyberShape(cutSize: 15)
                        .fill(Color.black.opacity(0.22))

                    CyberShape(cutSize: 15)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .cyberCyan, .cyberEmerald],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                }
            )
            .clipShape(CyberShape(cutSize: 15))
            .shadow(
                color: Color.cyberEmerald.opacity(isPulsing ? 0.85 : 0.35),
                radius: isPulsing ? 18 : 8
            )
            .shadow(
                color: Color.cyberCyan.opacity(isPulsing ? 0.85 : 0.40),
                radius: isPulsing ? 24 : 10
            )
            .scaleEffect(isPulsing ? 1.03 : 0.98)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode Selection Menu
    private var modeMenuPanel: some View {
        let _ = lang.language
        let equippedItemName = (itemManager.activeRunCarryInItem ?? itemManager.selectedCarryInItem)?.displayName
        let itemBadgeText: String = {
            if let equippedItemName {
                return L10n("\(equippedItemName) 装備中", "\(equippedItemName) EQUIPPED")
            }
            return "\(itemManager.points) PT"
        }()

        return VStack(spacing: 10) {
            // ① KUMITE
            modeButton(
                title: "KUMITE",
                subtitle: L10n("勝ち抜きサバイバル（ランキング対象）", "Survival Mode (World Ranked)"),
                systemImage: "flame.fill",
                primary: .cyberCyan,
                secondary: .cyberEmerald,
                topTrailingBadge: (engine.hasSavedKumiteSession && engine.winStreak > 0)
                    ? L10n("\(engine.winStreak)連勝中", "\(engine.winStreak) WINS")
                    : nil
            ) {
                engine.startOrResumeKumite()
            }

            // ② ITEM
            modeButton(
                title: "ITEM",
                subtitle: L10n("ポイント交換・持ち込みアイテム設定", "Point Exchange & Item Loadout"),
                systemImage: "shippingbox.fill",
                primary: .cyberEmerald,
                secondary: .cyberCyan,
                topTrailingBadge: itemBadgeText
            ) {
                isShowingItemSheet = true
            }

            // ③ RANKING
            modeButton(
                title: "RANKING",
                subtitle: L10n("世界ランキング", "World Leaderboard"),
                systemImage: "trophy.fill",
                primary: .cyberAmber,
                secondary: .cyberCyan
            ) {
                isShowingRankingSheet = true
            }

            // ④ SETTING
            modeButton(
                title: "SETTING",
                subtitle: L10n("各種設定", "Audio, Tempo, Language & Rules"),
                systemImage: "slider.horizontal.3",
                primary: Color.white.opacity(0.85),
                secondary: .cyberCyan
            ) {
                isShowingSettings = true
            }

            // ④ ✕ BACK
            Button {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
                withAnimation(.easeInOut(duration: 0.28)) {
                    isMenuExpanded = false
                }
            } label: {
                Text("✕ BACK")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 150, height: 38)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: Color.white.opacity(0.55),
                    secondaryColor: Color.cyberCyan.opacity(0.55),
                    cutSize: 9,
                    fillOpacity: 0.12
                )
            )
            .padding(.top, 2)
        }
        .padding(.horizontal, 26)
    }

    private func modeButton(
        title: String,
        subtitle: String,
        systemImage: String,
        primary: Color,
        secondary: Color,
        topTrailingBadge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SoundManager.shared.playButtonSE()
            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primary)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: 320)
            .frame(height: 58)
        }
        .buttonStyle(
            CyberButtonStyle(
                primaryColor: primary,
                secondaryColor: secondary,
                cutSize: 13,
                fillOpacity: 0.28
            )
        )
        .overlay(alignment: .topTrailing) {
            if let topTrailingBadge {
                Text(topTrailingBadge)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.cyberAmber)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.cyberAmber.opacity(0.75), radius: 6)
                    .offset(x: -8, y: -9)
                    .allowsHitTesting(false)
            }
        }
    }
}
