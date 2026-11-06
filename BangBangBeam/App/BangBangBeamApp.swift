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

/// アプリ全体の画面遷移・非プレイ画面の共通バナー広告・リワード広告フォールバックを統括するルートビュー
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
        .onAppear {
            engine.onAppAppear()
        }
    }
}
