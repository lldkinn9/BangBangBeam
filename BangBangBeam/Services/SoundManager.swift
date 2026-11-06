import Foundation
import AVFoundation
import Observation

/// BGM再生トラック種別
enum BGMTrack: String {
    case title = "bgm_title"
    case battle1 = "bgm_battle_1"
    case battle2 = "bgm_battle_2"
}

/// SE（効果音）種別
enum SoundEffect: String {
    case button = "button"
    case cutin = "cutin"
}

/// アプリ全体のBGMループ再生・ON/OFF設定および効果音（SE）再生を管理するサウンドマネージャー
@Observable
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private let bgmEnabledKey = "BangBangBeam.isBGMEnabled"

    var isBGMEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBGMEnabled, forKey: bgmEnabledKey)
            if isBGMEnabled {
                if let target = desiredContext {
                    switch target {
                    case .title:
                        playTitleBGM()
                    case .battle:
                        playBattleBGM(forceNewRandom: false)
                    }
                }
            } else {
                stopBGM()
            }
        }
    }

    private enum BGMContext {
        case title
        case battle
    }

    private var desiredContext: BGMContext? = nil
    private var currentTrack: BGMTrack? = nil
    private var audioPlayer: AVAudioPlayer? = nil
    private let defaultVolume: Float = 0.55

    // MARK: - SE Preloaded Pools（低遅延・連打対応）
    private var buttonPlayers: [AVAudioPlayer] = []
    private var buttonPlayerIndex: Int = 0
    private let buttonSEVolume: Float = 0.85

    private var cutinPlayers: [AVAudioPlayer] = []
    private var cutinPlayerIndex: Int = 0
    private let cutinSEVolume: Float = 1.0

    private init() {
        if UserDefaults.standard.object(forKey: bgmEnabledKey) == nil {
            UserDefaults.standard.set(true, forKey: bgmEnabledKey)
            self.isBGMEnabled = true
        } else {
            self.isBGMEnabled = UserDefaults.standard.bool(forKey: bgmEnabledKey)
        }
        configureAudioSession()
        preloadSoundEffects()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // シミュレータ等でオーディオセッション競合が起きた場合もクラッシュさせない
        }
    }

    private func preloadSoundEffects() {
        buttonPlayers = buildPlayerPool(effect: .button, count: 4, volume: buttonSEVolume)
        cutinPlayers = buildPlayerPool(effect: .cutin, count: 2, volume: cutinSEVolume)
    }

    private func buildPlayerPool(effect: SoundEffect, count: Int, volume: Float) -> [AVAudioPlayer] {
        guard let url = resolveBundleURL(name: effect.rawValue, ext: "mp3"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        var pool: [AVAudioPlayer] = []
        pool.reserveCapacity(count)
        for _ in 0..<count {
            if let player = try? AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue) {
                player.numberOfLoops = 0
                player.volume = volume
                player.prepareToPlay()
                pool.append(player)
            }
        }
        return pool
    }

    // MARK: - SE Playback
    /// 各種ボタン押下時の効果音（button.mp3）を再生
    func playButtonSE() {
        if buttonPlayers.isEmpty {
            buttonPlayers = buildPlayerPool(effect: .button, count: 4, volume: buttonSEVolume)
        }
        guard !buttonPlayers.isEmpty else { return }

        let player = buttonPlayers[buttonPlayerIndex % buttonPlayers.count]
        buttonPlayerIndex = (buttonPlayerIndex + 1) % buttonPlayers.count

        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.volume = buttonSEVolume
        player.play()
    }

    /// 必殺技カットイン演出時の効果音（cutin.mp3）を再生
    func playCutinSE() {
        if cutinPlayers.isEmpty {
            cutinPlayers = buildPlayerPool(effect: .cutin, count: 2, volume: cutinSEVolume)
        }
        guard !cutinPlayers.isEmpty else { return }

        let player = cutinPlayers[cutinPlayerIndex % cutinPlayers.count]
        cutinPlayerIndex = (cutinPlayerIndex + 1) % cutinPlayers.count

        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.volume = cutinSEVolume
        player.play()
    }

    /// カットイン演出スキップ時などに再生中の cutin.mp3 を停止
    func stopCutinSE() {
        for player in cutinPlayers where player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
    }

    // MARK: - BGM Playback
    /// タイトル〜メニュー画面用BGM（Neon Overdrive）をループ再生
    func playTitleBGM() {
        desiredContext = .title
        guard isBGMEnabled else { return }
        if currentTrack == .title, audioPlayer?.isPlaying == true {
            audioPlayer?.volume = defaultVolume
            return
        }
        startTrack(.title)
    }

    /// バトル画面用BGM（Seamless Looping または Cyber Velocity をランダム選出）をループ再生
    func playBattleBGM(forceNewRandom: Bool = true) {
        desiredContext = .battle
        guard isBGMEnabled else { return }

        if !forceNewRandom,
           let current = currentTrack,
           (current == .battle1 || current == .battle2),
           audioPlayer?.isPlaying == true {
            audioPlayer?.volume = defaultVolume
            return
        }

        let chosen: BGMTrack = Bool.random() ? .battle1 : .battle2
        startTrack(chosen)
    }

    /// 必殺動画演出中の一時音量ダッキング
    func setDucked(_ ducked: Bool) {
        guard let player = audioPlayer else { return }
        player.volume = ducked ? (defaultVolume * 0.25) : defaultVolume
    }

    func stopBGM() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentTrack = nil
    }

    private func startTrack(_ track: BGMTrack) {
        guard let url = resolveBundleURL(name: track.rawValue, ext: "mp3") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // 無限ループ
            player.volume = defaultVolume
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
            self.currentTrack = track
        } catch {
            self.audioPlayer = nil
            self.currentTrack = nil
        }
    }

    /// フラット配置・Resources/BGM・Resources/SEサブフォルダ配置のどちらでも確実にバンドルURLを解決する
    func resolveBundleURL(name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        for sub in ["Resources/SE", "SE", "Resources/BGM", "BGM", "Resources/Videos", "Videos", "Resources"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                return url
            }
        }
        return nil
    }
}
