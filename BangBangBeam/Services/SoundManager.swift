import Foundation
import AVFoundation
import Observation

/// BGM再生トラック種別
enum BGMTrack: String {
    case title = "bgm_title"
    case battle1 = "bgm_battle_1"
    case battle2 = "bgm_battle_2"
}

/// アプリ全体のBGMループ再生・ON/OFF設定を管理するサウンドマネージャー
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

    private init() {
        if UserDefaults.standard.object(forKey: bgmEnabledKey) == nil {
            UserDefaults.standard.set(true, forKey: bgmEnabledKey)
            self.isBGMEnabled = true
        } else {
            self.isBGMEnabled = UserDefaults.standard.bool(forKey: bgmEnabledKey)
        }
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // シミュレータ等でオーディオセッション競合が起きた場合もクラッシュさせない
        }
    }

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

    /// フラット配置・Resources/BGMサブフォルダ配置のどちらでも確実にバンドルURLを解決する
    func resolveBundleURL(name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        for sub in ["Resources/BGM", "BGM", "Resources/Videos", "Videos", "Resources"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                return url
            }
        }
        return nil
    }
}
