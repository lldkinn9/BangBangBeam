import Foundation
import AVFoundation
import Observation

/// BGM再生トラック種別
enum BGMTrack: String, CaseIterable {
    case title = "bgm_title"
    case battle1 = "bgm_battle_1"
    case battle2 = "bgm_battle_2"
}

/// SE（効果音）種別（今後追加されるSEもこのenumに追加するだけで一括でBGM ON/OFF設定・SE音量設定に従う）
enum SoundEffect: String, CaseIterable {
    case button = "button"
    case cutin = "cutin"
    case vsAppear = "vs_appear"

    var poolSize: Int {
        switch self {
        case .button:
            return 4
        case .cutin:
            return 2
        case .vsAppear:
            return 2
        }
    }
}

/// アプリ全体のBGMループ再生・効果音（SE）再生・サウンドON/OFF・BGM/SE個別音量を一元管理するサウンドマネージャー
@Observable
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private let bgmEnabledKey = "BangBangBeam.isBGMEnabled"
    private let bgmVolumeKey = "BangBangBeam.bgmVolume"
    private let seVolumeKey = "BangBangBeam.seVolume"

    /// サウンド（BGMおよび全SE効果音・必殺動画音声）のON/OFF設定。OFF時は音量スライダーの値にかかわらず完全無音化する。
    var isBGMEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBGMEnabled, forKey: bgmEnabledKey)
            if isBGMEnabled {
                ensureAudioSessionActive()
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

    /// BGM 音量（0.0 〜 1.0、初期値 0.45 = 45%）
    var bgmVolume: Double {
        didSet {
            let clamped = min(1.0, max(0.0, bgmVolume))
            if bgmVolume != clamped {
                bgmVolume = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: bgmVolumeKey)
            if isBGMEnabled {
                audioPlayer?.volume = effectiveBGMVolume
            }
        }
    }

    /// SE（効果音・必殺アニメーション音声）音量（0.0 〜 1.0、初期値 0.90 = 90%）
    var seVolume: Double {
        didSet {
            let clamped = min(1.0, max(0.0, seVolume))
            if seVolume != clamped {
                seVolume = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: seVolumeKey)
            let vol = Float(clamped)
            for effect in SoundEffect.allCases {
                guard let pool = sePlayerPools[effect] else { continue }
                for player in pool {
                    player.volume = isBGMEnabled ? vol : 0.0
                }
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
    private var bgmPlayers: [BGMTrack: AVAudioPlayer] = [:]
    private var isDucked: Bool = false

    private var effectiveBGMVolume: Float {
        let base = Float(min(1.0, max(0.0, bgmVolume)))
        return isDucked ? (base * 0.25) : base
    }

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

        if UserDefaults.standard.object(forKey: bgmVolumeKey) == nil {
            UserDefaults.standard.set(0.45, forKey: bgmVolumeKey)
            self.bgmVolume = 0.45
        } else {
            self.bgmVolume = min(1.0, max(0.0, UserDefaults.standard.double(forKey: bgmVolumeKey)))
        }

        if UserDefaults.standard.object(forKey: seVolumeKey) == nil {
            UserDefaults.standard.set(0.90, forKey: seVolumeKey)
            self.seVolume = 0.90
        } else {
            self.seVolume = min(1.0, max(0.0, UserDefaults.standard.double(forKey: seVolumeKey)))
        }

        ensureAudioSessionActive()
        preloadSoundEffects()
        preloadBGMTracks()
    }

    /// 広告視聴後やバックグラウンド復帰後でもBGM・SE・必殺動画音声が確実に同時再生されるようオーディオセッションを維持
    func ensureAudioSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // シミュレータ等でオーディオセッション競合が起きた場合もクラッシュさせない
        }
    }

    /// 1戦目開始時のディスクI/O＆MP3デコーダ初期化ラグを防ぐため、全BGMプレイヤーを事前準備
    private func preloadBGMTracks() {
        for track in BGMTrack.allCases where bgmPlayers[track] == nil {
            guard let url = resolveBundleURL(name: track.rawValue, ext: "mp3"),
                  let player = try? AVAudioPlayer(contentsOf: url) else {
                continue
            }
            player.numberOfLoops = -1
            player.volume = effectiveBGMVolume
            player.prepareToPlay()
            bgmPlayers[track] = player
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

        let initialVol = Float(min(1.0, max(0.0, seVolume)))
        var pool: [AVAudioPlayer] = []
        pool.reserveCapacity(effect.poolSize)
        for _ in 0..<effect.poolSize {
            if let player = try? AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue) {
                player.numberOfLoops = 0
                player.volume = initialVol
                player.prepareToPlay()
                pool.append(player)
            }
        }
        return pool
    }

    // MARK: - SE Playback（すべてこのメソッドを経由するため、OFF時は音量設定にかかわらず今後の追加SEも含めて確実に無音）
    /// 指定された効果音（SE）を再生する（サウンド設定がOFFの時は一切再生しない）
    func playSE(_ effect: SoundEffect) {
        guard isBGMEnabled else { return }

        let vol = Float(min(1.0, max(0.0, seVolume)))
        guard vol > 0.001 else { return }

        ensureAudioSessionActive()

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
        player.volume = vol
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

    /// 対戦直前VS画面でキャラクター＆名称が登場する瞬間の効果音（vs_appear.mp3）を再生
    func playVsAppearSE() {
        playSE(.vsAppear)
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
            audioPlayer?.volume = effectiveBGMVolume
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
            audioPlayer?.volume = effectiveBGMVolume
            return
        }

        let chosen: BGMTrack = Bool.random() ? .battle1 : .battle2
        startTrack(chosen)
    }

    /// 必殺動画演出中の一時音量ダッキング（動画の音声を明瞭に聴かせる）
    func setDucked(_ ducked: Bool) {
        isDucked = ducked
        if ducked && isBGMEnabled {
            ensureAudioSessionActive()
        }
        guard isBGMEnabled, let player = audioPlayer else { return }
        player.volume = effectiveBGMVolume
    }

    func stopBGM() {
        audioPlayer?.pause()
        audioPlayer?.currentTime = 0
        audioPlayer = nil
        currentTrack = nil
    }

    private func startTrack(_ track: BGMTrack) {
        guard isBGMEnabled else { return }
        ensureAudioSessionActive()

        if let active = audioPlayer, active !== bgmPlayers[track] {
            active.pause()
            active.currentTime = 0
        }

        if bgmPlayers[track] == nil,
           let url = resolveBundleURL(name: track.rawValue, ext: "mp3"),
           let created = try? AVAudioPlayer(contentsOf: url) {
            created.numberOfLoops = -1
            created.prepareToPlay()
            bgmPlayers[track] = created
        }

        guard let player = bgmPlayers[track] else {
            self.audioPlayer = nil
            self.currentTrack = nil
            return
        }

        player.numberOfLoops = -1
        player.currentTime = 0
        player.volume = effectiveBGMVolume
        player.play()
        self.audioPlayer = player
        self.currentTrack = track
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
