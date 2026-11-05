import SwiftUI
import Observation

/// 勝敗結果の状態定義
enum BattleOutcome: Equatable, Sendable {
    case ongoing
    case playerWin(reason: String)
    case playerLose(reason: String, isFoul: Bool)

    nonisolated static func == (lhs: BattleOutcome, rhs: BattleOutcome) -> Bool {
        switch (lhs, rhs) {
        case (.ongoing, .ongoing):
            return true
        case let (.playerWin(a), .playerWin(b)):
            return a == b
        case let (.playerLose(r1, f1), .playerLose(r2, f2)):
            return r1 == r2 && f1 == f2
        default:
            return false
        }
    }

    var isFinished: Bool {
        if case .ongoing = self { return false }
        return true
    }
}

/// 1vs1リズムバトルの状態管理・タイマー制御・勝敗判定・CPU思考を担うゲームエンジン
@Observable
@MainActor
final class GameEngine {
    // MARK: - Navigation & Mode
    var currentScreen: AppScreen = .title
    var gameMode: GameMode = .kumite

    // MARK: - Settings
    /// テンポ設定（デフォルト BPM 88 -> 約 0.68秒間隔）
    var bpm: Double = 88.0 {
        didSet {
            if isAutoLoopRunning {
                restartTimer()
            }
        }
    }

    /// 気力（Charge）の最大ストック数（仕様: 0〜5個）
    var maxCharge: Int = 5

    /// 勝利に必要なラウンド先取数（デフォルト: 1本勝負）
    var targetWins: Int = 1

    /// 触覚フィードバック（CoreHaptics / UIImpactFeedbackGenerator）の有効フラグ
    var isHapticsEnabled: Bool = true

    // MARK: - Battle State
    /// 現在の拍（0: せっせっせーの..., 1: バン！, 2: バン！, 3: ビーム！激突解決）
    var beat: Int = 0

    /// 経過ターン数
    var turnCount: Int = 1

    /// 気力ストック（0〜5）
    var playerCharge: Int = 0
    var cpuCharge: Int = 0

    /// ラウンド取得数（複数本先取設定時にも活用）
    var playerScore: Int = 0
    var cpuScore: Int = 0

    /// プレイヤーが次の3拍目に向けて予約しているコマンド
    var selectedAction: GameAction = .charge

    /// 直近の3拍目で確定・公開された両者のアクション
    var revealedPlayerAction: GameAction? = nil
    var revealedCpuAction: GameAction? = nil

    /// アリーナ中央のコールテキスト・サブメッセージ
    var calloutText: String = "せっせっせーの..."
    var statusDetailText: String = "リズムに合わせてコマンドを選択！"

    /// 現在の勝敗状態
    var outcome: BattleOutcome = .ongoing

    /// PRACTICEモード内で自動テンポ再生を試す場合のフラグ（初期値は手動進行）
    var isPracticeAutoPlay: Bool = false {
        didSet {
            guard currentScreen == .battle, gameMode == .practice, !outcome.isFinished else { return }
            if isPracticeAutoPlay {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    // MARK: - Internal Timer
    private var rhythmTimer: Timer? = nil

    /// 1拍あたりの秒数（BPM 88 のとき約 0.6818秒）
    var beatInterval: TimeInterval {
        60.0 / max(40.0, min(bpm, 180.0))
    }

    private var isAutoLoopRunning: Bool {
        rhythmTimer != nil
    }

    // MARK: - Navigation Actions
    /// 指定モードでバトルを開始し、BattleViewへ遷移する
    func startBattle(mode: GameMode) {
        stopTimer()
        gameMode = mode
        isPracticeAutoPlay = false
        playerScore = 0
        cpuScore = 0
        setupNewRound(resetScores: false)
        currentScreen = .battle

        if mode == .kumite {
            startTimer()
        }
    }

    /// 現在のモードで最初から再戦する
    func rematch() {
        stopTimer()
        playerScore = 0
        cpuScore = 0
        setupNewRound(resetScores: false)

        if gameMode == .kumite || (gameMode == .practice && isPracticeAutoPlay) {
            startTimer()
        }
    }

    /// タイトル画面へ安全に戻る
    func returnToTitle() {
        stopTimer()
        isPracticeAutoPlay = false
        currentScreen = .title
    }

    // MARK: - Player Input
    /// プレイヤーがコマンドボタンをタップした際の予約処理
    /// ※お手つきルールを成立させるため、気力不足のコマンドもあえて選択可能にする
    func selectCommand(_ action: GameAction) {
        guard !outcome.isFinished else { return }
        selectedAction = action
        HapticManager.playMedium(enabled: isHapticsEnabled)
    }

    /// PRACTICEモード用：手動で1拍進める
    func stepBeatManually() {
        guard !outcome.isFinished else { return }
        advanceBeat()
    }

    // MARK: - Rhythm Loop Engine
    private func setupNewRound(resetScores: Bool) {
        if resetScores {
            playerScore = 0
            cpuScore = 0
        }
        beat = 0
        turnCount = 1
        playerCharge = 0
        cpuCharge = 0
        selectedAction = .charge
        revealedPlayerAction = nil
        revealedCpuAction = nil
        outcome = .ongoing
        calloutText = "せっせっせーの..."
        statusDetailText = gameMode == .practice
            ? "コマンドを選んで「1拍進める」をタップ"
            : "1・2拍目の間にコマンドを予約せよ！"
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

    /// 拍を1つ進め、0拍目(導入) -> 1拍目(バン) -> 2拍目(バン) -> 3拍目(ビーム解決) -> 1拍目... の3拍子ループを駆動
    private func advanceBeat() {
        guard !outcome.isFinished else {
            stopTimer()
            return
        }

        switch beat {
        case 0, 3:
            // 新しいターンの1拍目へ移行
            if beat == 3 {
                turnCount += 1
            }
            beat = 1
            revealedPlayerAction = nil
            revealedCpuAction = nil
            calloutText = "💥 バン！"
            statusDetailText = "👏 リズム 1 / 3 — コマンド受付中"
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 1:
            // 2拍目へ移行
            beat = 2
            calloutText = "💥 バン！"
            statusDetailText = "👏 リズム 2 / 3 — 次でアクション激突！"
            HapticManager.playLight(enabled: isHapticsEnabled)

        case 2:
            // 3拍目：アクション激突・判定解決
            beat = 3
            calloutText = "⚡️ ビーム！"
            resolveClash()

        default:
            beat = 1
        }
    }

    // MARK: - Clash Resolution & Rules
    private func resolveClash() {
        let pAction = selectedAction
        let cAction = decideCpuAction()

        revealedPlayerAction = pAction
        revealedCpuAction = cAction

        // 1. お手つき（反則自滅）判定：気力不足でビーム/メガビームを選択して3拍目を迎えた場合、即敗北
        if playerCharge < pAction.cost {
            HapticManager.playRigid(enabled: isHapticsEnabled)
            statusDetailText = "⚠️ 気力不足で \(pAction.label) を発動！"
            outcome = .playerLose(reason: "お手つき自滅！YOU LOSE", isFoul: true)
            stopTimer()
            return
        }

        // 通常の3拍目激突 Heavy Haptic
        HapticManager.playHeavy(enabled: isHapticsEnabled)

        // 2. コスト消費
        playerCharge = max(0, playerCharge - pAction.cost)
        cpuCharge = max(0, cpuCharge - cAction.cost)

        // 3. 勝敗・相殺・防御マトリクス判定
        switch (pAction, cAction) {
        // --- 両者非攻撃 ---
        case (.charge, .charge):
            grantCharges(player: pAction, cpu: cAction)
            statusDetailText = "⚡️ 両者チャージ！お互いに気力 +1"

        case (.charge, .barrier):
            grantCharges(player: pAction, cpu: cAction)
            statusDetailText = "⚡️ チャージ成功！相手は様子見のバリア"

        case (.barrier, .charge):
            grantCharges(player: pAction, cpu: cAction)
            statusDetailText = "🛡️ バリア展開！相手は気力をチャージ (+1)"

        case (.barrier, .barrier):
            statusDetailText = "🛡️ 両者バリア！静かな睨み合い..."

        // --- 通常ビーム関連 ---
        case (.beam, .charge):
            handleRoundWin(byPlayer: true, detail: "💥 ビーム直撃！無防備なチャージを撃破！")

        case (.charge, .beam):
            handleRoundWin(byPlayer: false, detail: "💥 チャージ中にビーム被弾！")

        case (.beam, .barrier):
            statusDetailText = "🛡️ 相手のバリアに通常ビームを防がれた！"

        case (.barrier, .beam):
            statusDetailText = "🛡️ ナイス防御！相手の通常ビームを完全ブロック！"

        case (.beam, .beam):
            statusDetailText = "💥 ビーム同士が激突して相殺！！"

        // --- メガビーム（超必殺技・バリア貫通）関連 ---
        case (.megaBeam, .charge):
            handleRoundWin(byPlayer: true, detail: "🌟 メガビーム炸裂！圧倒的出力で撃破！")

        case (.megaBeam, .barrier):
            handleRoundWin(byPlayer: true, detail: "🌟 バリア貫通撃破！！メガビームが盾を粉砕！")

        case (.megaBeam, .beam):
            handleRoundWin(byPlayer: true, detail: "🌟 出力圧倒！通常ビームを飲み込み撃破！")

        case (.charge, .megaBeam):
            handleRoundWin(byPlayer: false, detail: "🌟 チャージ中に敵メガビームが直撃！")

        case (.barrier, .megaBeam):
            handleRoundWin(byPlayer: false, detail: "🌟 バリア貫通被弾！メガビームは防げない！")

        case (.beam, .megaBeam):
            handleRoundWin(byPlayer: false, detail: "🌟 出力負け！敵メガビームに押し切られた！")

        case (.megaBeam, .megaBeam):
            statusDetailText = "🌟⚡️ 超激突！！メガビーム同士が空間ごと相殺！！"
        }

        // 次ターンに向けて、気力不足による意図しない連続お手つきを防ぐため選択がコスト超過ならチャージへ戻す
        if !outcome.isFinished && playerCharge < selectedAction.cost {
            selectedAction = .charge
        }
    }

    private func grantCharges(player: GameAction, cpu: GameAction) {
        if player.gain > 0 {
            playerCharge = min(maxCharge, playerCharge + player.gain)
        }
        if cpu.gain > 0 {
            cpuCharge = min(maxCharge, cpuCharge + cpu.gain)
        }
    }

    private func handleRoundWin(byPlayer: Bool, detail: String) {
        statusDetailText = detail
        if byPlayer {
            playerScore += 1
            if playerScore >= targetWins {
                outcome = .playerWin(reason: detail)
                stopTimer()
            } else {
                // 複数本先取時は気力をリセットして次ラウンドへ
                prepareNextSubRound(banner: "ROUND WIN! (\(playerScore)-\(cpuScore)) — \(detail)")
            }
        } else {
            cpuScore += 1
            if cpuScore >= targetWins {
                outcome = .playerLose(reason: detail, isFoul: false)
                stopTimer()
            } else {
                prepareNextSubRound(banner: "ROUND LOSE... (\(playerScore)-\(cpuScore)) — \(detail)")
            }
        }
    }

    private func prepareNextSubRound(banner: String) {
        playerCharge = 0
        cpuCharge = 0
        selectedAction = .charge
        beat = 0
        statusDetailText = banner
    }

    // MARK: - CPU AI Logic (確率ベース行動選択)
    /// 仕様書 3.3 に準拠したCPU思考ロジック
    /// - 気力0の時: チャージ 70%、バリア 30%
    /// - 気力1以上の時: 相手に気力があれば バリア 40%、ビーム 40%、チャージ 20%
    /// - 気力2以上の時: メガビーム 55% で発動
    private func decideCpuAction() -> GameAction {
        let roll = Double.random(in: 0..<1.0)
        let canChargeMore = cpuCharge < maxCharge

        // 1. CPU気力 0 の時
        if cpuCharge == 0 {
            // 仕様通り チャージ 70%、バリア 30%
            return roll < 0.70 ? .charge : .barrier
        }

        // 2. CPU気力 2以上 の時: 55% で超必殺メガビーム発動
        if cpuCharge >= 2 {
            if roll < 0.55 {
                return .megaBeam
            }
            // 残り45%は気力1以上の戦術比率へフォールバック
            let subRoll = Double.random(in: 0..<1.0)
            return chooseStandardTactic(roll: subRoll, canChargeMore: canChargeMore)
        }

        // 3. CPU気力 1 の時
        return chooseStandardTactic(roll: roll, canChargeMore: canChargeMore)
    }

    private func chooseStandardTactic(roll: Double, canChargeMore: Bool) -> GameAction {
        if playerCharge >= 1 {
            // 相手に気力がある場合: バリア 40% / ビーム 40% / チャージ 20%
            if roll < 0.40 {
                return .barrier
            } else if roll < 0.80 || !canChargeMore {
                return .beam
            } else {
                return .charge
            }
        } else {
            // 相手が気力0（攻撃不可）の場合: バリア不要のため ビーム 65% / チャージ 35%
            if !canChargeMore || roll < 0.65 {
                return .beam
            } else {
                return .charge
            }
        }
    }
}

