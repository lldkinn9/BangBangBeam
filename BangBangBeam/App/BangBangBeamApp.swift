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

/// アプリ全体の画面遷移（TitleView <-> BattleView）を管理するルートビュー
struct RootContainerView: View {
    @Bindable var engine: GameEngine

    var body: some View {
        ZStack {
            Color.cyberBlack
                .ignoresSafeArea()

            switch engine.currentScreen {
            case .title:
                TitleView(engine: engine)
                    .transition(.opacity)
            case .battle:
                BattleView(engine: engine)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.32), value: engine.currentScreen)
    }
}

