import SwiftUI
import Observation

/// 勝敗・ステージ進行状態
enum BattleOutcome: Equatable, Sendable {
    case ongoing
    case stageClear(enemyName: String, reason: String)
    case gameOver(finalStreak: Int, reason: String)
    case practiceClear(isWin: Bool, reason: String)

    nonisolated static func == (lhs: BattleOutcome, rhs: BattleOutcome) -> Bool {
        switch (lhs, rhs) {
        case (.ongoing, .ongoing):
            return true
        case let (.stageClear(e1, r1), .stageClear(e2, r2)):
            return e1 == e2 && r1 == r2
        case let (.gameOver(s1, r1), .gameOver(s2, r2)):
            return s1 == s2 && r1 == r2
        case let (.practiceClear(w1, r1), .practiceClear(w2, r2)):
            return w1 == w2 && r1 == r2
        default:
            return false
        }
    }

    var isFinished: Bool {
        if case .ongoing = self { return false }
        return true
    }
}

/// 4チャージ一撃必殺発動時のカットイン＆動画再生リクエスト
struct UltimatePresentation: Equatable, Sendable {
    let character: CharacterProfile
    let isPlayer: Bool

    nonisolated static func == (lhs: UltimatePresentation, rhs: UltimatePresentation) -> Bool {
        lhs.character == rhs.character && lhs.isPlayer == rhs.isPlayer
    }
}

/// リズム速度プリセット（標準 / 速め の2択）
enum TempoPreset: String, CaseIterable, Identifiable, Sendable {
    case standard
    case fast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "標準"
        case .fast:
            return "速め"
        }
    }

    var bpmValue: Double {
        switch self {
        case .standard:
            return 88.0
        case .fast:
            return 116.0
        }
    }
}

/// 製品版ゲームエンジン（KUMITE 11人勝ち抜き・HP3制・被弾チャージ-1・お手つき無防備・4チャージ一撃必殺）
@Observable
@MainActor
final class GameEngine {
    // MARK: - Persistence Keys
    private let initialPracticeDoneKey = "BangBangBeam.hasCompletedInitialPractice"
    private let tempoPresetKey = "BangBangBeam.tempoPreset"

    // MARK: - Navigation & Mode
    var currentScreen: AppScreen = .title
    var gameMode: GameMode = .kumite
    var isFirstLaunchTutorial: Bool = false

    // MARK: - Constants & Settings
    let maxHP: Int = 3
    let maxCharge: Int = 4

    /// テンポ選択（標準 / 速め）
    var tempoPreset: TempoPreset = .standard {
        didSet {
            UserDefaults.standard.set(tempoPreset.rawValue, forKey: tempoPresetKey)
            bpm = tempoPreset.bpmValue
        }
    }

    /// テンポ実効BPM（標準: 88 BPM / 速め: 116 BPM）
    var bpm: Double = 88.0 {
        didSet {
            if isAutoLoopRunning {
                restartTimer()
            }
        }
    }

    var isHapticsEnabled: Bool = true

    // MARK: - KUMITE Progression State
    var winStreak: Int = 0
    var currentEnemy: CharacterProfile = CharacterProfile.kumiteRoster[0]
    var currentLoopNumber: Int = 1
    var currentStageInLoop: Int = 1
    var totalStagesInCurrentLoop: Int = 11

    // MARK: - Battle Live State
    /// 現在の拍（0: せっせっせーの..., 1: バン！, 2: バン！, 3: アクション激突）
    var beat: Int = 0
    var turnCount: Int = 1

    var playerHP: Int = 3
    var cpuHP: Int = 3

    var playerCharge: Int = 0
    var cpuCharge: Int = 0

    var playerExpression: CharacterExpression = .normal
    var cpuExpression: CharacterExpression = .normal

    /// プレイヤーが次の3拍目に向けて予約しているコマンド
    var selectedAction: GameAction = .charge

    /// 直近の3拍目で確定・公開された実効アクション
    var revealedPlayerMove: ResolvedMove? = nil
    var revealedCpuMove: ResolvedMove? = nil

    var calloutText: String = "せっせっせーの..."
    var statusDetailText: String = "リズムに合わせてコマンドを選択！"

    var outcome: BattleOutcome = .ongoing

    /// 4チャージ一撃必殺発動中のカットイン＆動画演出状態
    var activeUltimate: UltimatePresentation? = nil

    /// PRACTICEモードのフリー練習タブ用自動再生フラグ
    var isPracticeAutoPlay: Bool = false {
        didSet {
            guard currentScreen == .practiceTutorial, !outcome.isFinished, activeUltimate == nil else { return }
            if isPracticeAutoPlay {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    // MARK: - Timer
    private var rhythmTimer: Timer? = nil

    var beatInterval: TimeInterval {
        60.0 / max(50.0, min(bpm, 160.0))
    }

    private var isAutoLoopRunning: Bool {
        rhythmTimer != nil
    }

    // MARK: - Initialization & First Launch Check
    init() {
        if let savedRaw = UserDefaults.standard.string(forKey: tempoPresetKey),
           let savedPreset = TempoPreset(rawValue: savedRaw) {
            self.tempoPreset = savedPreset
            self.bpm = savedPreset.bpmValue
        } else {
            self.tempoPreset = .standard
            self.bpm = TempoPreset.standard.bpmValue
        }

        let completedTutorial = UserDefaults.standard.bool(forKey: initialPracticeDoneKey)
        if !completedTutorial {
            // 初回アプリ起動時は自動で PRACTICE（チュートリアル）モードを起動
            self.isFirstLaunchTutorial = true
            self.gameMode = .practice
            self.currentScreen = .practiceTutorial
            setupMatchState(enemy: CharacterProfile.kumiteRoster[0])
        } else {
            self.currentScreen = .title
        }
    }

    /// 起動完了時のオーディオ・サービス初期化フック
    func onAppAppear() {
        GameCenterManager.shared.authenticateLocalPlayer()
        AdManager.shared.startSDKAndRequestATT()

        switch currentScreen {
        case .title:
            SoundManager.shared.playTitleBGM()
        case .kumiteBattle, .practiceTutorial:
            SoundManager.shared.playBattleBGM(forceNewRandom: true)
        }
    }

    func markTutorialCompleted() {
        UserDefaults.standard.set(true, forKey: initialPracticeDoneKey)
        isFirstLaunchTutorial = false
    }

    // MARK: - Navigation Transitions
    /// KUMITE（勝ち抜きサバイバル）を Stage 1 (geek) から開始
    func startKumiteFromBeginning() {
        markTutorialCompleted()
        stopTimer()
        gameMode = .kumite
        winStreak = 0
        loadEnemyForCurrentStreak()
        setupMatchState(enemy: currentEnemy)
        currentScreen = .kumiteBattle
        SoundManager.shared.playBattleBGM(forceNewRandom: true)
        startTimer()
    }

    /// KUMITEで敵撃破後、ReoのHP=3全回復・チャージ0リセットで次の敵へ進む
    func advanceToNextKumiteStage() {
        stopTimer()
        loadEnemyForCurrentStreak()
        setupMatchState(enemy: currentEnemy)
        SoundManager.shared.playBattleBGM(forceNewRandom: true)
        startTimer()
    }

    /// PRACTICE（ルール学習＆練習専用UI）を開始
    func startPracticeMode() {
        stopTimer()
        gameMode = .practice
        isPracticeAutoPlay = false
        setupMatchState(enemy: CharacterProfile.kumiteRoster[0])
        currentScreen = .practiceTutorial
        SoundManager.shared.playBattleBGM(forceNewRandom: true)
    }

    /// PRACTICE内のフリー実戦リセット
    func resetPracticeSparring() {
        stopTimer()
        setupMatchState(enemy: CharacterProfile.kumiteRoster[0])
        if isPracticeAutoPlay {
            startTimer()
        }
    }

    /// タイトル画面へ戻る
    func returnToTitle() {
        markTutorialCompleted()
        stopTimer()
        activeUltimate = nil
        isPracticeAutoPlay = false
        SoundManager.shared.setDucked(false)
        currentScreen = .title
        SoundManager.shared.playTitleBGM()
    }

    // MARK: - Player Input
    /// チャージ不足のボタンもタップ可能（3拍目で無防備のお手つき状態になる）
    func selectCommand(_ action: GameAction) {
        guard !outcome.isFinished, activeUltimate == nil else { return }
        selectedAction = action
        HapticManager.playMedium(enabled: isHapticsEnabled)
    }

    /// 手動で1拍進める（PRACTICE用）
    func stepBeatManually() {
        guard !outcome.isFinished, activeUltimate == nil else { return }
        advanceBeat()
    }

    // MARK: - Match Setup & Rhythm Loop
    private func loadEnemyForCurrentStreak() {
        let info = CharacterProfile.enemy(forStreak: winStreak)
        currentEnemy = info.profile
        currentLoopNumber = info.loopNumber
        currentStageInLoop = info.stageInLoop
        totalStagesInCurrentLoop = info.totalStagesInLoop
    }

    private func setupMatchState(enemy: CharacterProfile) {
        currentEnemy = enemy
        beat = 0
        turnCount = 1
        playerHP = maxHP
        cpuHP = maxHP
        playerCharge = 0
        cpuCharge = 0
        playerExpression = .normal
        cpuExpression = .normal
        selectedAction = .charge
        revealedPlayerMove = nil
        revealedCpuMove = nil
        activeUltimate = nil
        outcome = .ongoing
        calloutText = "せっせっせーの..."
        statusDetailText = gameMode == .practice
            ? "1・2拍目でコマンドを選び、3拍目でアクション発動！"
            : "VS \(enemy.codeName) — 1・2拍目の間にコマンドを予約せよ！"
    }

    private func startTimer() {
        stopTimer()
        let interval = beatInterval
        rhythmTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceBeat()
            }
        }
    }

    private func restartTimer() {
        guard rhythmTimer != nil else { return }
        startTimer()
    }

    func stopTimer() {
        rhythmTimer?.invalidate()
        rhythmTimer = nil
    }

    private func advanceBeat() {
        guard !outcome.isFinished, activeUltimate == nil else {
            stopTimer()
            return
        }

        switch beat {
        case 0, 3:
            if beat == 3 {
                turnCount += 1
            }
            beat = 1
            revealedPlayerMove = nil
            revealedCpuMove = nil
            playerExpression = .normal
            cpuExpression = .normal
            calloutText = "💥 バン！"
            statusDetailText = "👏 リズム 1 / 3 — コマンド受付中"
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 1:
            beat = 2
            calloutText = "💥 バン！"
            statusDetailText = "👏 リズム 2 / 3 — 次でアクション激突！"
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 2:
            beat = 3
            calloutText = "⚡️ アクション！"
            resolveClash()

        default:
            beat = 1
        }
    }

    // MARK: - Clash Resolution (HP=3 / 被弾チャージ-1 / お手つき無防備 / 4チャージ一撃必殺)
    private func resolveClash() {
        // 1. プレイヤー行動の解決（チャージ不足なら無防備 .fumble）
        let pMove: ResolvedMove
        if playerCharge < selectedAction.cost {
            pMove = .fumble(attempted: selectedAction)
            HapticManager.playRigid(enabled: isHapticsEnabled)
        } else {
            playerCharge -= selectedAction.cost
            pMove = .valid(selectedAction)
        }

        // 2. CPU行動の解決
        let cMove = decideCpuMove()
        if case .valid(let cAct) = cMove {
            cpuCharge = max(0, cpuCharge - cAct.cost)
        }

        revealedPlayerMove = pMove
        revealedCpuMove = cMove

        // 3. 4チャージ一撃必殺（メガビーム）判定
        let playerUlt = (pMove == .valid(.megaBeam))
        let cpuUlt = (cMove == .valid(.megaBeam))

        if playerUlt && cpuUlt {
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            calloutText = "🌟⚡️ 超激突相殺！！"
            statusDetailText = "両者の4チャージ必殺ビームが空間ごと相殺した！！"
            resetSelectionIfUnaffordable()
            return
        } else if playerUlt {
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            triggerUltimateSequence(character: .reo, isPlayer: true)
            return
        } else if cpuUlt {
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            triggerUltimateSequence(character: currentEnemy, isPlayer: false)
            return
        }

        if case .valid = pMove {
            HapticManager.playHeavy(enabled: isHapticsEnabled)
        }

        // 4. 通常ビーム / バリア / チャージ / お手つき無防備 の勝敗・ダメージ解決
        let playerFiredBeam = (pMove == .valid(.beam))
        let cpuFiredBeam = (cMove == .valid(.beam))

        if playerFiredBeam && cpuFiredBeam {
            calloutText = "💥 ビーム相殺！"
            statusDetailText = "両者のビームが激突して相殺！"
        } else if playerFiredBeam && cMove.isVulnerableToBeam {
            // プレイヤーの通常ビームが命中！（敵HP -1 ＆ 敵の蓄積チャージも -1）
            cpuHP = max(0, cpuHP - 1)
            cpuCharge = max(0, cpuCharge - 1)
            playerExpression = .fun
            cpuExpression = .sad
            calloutText = "💥 ビーム直撃！！"

            if case .fumble = cMove {
                statusDetailText = "敵がお手つき無防備！敵HP -1 ＆ 敵チャージ -1！"
            } else {
                statusDetailText = "チャージ中の敵を撃ち抜いた！敵HP -1 ＆ 敵チャージ -1！"
            }

            if cpuHP <= 0 {
                finishMatch(playerWon: true, reason: "\(currentEnemy.codeName) の体力を削り切って撃破！")
                return
            }
        } else if cpuFiredBeam && pMove.isVulnerableToBeam {
            // 敵の通常ビームを被弾！（ReoのHP -1 ＆ Reoの蓄積チャージも -1）
            playerHP = max(0, playerHP - 1)
            playerCharge = max(0, playerCharge - 1)
            playerExpression = .sad
            cpuExpression = .fun
            calloutText = "💥 被弾ダメージ！！"

            if case .fumble(let attempted) = pMove {
                statusDetailText = "⚠️ お手つき(\(attempted.label)不発)の無防備に被弾！HP -1 ＆ チャージ -1！"
            } else {
                statusDetailText = "チャージ中に被弾！HP -1 ＆ チャージ -1！"
            }

            if playerHP <= 0 {
                finishMatch(playerWon: false, reason: "ビームを3回被弾して力尽きた...")
                return
            }
        } else if playerFiredBeam && cMove == .valid(.barrier) {
            calloutText = "🛡️ ガードされた！"
            statusDetailText = "\(currentEnemy.codeName) のバリアに通常ビームを防がれた！"
        } else if cpuFiredBeam && pMove == .valid(.barrier) {
            calloutText = "🛡️ ナイスガード！"
            statusDetailText = "敵の通常ビームをバリアで完全防御！"
            playerExpression = .fun
        } else {
            // 互いに攻撃命中なし -> チャージを選んでいた側のみチャージ +1
            var notes: [String] = []
            if pMove == .valid(.charge) {
                playerCharge = min(maxCharge, playerCharge + 1)
                notes.append("Reo チャージ+1")
            } else if case .fumble(let attempted) = pMove {
                playerExpression = .sad
                notes.append("⚠️Reo お手つき無防備(\(attempted.label)不発)")
            } else if pMove == .valid(.barrier) {
                notes.append("Reo バリア")
            }

            if cMove == .valid(.charge) {
                cpuCharge = min(maxCharge, cpuCharge + 1)
                notes.append("\(currentEnemy.codeName) チャージ+1")
            } else if case .fumble = cMove {
                cpuExpression = .sad
                notes.append("\(currentEnemy.codeName) お手つき無防備！")
            } else if cMove == .valid(.barrier) {
                notes.append("\(currentEnemy.codeName) バリア")
            }

            calloutText = playerCharge >= maxCharge ? "🌟 必殺READY!!" : "⚡️ 読み合い継続"
            statusDetailText = notes.joined(separator: " / ")
        }

        resetSelectionIfUnaffordable()
    }

    private func resetSelectionIfUnaffordable() {
        if !outcome.isFinished && playerCharge < selectedAction.cost {
            selectedAction = .charge
        }
    }

    // MARK: - Ultimate Cut-in & Video Sequence
    private func triggerUltimateSequence(character: CharacterProfile, isPlayer: Bool) {
        stopTimer()
        activeUltimate = UltimatePresentation(character: character, isPlayer: isPlayer)
    }

    /// カットイン＆必殺動画の再生終了後に呼ばれ、一撃必殺で勝敗を確定する
    func completeUltimateSequence() {
        guard let ult = activeUltimate else { return }
        activeUltimate = nil

        if ult.isPlayer {
            cpuHP = 0
            playerExpression = .fun
            cpuExpression = .sad
            calloutText = "🌟 一撃必殺 K.O.!!"
            finishMatch(playerWon: true, reason: "4チャージ超必殺ビーム炸裂！一撃必殺で \(currentEnemy.codeName) を撃破！")
        } else {
            playerHP = 0
            playerExpression = .sad
            cpuExpression = .fun
            calloutText = "💥 一撃必殺 K.O..."
            finishMatch(playerWon: false, reason: "\(currentEnemy.codeName) の一撃必殺ビームに敗れた...")
        }
    }

    private func finishMatch(playerWon: Bool, reason: String) {
        stopTimer()
        statusDetailText = reason

        if gameMode == .practice {
            outcome = .practiceClear(isWin: playerWon, reason: reason)
            return
        }

        if playerWon {
            winStreak += 1
            PlayerIconManager.shared.recordKumiteVictory(
                enemy: currentEnemy,
                loopNumber: currentLoopNumber,
                newWinStreak: winStreak
            )
            GameCenterManager.shared.recordWinStreak(winStreak)
            outcome = .stageClear(enemyName: currentEnemy.codeName, reason: reason)
        } else {
            GameCenterManager.shared.recordWinStreak(winStreak)
            outcome = .gameOver(finalStreak: winStreak, reason: reason)
        }
    }

    // MARK: - Enemy Tiered AI Logic (お手つきは一切しない仕様)
    private func decideCpuMove() -> ResolvedMove {
        let chosenAction = selectCpuAction()
        // 万一にも気力不足の行動が選ばれないよう安全ガード（お手つき防止保証）
        if cpuCharge < chosenAction.cost {
            return .valid(.charge)
        }
        return .valid(chosenAction)
    }

    private func selectCpuAction() -> GameAction {
        let traits = currentEnemy.ai
        // 2周目以降はわずかに判断精度が上昇
        let loopBonus = min(0.15, Double(currentLoopNumber - 1) * 0.05)
        let precision = min(0.99, traits.readPrecision + loopBonus)

        // 1. CPUが4チャージ満タンの時：高確率で一撃必殺メガビームを発動！
        if cpuCharge >= maxCharge {
            let fireUltProb = 0.65 + (traits.ultimateGreed * 0.32)
            if Double.random(in: 0..<1.0) < min(0.97, fireUltProb) {
                return .megaBeam
            }
            return .beam
        }

        // 2. プレイヤーが4チャージ（一撃必殺可能）の時：賢い敵はバリアが貫通されると知り先制ビームを撃つ
        if playerCharge >= maxCharge && cpuCharge >= 1 {
            if Double.random(in: 0..<1.0) < precision {
                return .beam
            }
        }

        // 3. プレイヤーが3チャージ（あと1で一撃必殺！）の時：賢い敵はビームでチャージ-1削りを狙う
        if playerCharge == (maxCharge - 1) && cpuCharge >= 1 {
            if Double.random(in: 0..<1.0) < (precision * 0.80) {
                return .beam
            }
        }

        // 4. CPUがチャージ 0 の時（チャージ または バリア のみ選択＝絶対にお手つきしない）
        if cpuCharge == 0 {
            if playerCharge == 0 {
                // 相手も0チャージなら攻撃される心配がない：賢い敵は確実にチャージする
                if Double.random(in: 0..<1.0) < (0.55 + precision * 0.43) {
                    return .charge
                }
                return .barrier
            } else {
                // 相手にチャージがある時：バリア警戒度に応じてガードか強気チャージ
                let guardProb = 0.20 + (traits.defenseAwareness * 0.55)
                return Double.random(in: 0..<1.0) < guardProb ? .barrier : .charge
            }
        }

        // 5. CPUがチャージ 1〜3 の通常戦術
        if playerCharge == 0 {
            // 相手は攻撃不可：賢い敵ほどバリアを張らず、攻撃か必殺用チャージを選ぶ
            let smartChoice = Double.random(in: 0..<1.0) < (0.45 + precision * 0.52)
            if smartChoice {
                let chargeBias = traits.ultimateGreed * 0.65
                return Double.random(in: 0..<1.0) < chargeBias ? .charge : .beam
            } else {
                return .barrier
            }
        } else {
            // お互いに1〜3チャージある白熱の読み合い
            let wBeam = traits.aggression + (playerHP == 1 ? 0.25 : 0.0)
            let wBarrier = traits.defenseAwareness
            let wCharge = traits.ultimateGreed * 0.75
            let sum = max(0.01, wBeam + wBarrier + wCharge)
            let r = Double.random(in: 0..<sum)

            if r < wBeam {
                return .beam
            } else if r < (wBeam + wBarrier) {
                return .barrier
            } else {
                return .charge
            }
        }
    }
}
