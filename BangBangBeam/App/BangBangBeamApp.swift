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

/// アプリ全体の画面遷移・非プレイ画面の共通バナー広告・インタースティシャル広告オーバーレイを統括するルートビュー
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
                    TitleView(engine: engine)
                        .transition(.opacity)

                case .kumiteBattle:
                    BattleView(engine: engine)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .practiceTutorial:
                    PracticeTutorialView(engine: engine)
                        .transition(.opacity)
                }
            }
            // プレイ画面以外（タイトル・モード選択、今後追加する非プレイ画面すべて）の最下部にバナー広告を表示
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if engine.currentScreen.showsBottomBannerAd {
                    AdBannerFooterView()
                }
            }

            // GoogleMobileAds SDK 未リンク時のリトライ全画面広告タイミング確認オーバーレイ
            if adManager.isPresentingFallbackInterstitial {
                FallbackInterstitialOverlayView {
                    adManager.dismissFallbackInterstitial()
                }
                .transition(.opacity)
                .zIndex(50)
            }
        }
        .animation(.easeInOut(duration: 0.30), value: engine.currentScreen)
        .onAppear {
            engine.onAppAppear()
        }
    }
}
