import SwiftUI

/// 画面1: タイトル画面 (TitleView)
struct TitleView: View {
    @Bindable var engine: GameEngine

    @State private var isMenuExpanded: Bool = false
    @State private var isShowingSettings: Bool = false
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
                        Color.black.opacity(0.68)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
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
                // ヘッダー右上の小型バージョン表示
                HStack {
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

                // 上部ロゴ: 少年の頭上の夜空エリアに配置（余計なサブテキストは入れない）
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

                // 中央〜下部エリア: 初期STARTボタン または 展開後のモード選択メニュー
                if isMenuExpanded {
                    modeMenuPanel
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.94)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            )
                        )
                        .padding(.bottom, 56)
                } else {
                    startButton
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .padding(.bottom, 34)
                }
            }
        }
        // 背景画像 "Title" を全画面表示（レイアウト幅に影響させないため .background に配置）
        .background {
            Image("Title")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingSheetView(engine: engine)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - Compact START Button (Width: 220px on Center Road)
    private var startButton: some View {
        Button {
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
            .frame(width: 220, height: 54)
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

    // MARK: - Mode Selection Menu (Shown over Smoke Overlay)
    private var modeMenuPanel: some View {
        VStack(spacing: 16) {
            // ① KUMITE
            modeButton(
                title: "KUMITE",
                subtitle: "1vs1 CPU対戦（勝負制）",
                systemImage: "flame.fill",
                primary: .cyberCyan,
                secondary: .cyberEmerald
            ) {
                isMenuExpanded = false
                engine.startBattle(mode: .kumite)
            }

            // ② PRACTICE
            modeButton(
                title: "PRACTICE",
                subtitle: "1拍ずつ手動で進められる練習モード",
                systemImage: "metronome.fill",
                primary: .cyberEmerald,
                secondary: .cyberCyan
            ) {
                isMenuExpanded = false
                engine.startBattle(mode: .practice)
            }

            // ③ SETTING
            modeButton(
                title: "SETTING",
                subtitle: "BPM速度・ルール設定",
                systemImage: "slider.horizontal.3",
                primary: Color.white.opacity(0.85),
                secondary: .cyberCyan
            ) {
                HapticManager.playLight(enabled: engine.isHapticsEnabled)
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
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 160, height: 42)
            }
            .buttonStyle(
                CyberButtonStyle(
                    primaryColor: Color.white.opacity(0.55),
                    secondaryColor: Color.cyberCyan.opacity(0.55),
                    cutSize: 10,
                    fillOpacity: 0.12
                )
            )
            .padding(.top, 6)
        }
        .padding(.horizontal, 28)
    }

    private func modeButton(
        title: String,
        subtitle: String,
        systemImage: String,
        primary: Color,
        secondary: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.playMedium(enabled: engine.isHapticsEnabled)
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(primary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(primary)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 310)
            .frame(height: 66)
        }
        .buttonStyle(
            CyberButtonStyle(
                primaryColor: primary,
                secondaryColor: secondary,
                cutSize: 14,
                fillOpacity: 0.28
            )
        )
    }
}
