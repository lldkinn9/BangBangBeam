import Foundation
import AVFoundation
import Observation

/// BGM再生トラック種別
enum BGMTrack: String {
    case title = "bgm_title"
    case battle1 = "bgm_battle_1"
    case battle2 = "bgm_battle_2"
}

/// SE（効果音）種別（今後追加されるSEもこのenumに追加するだけで一括でBGM ON/OFF設定に従う）
enum SoundEffect: String, CaseIterable {
    case button = "button"
    case cutin = "cutin"

    var defaultVolume: Float {
        switch self {
        case .button:
            return 0.85
        case .cutin:
            return 1.0
        }
    }

    var poolSize: Int {
        switch self {
        case .button:
            return 4
        case .cutin:
            return 2
        }
    }
}

/// アプリ全体のBGMループ再生・効果音（SE）再生・サウンドON/OFF設定を一元管理するサウンドマネージャー
@Observable
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private let bgmEnabledKey = "BangBangBeam.isBGMEnabled"

    /// BGM（および全SE効果音）のON/OFF設定。OFF時はBGM・既存SE・今後追加される全SEを無音化する。
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
                stopAllSE()
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

    // MARK: - SE Preloaded Pools（全SoundEffect共通管理）
    private var sePlayerPools: [SoundEffect: [AVAudioPlayer]] = [:]
    private var sePoolIndices: [SoundEffect: Int] = [:]

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
        for effect in SoundEffect.allCases {
            sePlayerPools[effect] = buildPlayerPool(effect: effect)
            sePoolIndices[effect] = 0
        }
    }

    private func buildPlayerPool(effect: SoundEffect) -> [AVAudioPlayer] {
        guard let url = resolveBundleURL(name: effect.rawValue, ext: "mp3"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        var pool: [AVAudioPlayer] = []
        pool.reserveCapacity(effect.poolSize)
        for _ in 0..<effect.poolSize {
            if let player = try? AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue) {
                player.numberOfLoops = 0
                player.volume = effect.defaultVolume
                player.prepareToPlay()
                pool.append(player)
            }
        }
        return pool
    }

    // MARK: - SE Playback（すべてこのメソッドを経由するため、BGM OFF時は今後の追加SEも含めて確実に無音）
    /// 指定された効果音（SE）を再生する（BGM設定がOFFの時は一切再生しない）
    func playSE(_ effect: SoundEffect) {
        guard isBGMEnabled else { return }

        var pool = sePlayerPools[effect] ?? []
        if pool.isEmpty {
            pool = buildPlayerPool(effect: effect)
            sePlayerPools[effect] = pool
        }
        guard !pool.isEmpty else { return }

        let currentIndex = sePoolIndices[effect] ?? 0
        let player = pool[currentIndex % pool.count]
        sePoolIndices[effect] = (currentIndex + 1) % pool.count

        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.volume = effect.defaultVolume
        player.play()
    }

    /// 対象ボタン（START / KUMITE / RANKING / SETTING）押下時の効果音（button.mp3）を再生
    func playButtonSE() {
        playSE(.button)
    }

    /// 必殺技カットイン演出時の効果音（cutin.mp3）を再生
    func playCutinSE() {
        playSE(.cutin)
    }

    /// 特定の効果音（SE）の再生を停止
    func stopSE(_ effect: SoundEffect) {
        guard let pool = sePlayerPools[effect] else { return }
        for player in pool where player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
    }

    /// カットイン演出スキップ時などに再生中の cutin.mp3 を停止
    func stopCutinSE() {
        stopSE(.cutin)
    }

    /// 再生中の全効果音（SE）を一括停止（BGM OFF切替時などに使用）
    func stopAllSE() {
        for effect in SoundEffect.allCases {
            stopSE(effect)
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
