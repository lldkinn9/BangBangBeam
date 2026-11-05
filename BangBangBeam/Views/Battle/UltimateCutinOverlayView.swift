import SwiftUI
import AVFoundation

/// 4チャージ一撃必殺発動時の「目元カットイン → 必殺アニメーション動画 (mp4)」演出ビュー
struct UltimateCutinOverlayView: View {
    let character: CharacterProfile
    let isPlayer: Bool
    let onComplete: () -> Void

    @State private var showCutinBanner: Bool = false
    @State private var phase: Phase = .cutin
    @State private var hasCompleted: Bool = false

    private enum Phase {
        case cutin
        case video
    }

    var body: some View {
        ZStack {
            Color.black.opacity(phase == .video ? 0.96 : 0.82)
                .ignoresSafeArea()

            if phase == .cutin {
                cutinView
                    .transition(.opacity)
            } else {
                videoPlayerSection
                    .transition(.opacity)
            }

            // 右上スキップボタン（テンポ良く周回したいプレイヤー向け）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        finishOnce()
                    } label: {
                        Text("SKIP ▶▶")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.65), in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(Color.cyberCyan.opacity(0.6), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()
            }
        }
        .task {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                showCutinBanner = true
            }
            try? await Task.sleep(for: .milliseconds(1050))
            guard !hasCompleted else { return }

            if SoundManager.shared.resolveBundleURL(name: character.ultimateVideoName, ext: "mp4") != nil {
                withAnimation(.easeInOut(duration: 0.18)) {
                    phase = .video
                }
            } else {
                finishOnce()
            }
        }
    }

    private var cutinView: some View {
        let accent: Color = isPlayer ? .cyberEmerald : .cyberDanger

        return VStack(spacing: 18) {
            Text(isPlayer ? "⚡️ OVERDRIVE ULTIMATE ⚡️" : "⚠️ ENEMY ULTIMATE ⚠️")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .tracking(3)
                .foregroundStyle(accent)
                .shadow(color: accent, radius: 10)

            ZStack {
                Image(character.cutinAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .clipped()
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white, accent, .cyberCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: accent.opacity(0.95), radius: 24)
            }
            .offset(x: showCutinBanner ? 0 : (isPlayer ? -380 : 380))

            Text("\(character.codeName) // 一撃必殺！！")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: accent, radius: 12)
        }
    }

    private var videoPlayerSection: some View {
        Group {
            if let url = SoundManager.shared.resolveBundleURL(name: character.ultimateVideoName, ext: "mp4") {
                SeamlessVideoPlayerView(url: url) {
                    finishOnce()
                }
                .ignoresSafeArea()
            }
        }
    }

    private func finishOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onComplete()
    }
}

/// コントロールバーを表示せず全画面で必殺mp4動画を再生し、終了時にコールバックを呼ぶプレイヤー
private struct SeamlessVideoPlayerView: UIViewRepresentable {
    let url: URL
    let onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEnded: onEnded)
    }

    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true // BGM無し仕様に準拠
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        context.coordinator.observe(item: item, player: player)
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerContainerUIView, coordinator: Coordinator) {
        uiView.playerLayer.player?.pause()
        uiView.playerLayer.player = nil
        coordinator.cleanup()
    }

    final class Coordinator {
        private let onEnded: () -> Void
        private var observer: NSObjectProtocol?
        private var fallbackTask: Task<Void, Never>?

        init(onEnded: @escaping () -> Void) {
            self.onEnded = onEnded
        }

        func observe(item: AVPlayerItem, player: AVPlayer) {
            observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onEnded()
                }
            }

            // 万一再生通知が届かない場合の安全タイムアウト（最大7秒）
            fallbackTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(7.0))
                if !Task.isCancelled {
                    self?.onEnded()
                }
            }
        }

        func cleanup() {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
            fallbackTask?.cancel()
            fallbackTask = nil
        }
    }
}

private final class PlayerContainerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
