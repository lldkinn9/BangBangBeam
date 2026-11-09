import SwiftUI
import AVFoundation

/// 4チャージ一撃必殺発動時の「目元カットイン → 必殺アニメーション動画 (音声付きmp4)」演出ビュー
struct UltimateCutinOverlayView: View {
    let character: CharacterProfile
    let isPlayer: Bool
    let onComplete: () -> Void

    @Bindable private var soundManager = SoundManager.shared
    @State private var showCutinBanner: Bool = false
    @State private var phase: Phase = .cutin
    @State private var hasCompleted: Bool = false

    private enum Phase {
        case cutin
        case video
    }

    /// サウンドON時はSE音量設定を適用してmp4音声を再生し、OFF時は完全ミュートにする
    private var effectiveVideoVolume: Float {
        guard soundManager.isBGMEnabled else { return 0.0 }
        return Float(min(1.0, max(0.0, soundManager.seVolume)))
    }

    var body: some View {
        let videoURL = SoundManager.shared.resolveBundleURL(name: character.ultimateVideoName, ext: "mp4")

        ZStack {
            Color.black.opacity(phase == .video ? 0.96 : 0.84)
                .ignoresSafeArea()

            // カットイン中から映像・音声デコーダをプリロードしておき、phase == .video 移行と同時に音声付きで即座に再生開始
            if let url = videoURL {
                SeamlessVideoPlayerView(
                    url: url,
                    isPlaying: phase == .video,
                    audioVolume: effectiveVideoVolume
                ) {
                    finishOnce()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(phase == .video ? 1.0 : 0.0)
            }

            if phase == .cutin {
                cutinView
                    .transition(.opacity)
            }

            // 右上スキップボタン（テンポ良く周回したいプレイヤー向け）
            VStack {
                HStack {
                    Spacer()
                    Button {
                        SoundManager.shared.stopCutinSE()
                        SoundManager.shared.setDucked(false)
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
            SoundManager.shared.ensureAudioSessionActive()
            SoundManager.shared.setDucked(true)
            SoundManager.shared.playCutinSE()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                showCutinBanner = true
            }
            try? await Task.sleep(for: .milliseconds(1100))
            guard !hasCompleted else { return }

            if videoURL != nil {
                withAnimation(.easeInOut(duration: 0.18)) {
                    phase = .video
                }
            } else {
                finishOnce()
            }
        }
        .onDisappear {
            SoundManager.shared.stopCutinSE()
            SoundManager.shared.setDucked(false)
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

            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 186)
                .overlay {
                    Image(character.cutinAsset)
                        .resizable()
                        .scaledToFill()
                }
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
                .offset(x: showCutinBanner ? 0 : (isPlayer ? -380 : 380))

            Text("\(character.codeName) // 一撃必殺！！")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: accent, radius: 12)
        }
    }

    private func finishOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        SoundManager.shared.setDucked(false)
        onComplete()
    }
}

/// コントロールバーを表示せず全画面で必殺mp4動画 (H.264 avc1 + AAC音声) を再生し、終了時にコールバックを呼ぶプレイヤー
private struct SeamlessVideoPlayerView: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool
    let audioVolume: Float
    let onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEnded: onEnded)
    }

    func makeUIView(context: Context) -> PlayerContainerUIView {
        // 必殺動画のAVPlayer初期化前にも必ず `.ambient` カテゴリを適用し、iPhoneの消音モード時は確実に無音化する
        SoundManager.shared.ensureAudioSessionActive()

        let view = PlayerContainerUIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.allowsExternalPlayback = false
        player.automaticallyWaitsToMinimizeStalling = false
        player.audiovisualBackgroundPlaybackPolicy = .pauses
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.actionAtItemEnd = .pause

        // 停止中（rate == 0）は音が出ないため、プリロード段階から音声パイプラインも準備（ゲーム内BGM OFF時は完全ミュート、ON時はiPhone消音モードに連動）
        let shouldMute = (audioVolume <= 0.001)
        player.isMuted = shouldMute
        player.volume = shouldMute ? 0.0 : audioVolume

        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill

        context.coordinator.setup(item: item, player: player)
        if isPlaying {
            context.coordinator.startPlaybackIfNeeded(volume: audioVolume)
        }
        return view
    }

    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        SoundManager.shared.ensureAudioSessionActive()
        let shouldMute = (audioVolume <= 0.001)
        uiView.playerLayer.player?.isMuted = shouldMute
        uiView.playerLayer.player?.volume = shouldMute ? 0.0 : audioVolume
        if isPlaying {
            context.coordinator.startPlaybackIfNeeded(volume: audioVolume)
        }
    }

    static func dismantleUIView(_ uiView: PlayerContainerUIView, coordinator: Coordinator) {
        uiView.playerLayer.player?.pause()
        uiView.playerLayer.player = nil
        coordinator.cleanup()
    }

    final class Coordinator {
        private let onEnded: () -> Void
        private var player: AVPlayer?
        private var endObserver: NSObjectProtocol?
        private var statusObservation: NSKeyValueObservation?
        private var fallbackTask: Task<Void, Never>?
        private var didStartPlayback: Bool = false

        init(onEnded: @escaping () -> Void) {
            self.onEnded = onEnded
        }

        func setup(item: AVPlayerItem, player: AVPlayer) {
            self.player = player

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onEnded()
                }
            }

            statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] observedItem, _ in
                let currentStatus = observedItem.status
                if currentStatus == .failed {
                    Task { @MainActor [weak self] in
                        self?.onEnded()
                    }
                }
            }
        }

        func startPlaybackIfNeeded(volume: Float) {
            guard !didStartPlayback, let player else { return }
            if player.currentItem?.status == .failed {
                onEnded()
                return
            }
            didStartPlayback = true
            SoundManager.shared.ensureAudioSessionActive()

            let shouldMute = (volume <= 0.001)
            player.isMuted = shouldMute
            player.volume = shouldMute ? 0.0 : volume

            let currentSeconds = player.currentTime().seconds
            if currentSeconds.isFinite && currentSeconds > 0.05 {
                player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] _ in
                    Task { @MainActor in
                        SoundManager.shared.ensureAudioSessionActive()
                        player?.play()
                    }
                }
            } else {
                SoundManager.shared.ensureAudioSessionActive()
                player.play()
            }

            // 動画尺を自動取得した上で、万一終了通知が届かない場合のみ安全回収するフォールバック
            fallbackTask = Task { @MainActor [weak self, weak player] in
                var waitSeconds: Double = 15.0
                if let asset = player?.currentItem?.asset,
                   let dur = try? await asset.load(.duration),
                   dur.isNumeric && dur.seconds > 0.5 {
                    waitSeconds = dur.seconds + 3.0
                }
                try? await Task.sleep(for: .seconds(waitSeconds))
                if !Task.isCancelled {
                    self?.onEnded()
                }
            }
        }

        func cleanup() {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            statusObservation?.invalidate()
            statusObservation = nil
            fallbackTask?.cancel()
            fallbackTask = nil
            player?.pause()
            player = nil
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
