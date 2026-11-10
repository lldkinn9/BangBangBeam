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

/// 戦闘開始前の演出フェーズ（事前VS画面 → ゲーム画面へ切替 → Ready → Go!! → 3拍開始）
enum PreBattleIntroPhase: Equatable, Sendable {
    case vsScreen
    case ready
    case go
    case none
}

/// 出した手の相手との勝敗に応じて、Reoの顔の左側の空きスペースに大きく表示する英字判定（該当しない場合は非表示）
enum PlayerClashCallout: Equatable, Sendable {
    /// ガードが成立 → Good!!（シアンカラー）
    case goodGuard
    /// ビームが相手にあたる → Nice!!（黄色）
    case niceHit
    /// チャージ成功 → Charge（ネオングリーン）
    case chargeSuccess
    /// 相手のビーム被弾 → Bad（赤）
    case badHit

    var displayText: String {
        switch self {
        case .goodGuard:
            return "Good!!"
        case .niceHit:
            return "Nice!!"
        case .chargeSuccess:
            return "Charge"
        case .badHit:
            return "Bad"
        }
    }

    var primaryColor: Color {
        switch self {
        case .goodGuard:
            return Color.cyberCyan
        case .niceHit:
            return Color(red: 1.0, green: 0.90, blue: 0.14)
        case .chargeSuccess:
            return Color.cyberEmerald
        case .badHit:
            return Color.cyberDanger
        }
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

/// 製品版ゲームエンジン（KUMITE 勝ち抜き・事前VS画面＋Ready/Go!!導入・HP3制・被弾チャージ-1・4チャージ即時ULTIMATE発動）
@Observable
@MainActor
final class GameEngine {
    // MARK: - Persistence Keys
    private let initialPracticeDoneKey = "BangBangBeam.hasCompletedInitialPractice"
    private let tempoPresetKey = "BangBangBeam.tempoPreset"
    private let savedKumiteActiveKey = "BangBangBeam.hasSavedKumiteSession"
    private let savedKumiteStreakKey = "BangBangBeam.savedKumiteWinStreak"
    private let savedKumiteRevivesKey = "BangBangBeam.savedKumiteRemainingRevives"
    private let savedKumiteMaxRevivesKey = "BangBangBeam.savedKumiteMaxRevives"
    private let savedKumitePendingReviveKey = "BangBangBeam.savedKumitePendingRevive"

    // MARK: - Navigation & Mode
    var currentScreen: AppScreen = .title
    var gameMode: GameMode = .kumite
    var isFirstLaunchTutorial: Bool = false

    // MARK: - Constants & Settings
    let maxHP: Int = 3
    let maxCharge: Int = 4
    let maxRevivesPerRun: Int = 2

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
            if rhythmTimer != nil {
                restartTimer()
            }
        }
    }

    var isHapticsEnabled: Bool = true

    // MARK: - KUMITE Progression State
    var winStreak: Int = 0
    var remainingRevives: Int = 2
    var currentRunMaxRevives: Int = 2
    var hasSavedKumiteSession: Bool = false
    /// 敗退後に復活回数を残してタイトルへ戻った保留状態かどうか
    var isPendingKumiteRevive: Bool = false
    /// 敗退保留状態からKUMITEを押した際の確認ポップアップ表示フラグ
    var isShowingPendingRevivePrompt: Bool = false
    var currentEnemy: CharacterProfile = CharacterProfile.kumiteRoster[0]
    var currentLoopNumber: Int = 1
    var currentStageInLoop: Int = 1
    var totalStagesInCurrentLoop: Int = 11

    // MARK: - Battle Live State
    /// 戦闘開始前の演出状態（.vsScreen → .ready → .go → .none）
    var preBattlePhase: PreBattleIntroPhase = .none

    /// 現在の拍（0: 開始待機, 1: バン！, 2: バン！, 3: アクション激突）
    var beat: Int = 0
    var turnCount: Int = 1

    /// 赤いタイムバーが右から左へ消えていく入力受付区間（1拍目開始〜3拍目突入までの 2拍分）の開始時刻
    var turnWindowStartDate: Date? = nil

    var playerHP: Int = 3
    var cpuHP: Int = 3

    var playerCharge: Int = 0
    var cpuCharge: Int = 0

    var playerExpression: CharacterExpression = .normal
    var cpuExpression: CharacterExpression = .normal

    /// プレイヤーが次のアクションに向けて予約している通常コマンド（CHARGE / BEAM / BARRIER）
    var selectedAction: GameAction = .charge

    /// 直近の3拍目で確定・公開された実効アクション
    var revealedPlayerMove: ResolvedMove? = nil
    var revealedCpuMove: ResolvedMove? = nil

    /// 出した手の勝敗に応じてReoの顔の左側に大きく表示する判定テキスト（Good!! / Nice!! / Charge / Bad / nil）
    var playerClashCallout: PlayerClashCallout? = nil

    var calloutText: String = "Ready"
    var statusDetailText: String = "赤いバーが消える前にコマンドを選択！"

    var outcome: BattleOutcome = .ongoing

    /// 4チャージ一撃必殺発動中のカットイン＆動画演出状態
    var activeUltimate: UltimatePresentation? = nil

    /// 毎バトル前のVS画面で現在選択中の1戦限定ブーストアイテム（ハート・電池・防弾チョッキのうち最大1種類1個）
    var selectedVsBattleItem: BattleItem? = nil

    /// アイテム使用・自動防御時のミニトースト表示テキスト
    var itemEffectFeedbackText: String? = nil
    private var itemFeedbackTask: Task<Void, Never>? = nil

    /// プレイヤーの現在の最大体力（VS画面でハートを使用したバトルは 4、通常時は 3）
    var playerMaxHP: Int {
        (gameMode == .kumite && ItemManager.shared.activeBattleBoostItem == .heart) ? (maxHP + 1) : maxHP
    }

    // MARK: - Timer
    private var rhythmTimer: Timer? = nil
    private var pendingTimerTask: Task<Void, Never>? = nil

    var beatInterval: TimeInterval {
        let effectiveBPM = (gameMode == .practice) ? TempoPreset.standard.bpmValue : bpm
        return 60.0 / max(50.0, min(effectiveBPM, 160.0))
    }

    /// 1ターンあたりのコマンド受付時間（1拍目開始から3拍目発動までの2拍分）
    var inputWindowDuration: TimeInterval {
        beatInterval * 2.0
    }

    /// 自動リズムタイマーが稼働中かどうか（タイムバーの連続アニメーション判定用）
    var isRhythmRunning: Bool {
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

        if UserDefaults.standard.bool(forKey: savedKumiteActiveKey) {
            let loadedStreak = max(0, UserDefaults.standard.integer(forKey: savedKumiteStreakKey))
            let loadedMaxRevives = max(maxRevivesPerRun, UserDefaults.standard.integer(forKey: savedKumiteMaxRevivesKey))
            let savedRevives = min(loadedMaxRevives, max(0, UserDefaults.standard.integer(forKey: savedKumiteRevivesKey)))
            let pendingRevive = UserDefaults.standard.bool(forKey: savedKumitePendingReviveKey)

            if pendingRevive && (loadedStreak <= 0 || savedRevives <= 0) {
                clearSavedKumiteSession()
            } else if loadedStreak > 0 {
                self.hasSavedKumiteSession = true
                self.winStreak = loadedStreak
                self.currentRunMaxRevives = loadedMaxRevives
                self.remainingRevives = savedRevives
                self.isPendingKumiteRevive = pendingRevive
            } else {
                clearSavedKumiteSession()
            }
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

    /// 起動完了時のオーディオ・サービス・画像キャッシュ初期化フック
    func onAppAppear() {
        GameCenterManager.shared.authenticateLocalPlayer()
        AdManager.shared.startSDKAndRequestATT()
        HapticManager.warmUp(enabled: isHapticsEnabled)
        AssetPrewarmer.warmUpForInitialLaunch(startingStreak: winStreak)

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
    /// タイトル等からKUMITEを開始（勝利中断時はそのまま再開、敗退保留時は確認ポップアップを表示）
    func startOrResumeKumite() {
        if hasSavedKumiteSession && winStreak > 0 {
            if isPendingKumiteRevive {
                if remainingRevives > 0 {
                    AdManager.shared.rewardedAdStatusMessage = nil
                    isShowingPendingRevivePrompt = true
                    return
                } else {
                    startKumiteFromBeginning()
                    return
                }
            }

            let needsTransitionSettle = (currentScreen != .kumiteBattle)
            markTutorialCompleted()
            stopTimer()
            HapticManager.warmUp(enabled: isHapticsEnabled)
            gameMode = .kumite
            let previousMedkit = ItemManager.shared.activeRunMedkit
            let loadout = ItemManager.shared.activatePendingLoadoutForResumedKumite()
            if previousMedkit == nil, let newlyAppliedMedkit = loadout.medkit {
                currentRunMaxRevives += newlyAppliedMedkit.bonusRevives
                remainingRevives += newlyAppliedMedkit.bonusRevives
            }
            saveKumiteSession(isPendingRevive: false)
            loadEnemyForCurrentStreak()
            setupMatchState(enemy: currentEnemy)
            currentScreen = .kumiteBattle
            SoundManager.shared.playBattleBGM(forceNewRandom: true)
            startPreBattleIntroThenRhythm(needsTransitionSettle: needsTransitionSettle)
        } else {
            startKumiteFromBeginning()
        }
    }

    /// KUMITE（勝ち抜きサバイバル）を最初から（連勝0・基本復活2回＋救急キットボーナス）開始
    func startKumiteFromBeginning() {
        let needsTransitionSettle = (currentScreen != .kumiteBattle)
        isShowingPendingRevivePrompt = false
        markTutorialCompleted()
        stopTimer()
        HapticManager.warmUp(enabled: isHapticsEnabled)
        clearSavedKumiteSession(clearActiveItems: false)
        gameMode = .kumite
        winStreak = 0
        let loadout = ItemManager.shared.activateLoadoutForNewKumiteRun()
        let bonusRevives = loadout.medkit?.bonusRevives ?? 0
        currentRunMaxRevives = maxRevivesPerRun + bonusRevives
        remainingRevives = currentRunMaxRevives
        loadEnemyForCurrentStreak()
        setupMatchState(enemy: currentEnemy)
        currentScreen = .kumiteBattle
        SoundManager.shared.playBattleBGM(forceNewRandom: true)
        startPreBattleIntroThenRhythm(needsTransitionSettle: needsTransitionSettle)
    }

    /// 動画広告（リワード広告）視聴完了後、現在の連勝記録を維持したまま負けたバトルをやり直す（敗退リザルト画面・タイトル再開確認ポップアップ共通）
    func reviveCurrentKumiteMatch() {
        guard remainingRevives > 0 else { return }
        let needsTransitionSettle = (currentScreen != .kumiteBattle)
        isShowingPendingRevivePrompt = false
        markTutorialCompleted()
        remainingRevives -= 1
        ItemManager.shared.markReviveUsedInActiveRun()
        isPendingKumiteRevive = false
        if winStreak > 0 {
            saveKumiteSession(isPendingRevive: false)
        }
        stopTimer()
        HapticManager.warmUp(enabled: isHapticsEnabled)
        gameMode = .kumite
        loadEnemyForCurrentStreak()
        setupMatchState(enemy: currentEnemy)
        if needsTransitionSettle {
            currentScreen = .kumiteBattle
            SoundManager.shared.playBattleBGM(forceNewRandom: true)
        } else {
            SoundManager.shared.playBattleBGM(forceNewRandom: false)
        }
        startPreBattleIntroThenRhythm(needsTransitionSettle: needsTransitionSettle)
    }

    /// KUMITEで敵撃破後、BGMはリセットせずそのまま継続再生で次の敵へ進む（事前VS画面 → Ready → Go!! → 3拍開始）
    func advanceToNextKumiteStage() {
        stopTimer()
        loadEnemyForCurrentStreak()
        setupMatchState(enemy: currentEnemy)
        SoundManager.shared.playBattleBGM(forceNewRandom: false)
        startPreBattleIntroThenRhythm(needsTransitionSettle: false)
    }

    /// PRACTICE（本番バトルUI上の吹き出しルール学習）を開始
    func startPracticeMode() {
        stopTimer()
        gameMode = .practice
        setupMatchState(enemy: CharacterProfile.kumiteRoster[0])
        preBattlePhase = .none
        currentScreen = .practiceTutorial
        SoundManager.shared.playBattleBGM(forceNewRandom: true)
    }

    /// ルール学習完了後の「練習」ボタン押下時：「標準」速度で GEEK との1戦練習バトルを開始（Ready → Go!! → 3拍開始）
    func startPracticeBattleMatch() {
        stopTimer()
        gameMode = .practice
        HapticManager.warmUp(enabled: isHapticsEnabled)
        setupMatchState(enemy: CharacterProfile.kumiteRoster[0])
        SoundManager.shared.playButtonSE()
        SoundManager.shared.playBattleBGM(forceNewRandom: false)

        pendingTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // 1.「Ready」表示
            self.preBattlePhase = .ready
            self.calloutText = "Ready"
            self.statusDetailText = "練習バトル（標準速度）— コマンドを準備しよう！"
            HapticManager.playLight(enabled: self.isHapticsEnabled)
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled, !self.outcome.isFinished, self.activeUltimate == nil else { return }

            // 2.「Go!!」表示
            self.preBattlePhase = .go
            self.calloutText = "Go!!"
            self.statusDetailText = "バトル開始！！"
            HapticManager.playHeavy(enabled: self.isHapticsEnabled)
            try? await Task.sleep(for: .milliseconds(620))
            guard !Task.isCancelled, !self.outcome.isFinished, self.activeUltimate == nil else { return }

            // 3.「標準」速度で3拍のリズムループ開始
            self.pendingTimerTask = nil
            self.preBattlePhase = .none
            self.scheduleCommonRunLoopTimer()
            self.advanceBeat()
        }
    }

    /// タイトル画面へ戻る（勝利後、または敗退後でも復活回数が残っている場合に限り連勝数と復活回数を維持保存）
    func returnToTitle() {
        markTutorialCompleted()
        stopTimer()
        preBattlePhase = .none
        if gameMode == .kumite {
            if case .stageClear = outcome {
                saveKumiteSession(isPendingRevive: false)
            } else if case .gameOver = outcome, winStreak > 0, remainingRevives > 0 {
                saveKumiteSession(isPendingRevive: true)
            } else {
                clearSavedKumiteSession(clearActiveItems: true)
                winStreak = 0
                currentRunMaxRevives = maxRevivesPerRun
                remainingRevives = maxRevivesPerRun
            }
        }
        activeUltimate = nil
        selectedVsBattleItem = nil
        ItemManager.shared.clearPerBattleBoostItem()
        itemEffectFeedbackText = nil
        SoundManager.shared.setDucked(false)
        currentScreen = .title
        SoundManager.shared.playTitleBGM()
    }

    private func saveKumiteSession(isPendingRevive: Bool = false) {
        hasSavedKumiteSession = true
        isPendingKumiteRevive = isPendingRevive
        UserDefaults.standard.set(true, forKey: savedKumiteActiveKey)
        UserDefaults.standard.set(winStreak, forKey: savedKumiteStreakKey)
        UserDefaults.standard.set(remainingRevives, forKey: savedKumiteRevivesKey)
        UserDefaults.standard.set(currentRunMaxRevives, forKey: savedKumiteMaxRevivesKey)
        UserDefaults.standard.set(isPendingRevive, forKey: savedKumitePendingReviveKey)
    }

    private func clearSavedKumiteSession(clearActiveItems: Bool = true) {
        hasSavedKumiteSession = false
        isPendingKumiteRevive = false
        UserDefaults.standard.set(false, forKey: savedKumiteActiveKey)
        UserDefaults.standard.removeObject(forKey: savedKumiteStreakKey)
        UserDefaults.standard.removeObject(forKey: savedKumiteRevivesKey)
        UserDefaults.standard.removeObject(forKey: savedKumiteMaxRevivesKey)
        UserDefaults.standard.removeObject(forKey: savedKumitePendingReviveKey)
        if clearActiveItems {
            ItemManager.shared.clearFinishedKumiteRunLoadout()
        }
    }

    // MARK: - Item Shop & Battle Active Item Actions
    /// ITEM画面から救急キットを交換・即時適用（中断中の連勝セッションがある場合はその残り復活回数にも即加算）
    @discardableResult
    func exchangeAndApplyMedkit(_ medkit: BattleItem) -> Bool {
        guard ItemManager.shared.exchangeAndApplyMedkit(medkit, hasSavedKumiteSession: hasSavedKumiteSession) else {
            return false
        }
        if hasSavedKumiteSession {
            currentRunMaxRevives += medkit.bonusRevives
            remainingRevives += medkit.bonusRevives
            saveKumiteSession(isPendingRevive: isPendingKumiteRevive)
        }
        return true
    }

    /// バトル画面のREOハート上に表示された使用型アイテム（回復薬・エナジードリンク）をタップした瞬間に即時適用する
    func useEquippedBattleItem() {
        guard gameMode == .kumite,
              preBattlePhase == .none,
              !outcome.isFinished,
              activeUltimate == nil,
              let item = ItemManager.shared.activeRunCarryInItem,
              item.isTapUsableInBattle else {
            return
        }

        switch item {
        case .healingPotion:
            guard playerHP < playerMaxHP else {
                HapticManager.playLight(enabled: isHapticsEnabled)
                showItemEffectFeedback("体力はすでに満タンです")
                return
            }
            ItemManager.shared.consumeActiveRunCarryInItem()
            playerHP = playerMaxHP
            if playerExpression == .sad {
                playerExpression = .normal
            }
            SoundManager.shared.playButtonSE()
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            showItemEffectFeedback("💊 体力全回復！！")

        case .energyDrink:
            guard playerCharge < maxCharge else {
                HapticManager.playLight(enabled: isHapticsEnabled)
                showItemEffectFeedback("チャージはすでに満タンです")
                return
            }
            ItemManager.shared.consumeActiveRunCarryInItem()
            playerCharge = min(maxCharge, playerCharge + 2)
            if playerCharge >= maxCharge {
                selectedAction = .charge
            }
            SoundManager.shared.playButtonSE()
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            showItemEffectFeedback("⚡ チャージ +2！！")

        default:
            break
        }
    }

    private func showItemEffectFeedback(_ message: String) {
        itemFeedbackTask?.cancel()
        itemEffectFeedbackText = message
        itemFeedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(1600))
            guard !Task.isCancelled else { return }
            if self?.itemEffectFeedbackText == message {
                self?.itemEffectFeedbackText = nil
            }
        }
    }

    // MARK: - Player Input
    /// 通常3コマンド（CHARGE / BEAM / BARRIER）の予約選択（チャージ不足のBEAMも選択可能で、発動時に無防備のお手つきになる）
    func selectCommand(_ action: GameAction) {
        guard !outcome.isFinished, activeUltimate == nil, preBattlePhase != .vsScreen else { return }
        guard action != .megaBeam else {
            triggerPlayerUltimateImmediately()
            return
        }
        selectedAction = action
        HapticManager.playMedium(enabled: isHapticsEnabled)
    }

    /// 4チャージ到達時に出現する金色「ULTIMATE」ボタンを押した瞬間に、リズム待機なしで即座にカットイン→必殺アニメーションを発動する
    func triggerPlayerUltimateImmediately() {
        guard !outcome.isFinished, activeUltimate == nil, preBattlePhase == .none, playerCharge >= maxCharge else { return }
        stopTimer()
        playerCharge = 0
        selectedAction = .charge
        revealedPlayerMove = .valid(.megaBeam)
        playerClashCallout = nil
        calloutText = "🌟 ULTIMATE!!"
        statusDetailText = "REO 一撃必殺発動！！"
        HapticManager.playHeavy(enabled: isHapticsEnabled)
        triggerUltimateSequence(character: .reo, isPlayer: true)
    }

    // MARK: - Match Setup & Pre-Battle Intro Sequence
    private func loadEnemyForCurrentStreak() {
        let info = CharacterProfile.enemy(forStreak: winStreak)
        currentEnemy = info.profile
        currentLoopNumber = info.loopNumber
        currentStageInLoop = info.stageInLoop
        totalStagesInCurrentLoop = info.totalStagesInLoop
        AssetPrewarmer.warmUpUpcomingEnemies(currentStreak: winStreak)
    }

    private func setupMatchState(enemy: CharacterProfile) {
        currentEnemy = enemy
        beat = 0
        turnCount = 1
        turnWindowStartDate = nil
        ItemManager.shared.clearPerBattleBoostItem()
        selectedVsBattleItem = nil
        playerHP = maxHP
        cpuHP = maxHP
        playerCharge = 0
        cpuCharge = 0
        playerExpression = .normal
        cpuExpression = .normal
        selectedAction = .charge
        revealedPlayerMove = nil
        revealedCpuMove = nil
        playerClashCallout = nil
        activeUltimate = nil
        itemEffectFeedbackText = nil
        outcome = .ongoing
        calloutText = "Ready"
        statusDetailText = gameMode == .practice
            ? "赤いバーが消える前にコマンドを選び、アクション発動！"
            : "VS \(enemy.codeName) — 赤いバーが消える前にコマンドを選べ！"
    }

    /// KUMITE戦闘開始前の演出シーケンス：1. 事前VS画面で待機（「START」押下でバトル画面へ遷移）
    private func startPreBattleIntroThenRhythm(needsTransitionSettle: Bool) {
        stopTimer()
        selectedVsBattleItem = nil
        preBattlePhase = .vsScreen
        HapticManager.playLight(enabled: isHapticsEnabled)
    }

    /// 事前VS画面の「START」ボタン押下時：選択されていた1戦限定アイテムをストックから1個消費・反映し、2. ゲーム画面に切替＋「Ready」 → 3.「Go!!」 → 4. 3拍開始
    func confirmVsScreenStart() {
        guard preBattlePhase == .vsScreen, !outcome.isFinished, activeUltimate == nil else { return }
        stopTimer()
        SoundManager.shared.playButtonSE()
        HapticManager.playHeavy(enabled: isHapticsEnabled)

        if gameMode == .kumite {
            let activatedBoost = ItemManager.shared.consumeAndActivateVsBattleBoost(selectedVsBattleItem)
            selectedVsBattleItem = nil
            if activatedBoost == .heart {
                playerHP = maxHP + 1
            } else if activatedBoost == .battery {
                playerCharge = 1
            }
        }

        pendingTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // 2. ゲーム画面に切替 ＆「Ready」表示
            self.preBattlePhase = .ready
            self.calloutText = "Ready"
            self.statusDetailText = "VS \(self.currentEnemy.codeName) — コマンドを準備せよ！"
            HapticManager.playLight(enabled: self.isHapticsEnabled)
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled, !self.outcome.isFinished, self.activeUltimate == nil else { return }

            // 3.「Go!!」表示
            self.preBattlePhase = .go
            self.calloutText = "Go!!"
            self.statusDetailText = "バトル開始！！"
            HapticManager.playHeavy(enabled: self.isHapticsEnabled)
            try? await Task.sleep(for: .milliseconds(620))
            guard !Task.isCancelled, !self.outcome.isFinished, self.activeUltimate == nil else { return }

            // 4. 3拍のリズムループ開始（即座に1拍目＆赤いタイムバー開始）
            self.pendingTimerTask = nil
            self.preBattlePhase = .none
            self.scheduleCommonRunLoopTimer()
            self.advanceBeat()
        }
    }

    private func startTimer(initialDelay: TimeInterval = 0.0) {
        stopTimer()
        if initialDelay > 0 {
            pendingTimerTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(initialDelay))
                guard !Task.isCancelled, let self else { return }
                self.pendingTimerTask = nil
                guard !self.outcome.isFinished, self.activeUltimate == nil else { return }
                self.scheduleCommonRunLoopTimer()
            }
        } else {
            scheduleCommonRunLoopTimer()
        }
    }

    private func scheduleCommonRunLoopTimer() {
        let interval = beatInterval
        if beat == 1 {
            turnWindowStartDate = Date()
        } else if beat == 2 {
            turnWindowStartDate = Date().addingTimeInterval(-interval)
        } else {
            turnWindowStartDate = nil
        }

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceBeat()
            }
        }
        timer.tolerance = min(0.02, interval * 0.04)
        RunLoop.main.add(timer, forMode: .common)
        rhythmTimer = timer
    }

    private func restartTimer() {
        guard rhythmTimer != nil else { return }
        startTimer()
    }

    func stopTimer() {
        pendingTimerTask?.cancel()
        pendingTimerTask = nil
        rhythmTimer?.invalidate()
        rhythmTimer = nil
        turnWindowStartDate = nil
    }

    private func advanceBeat() {
        guard !outcome.isFinished, activeUltimate == nil, preBattlePhase == .none else {
            stopTimer()
            return
        }

        switch beat {
        case 0, 3:
            if beat == 3 {
                turnCount += 1
            }
            beat = 1
            if isRhythmRunning {
                turnWindowStartDate = Date()
            } else {
                turnWindowStartDate = nil
            }
            revealedPlayerMove = nil
            revealedCpuMove = nil
            playerClashCallout = nil
            playerExpression = playerHP == 1 ? .sad : .normal
            cpuExpression = cpuHP == 1 ? .sad : .normal
            calloutText = "💥 バン！"
            statusDetailText = playerCharge >= maxCharge
                ? "🌟 ULTIMATE ボタンを押して一撃必殺を放て！"
                : "赤いバーが消える前にコマンドを選択！"
            SoundManager.shared.playSuperClapSE()
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 1:
            beat = 2
            if isRhythmRunning && turnWindowStartDate == nil {
                turnWindowStartDate = Date().addingTimeInterval(-beatInterval)
            }
            calloutText = "💥 バン！"
            statusDetailText = playerCharge >= maxCharge
                ? "🌟 今すぐ ULTIMATE ボタンをタップ！！"
                : "まもなくアクション激突！"
            SoundManager.shared.playSuperClapSE()
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 2:
            beat = 3
            turnWindowStartDate = nil
            calloutText = "⚡️ アクション！"
            SoundManager.shared.playHandRevealSE()
            resolveClash()

        default:
            beat = 1
        }
    }

    // MARK: - Clash Resolution (HP=3 / 被弾チャージ-1 / お手つき無防備 / 4チャージ一撃必殺)
    private func resolveClash() {
        playerClashCallout = nil

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

        // 3. 4チャージ一撃必殺判定
        let playerUlt = (pMove == .valid(.megaBeam))
        let cpuUlt = (cMove == .valid(.megaBeam))

        if playerUlt && cpuUlt {
            HapticManager.playHeavy(enabled: isHapticsEnabled)
            calloutText = "🌟⚡️ 超激突相殺！！"
            statusDetailText = "両者の4チャージ必殺技が空間ごと相殺した！！"
            resetSelectionIfNeeded()
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
            // プレイヤーの通常ビームが命中！（敵HP -1 ＆ 敵の蓄積チャージも -1）→ Nice!!（黄色）
            playerClashCallout = .niceHit
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
            if gameMode == .kumite && ItemManager.shared.activeBattleBoostItem == .bulletproofVest {
                // 防弾チョッキが発動し相手のビームを一度だけ完全防御！
                ItemManager.shared.consumeActiveBattleVestIfPresent()
                playerClashCallout = .goodGuard
                playerExpression = .fun
                calloutText = "🛡️ チョッキで防御！！"
                statusDetailText = "防弾チョッキが敵のビームを防いだ！（ダメージ0）"
                HapticManager.playHeavy(enabled: isHapticsEnabled)
                showItemEffectFeedback("🛡️ 防弾チョッキでビーム防御！")
            } else {
                // 敵の通常ビームを被弾！（ReoのHP -1 ＆ Reoの蓄積チャージも -1）→ Bad（赤）
                playerClashCallout = .badHit
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
                    finishMatch(playerWon: false, reason: "ビームを被弾して力尽きた...")
                    return
                }
            }
        } else if playerFiredBeam && cMove == .valid(.barrier) {
            calloutText = "🛡️ ガードされた！"
            statusDetailText = "\(currentEnemy.codeName) のバリアに通常ビームを防がれた！"
        } else if cpuFiredBeam && pMove == .valid(.barrier) {
            // ガードが成立 → Good!!（シアンカラー）
            playerClashCallout = .goodGuard
            calloutText = "🛡️ ナイスガード！"
            statusDetailText = "敵の通常ビームをバリアで完全防御！"
            playerExpression = .fun
        } else {
            // 互いに攻撃命中なし -> チャージを選んでいた側のみチャージ +1
            var notes: [String] = []
            if pMove == .valid(.charge) {
                // チャージ成功 → Charge（ネオングリーン）
                playerClashCallout = .chargeSuccess
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

            calloutText = playerCharge >= maxCharge ? "🌟 ULTIMATE READY!!" : "⚡️ 読み合い継続"
            statusDetailText = playerCharge >= maxCharge
                ? "🌟 金色の ULTIMATE ボタンをタップして一撃必殺！！"
                : notes.joined(separator: " / ")
        }

        // 体力が残り1になった側は常時 sad.png を表示
        if playerHP == 1 {
            playerExpression = .sad
        }
        if cpuHP == 1 {
            cpuExpression = .sad
        }

        resetSelectionIfNeeded()
    }

    private func resetSelectionIfNeeded() {
        guard !outcome.isFinished else { return }
        if playerCharge >= maxCharge || playerCharge < selectedAction.cost {
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
            finishMatch(playerWon: true, reason: "4チャージ ULTIMATE 炸裂！一撃必殺で \(currentEnemy.codeName) を撃破！")
        } else {
            if gameMode == .kumite && ItemManager.shared.activeBattleBoostItem == .bulletproofVest {
                // 防弾チョッキが一撃必殺の必殺技も一度だけ防ぐ！
                ItemManager.shared.consumeActiveBattleVestIfPresent()
                playerClashCallout = .goodGuard
                playerExpression = .fun
                cpuExpression = cpuHP == 1 ? .sad : .normal
                calloutText = "🛡️ 必殺技を防御！！"
                statusDetailText = "防弾チョッキが敵の必殺技を完全に防ぎ切った！！"
                HapticManager.playHeavy(enabled: isHapticsEnabled)
                showItemEffectFeedback("🛡️ 防弾チョッキで必殺技を防御！！")
                resetSelectionIfNeeded()
                if currentScreen == .kumiteBattle {
                    scheduleCommonRunLoopTimer()
                }
                return
            }

            playerHP = 0
            playerExpression = .sad
            cpuExpression = .fun
            calloutText = "💥 一撃必殺 K.O..."
            finishMatch(playerWon: false, reason: "\(currentEnemy.codeName) の一撃必殺に敗れた...")
        }
    }

    private func finishMatch(playerWon: Bool, reason: String) {
        stopTimer()
        preBattlePhase = .none
        statusDetailText = reason

        if playerWon {
            SoundManager.shared.playVoiceYouWinSE()
        } else {
            SoundManager.shared.playVoiceYouLoseSE()
        }

        if gameMode == .practice {
            markTutorialCompleted()
            outcome = .practiceClear(isWin: playerWon, reason: reason)
            return
        }

        if playerWon {
            winStreak += 1
            ItemManager.shared.addVictoryPoint()
            saveKumiteSession(isPendingRevive: false)
            PlayerIconManager.shared.recordKumiteVictory(
                enemy: currentEnemy,
                loopNumber: currentLoopNumber,
                newWinStreak: winStreak
            )
            GameCenterManager.shared.recordWinStreak(winStreak)
            outcome = .stageClear(enemyName: currentEnemy.codeName, reason: reason)
        } else {
            if winStreak > 0 && remainingRevives > 0 {
                saveKumiteSession(isPendingRevive: true)
            } else {
                clearSavedKumiteSession(clearActiveItems: remainingRevives <= 0)
            }
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
        // 0. 初手（1ターン目）で両者ともチャージ0の時は他行動が無意味なため必ずチャージを選択（電池持ち込み時は通常の読み合いへ移行）
        if turnCount == 1 && playerCharge == 0 && cpuCharge == 0 {
            return .charge
        }

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
