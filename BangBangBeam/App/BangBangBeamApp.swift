import SwiftUI

@main
struct BangBangBeamApp: App {
    @State private var engine = GameEngine()

    var body: some Scene {
        WindowGroup {
            RootContainerView(engine: engine)
                .preferredColorScheme(.dark)
        }
    }
}

/// アプリ全体の画面遷移・非プレイ画面の共通バナー広告・敗退保留からの復活確認ポップアップ・リワード広告フォールバックを統括するルートビュー
struct RootContainerView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared

    var body: some View {
        ZStack {
            Color.cyberBlack
                .ignoresSafeArea()

            Group {
                switch engine.currentScreen {
                case .title:
                    // バナーのsafeAreaInsetをTitleView側のみに限定し、BattleView遷移中の画面高さ再レイアウト負荷をゼロにする
                    TitleView(engine: engine)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if engine.currentScreen.showsBottomBannerAd {
                                AdBannerFooterView()
                            }
                        }
                        .transition(.opacity)

                case .kumiteBattle:
                    BattleView(engine: engine)
                        .transition(.opacity)

                case .practiceTutorial:
                    PracticeTutorialView(engine: engine)
                        .transition(.opacity)
                }
            }

            // 敗退後に復活回数を残してタイトルへ戻った状態から「KUMITE」を押した際の確認ポップアップ
            if engine.isShowingPendingRevivePrompt {
                PendingRevivePromptOverlayView(engine: engine)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(45)
            }

            // GoogleMobileAds SDK 未リンク時の復活リワード動画広告タイミング確認オーバーレイ
            if adManager.isPresentingFallbackRewardedAd {
                FallbackRewardedAdOverlayView(
                    onRewardComplete: {
                        adManager.completeFallbackRewardedAd()
                    },
                    onCancel: {
                        adManager.cancelFallbackRewardedAd()
                    }
                )
                .transition(.opacity)
                .zIndex(50)
            }
        }
        .animation(.easeOut(duration: 0.20), value: engine.currentScreen)
        .animation(.easeOut(duration: 0.18), value: engine.isShowingPendingRevivePrompt)
        .onAppear {
            engine.onAppAppear()
        }
    }
}

/// 敗退後に復活回数を残してタイトルへ戻っていた場合、次回「KUMITE」押下時に表示する確認ポップアップ
private struct PendingRevivePromptOverlayView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.isShowingPendingRevivePrompt = false
                }

            VStack(spacing: 16) {
                Text("KUMITE 再開確認")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .italic()
                    .tracking(1.5)
                    .foregroundStyle(Color.cyberAmber)
                    .shadow(color: Color.cyberAmber.opacity(0.75), radius: 10)

                VStack(spacing: 6) {
                    Text("保持中の記録：\(engine.winStreak) 連勝")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Color.cyberCyan)

                    Text("前回敗退時の連勝記録が残っています。\n動画広告を見て連勝を継続するか、最初から挑戦するか選択してください。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 4)

                // 選択肢1: 動画広告を見て復活（連勝継続）
                Button {
                    HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                    adManager.presentRewardedAdForRevive {
                        engine.reviveCurrentKumiteMatch()
                    }
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.tv.fill")
                            Text(adManager.isLoadingRewardedAd ? "動画広告を読み込み中..." : "動画広告を見て復活（連勝継続）")
                        }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(.white)

                        Text("\(engine.winStreak)連勝を維持して再戦（復活残り \(engine.remainingRevives) / \(engine.maxRevivesPerRun) 回）")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.cyberAmber)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
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

                // 選択肢2: 最初から挑戦（0連勝）
                Button {
                    HapticManager.playMedium(enabled: engine.isHapticsEnabled)
                    engine.startKumiteFromBeginning()
                } label: {
                    Text("最初から挑戦（0連勝）")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(
                    CyberButtonStyle(
                        primaryColor: .cyberEmerald,
                        secondaryColor: .cyberCyan,
                        cutSize: 12,
                        fillOpacity: 0.26
                    )
                )

                // キャンセル（タイトルへ戻る・記録はそのまま保持）
                Button {
                    HapticManager.playLight(enabled: engine.isHapticsEnabled)
                    engine.isShowingPendingRevivePrompt = false
                } label: {
                    Text("✕ キャンセル")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                CyberShape(cutSize: 18)
                    .fill(Color.cyberPanel)
                    .overlay(
                        CyberShape(cutSize: 18)
                            .strokeBorder(Color.cyberAmber, lineWidth: 2)
                    )
            )
            .shadow(color: Color.cyberAmber.opacity(0.45), radius: 24)
            .padding(.horizontal, 20)
        }
    }
}
