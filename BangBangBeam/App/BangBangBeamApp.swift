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

/// アプリ全体の画面遷移・初回起動時の言語選択・非プレイ画面の共通バナー広告・敗退保留からの復活確認ポップアップを統括するルートビュー
struct RootContainerView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared
    @Bindable private var languageManager = LanguageManager.shared

    var body: some View {
        let _ = languageManager.language

        ZStack {
            Color.cyberBlack
                .ignoresSafeArea()

            Group {
                switch engine.currentScreen {
                case .title:
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
            .padding(.top, 4)

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

            // 初回起動時の言語選択オーバーレイ（日本語 / English）
            if !languageManager.hasSelectedInitialLanguage {
                InitialLanguageSelectionOverlayView(
                    engine: engine,
                    languageManager: languageManager
                )
                .transition(.opacity)
                .zIndex(60)
            }
        }
        .animation(.easeOut(duration: 0.20), value: engine.currentScreen)
        .animation(.easeOut(duration: 0.18), value: engine.isShowingPendingRevivePrompt)
        .animation(.easeOut(duration: 0.22), value: languageManager.hasSelectedInitialLanguage)
        .onAppear {
            engine.onAppAppear()
        }
    }
}

/// 初回起動時に表示される言語選択画面（日本語 / English）
private struct InitialLanguageSelectionOverlayView: View {
    var engine: GameEngine
    @Bindable var languageManager: LanguageManager

    @State private var tentativeLanguage: AppLanguage = LanguageManager.shared.language

    var body: some View {
        ZStack {
            Color.black.opacity(0.90)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(Color.cyberCyan)
                        .shadow(color: Color.cyberCyan.opacity(0.8), radius: 10)

                    Text("LANGUAGE / 言語選択")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white)

                    Text("使用する言語を選択してください\nPlease select your language")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { option in
                        let isSelected = (tentativeLanguage == option)

                        Button {
                            HapticManager.playLight(enabled: engine.isHapticsEnabled)
                            tentativeLanguage = option
                            languageManager.language = option
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundStyle(isSelected ? Color.cyberEmerald : Color.white.opacity(0.45))

                                Text(option.displayName)
                                    .font(.system(size: 19, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.cyberCyan.opacity(0.20) : Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                isSelected ? Color.cyberCyan : Color.white.opacity(0.22),
                                                lineWidth: isSelected ? 2.2 : 1.0
                                            )
                                    )
                            )
                            .shadow(color: isSelected ? Color.cyberCyan.opacity(0.45) : .clear, radius: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("※設定画面（SETTING）からいつでも変更できます\n* You can change this anytime in SETTING")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Button {
                    SoundManager.shared.playButtonSE()
                    HapticManager.playHeavy(enabled: engine.isHapticsEnabled)
                    languageManager.confirmInitialLanguage(tentativeLanguage)
                } label: {
                    Text(tentativeLanguage == .english ? "OK" : "決定")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(
                    CyberButtonStyle(
                        primaryColor: .cyberEmerald,
                        secondaryColor: .cyberCyan,
                        cutSize: 12,
                        fillOpacity: 0.40
                    )
                )
            }
            .padding(22)
            .frame(maxWidth: 380)
            .background(
                CyberShape(cutSize: 18)
                    .fill(Color.cyberPanel)
                    .overlay(
                        CyberShape(cutSize: 18)
                            .strokeBorder(Color.cyberCyan, lineWidth: 2)
                    )
            )
            .shadow(color: Color.cyberCyan.opacity(0.45), radius: 24)
            .padding(.horizontal, 22)
        }
    }
}

/// 敗退後に復活回数を残してタイトルへ戻っていた場合、次回「KUMITE」押下時に表示する確認ポップアップ
private struct PendingRevivePromptOverlayView: View {
    @Bindable var engine: GameEngine
    @Bindable private var adManager = AdManager.shared
    @Bindable private var lang = LanguageManager.shared

    var body: some View {
        let _ = lang.language

        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.isShowingPendingRevivePrompt = false
                }

            VStack(spacing: 16) {
                Text(L10n("KUMITE 再開確認", "RESUME KUMITE"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .italic()
                    .tracking(1.5)
                    .foregroundStyle(Color.cyberAmber)
                    .shadow(color: Color.cyberAmber.opacity(0.75), radius: 10)

                VStack(spacing: 6) {
                    Text(
                        L10n(
                            "保持中の記録：\(engine.winStreak) 連勝",
                            "Saved Streak: \(engine.winStreak) Wins"
                        )
                    )
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.cyberCyan)

                    Text(
                        L10n(
                            "前回敗退時の連勝記録が残っています。\n動画広告を見て連勝を継続するか、最初から挑戦するか選択してください。",
                            "Your previous win streak is still saved.\nWatch a video ad to continue your streak, or start fresh from 0 wins."
                        )
                    )
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
                            Text(
                                adManager.isLoadingRewardedAd
                                    ? L10n("動画広告を読み込み中...", "Loading Video Ad...")
                                    : L10n("動画広告を見て復活（連勝継続）", "Watch Ad to Revive (Keep Streak)")
                            )
                        }
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundStyle(.white)

                        Text(
                            L10n(
                                "\(engine.winStreak)連勝を維持して再戦（復活残り \(engine.remainingRevives) / \(engine.currentRunMaxRevives) 回）",
                                "Keep \(engine.winStreak)-win streak (Resets left: \(engine.remainingRevives) / \(engine.currentRunMaxRevives))"
                            )
                        )
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
                    Text(L10n("最初から挑戦（0連勝）", "Start Over (0 Wins)"))
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

                // キャンセル
                Button {
                    HapticManager.playLight(enabled: engine.isHapticsEnabled)
                    engine.isShowingPendingRevivePrompt = false
                } label: {
                    Text(L10n("✕ キャンセル", "✕ CANCEL"))
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
