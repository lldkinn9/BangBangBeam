import SwiftUI
@preconcurrency import GameKit
import Observation

/// 1位〜100位の世界ランキング表示用データモデル
struct LeaderboardRowEntry: Identifiable, Equatable, Sendable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let iconAssetName: String
    let isLocalPlayer: Bool

    nonisolated static func == (lhs: LeaderboardRowEntry, rhs: LeaderboardRowEntry) -> Bool {
        lhs.id == rhs.id
            && lhs.rank == rhs.rank
            && lhs.displayName == rhs.displayName
            && lhs.score == rhs.score
            && lhs.iconAssetName == rhs.iconAssetName
            && lhs.isLocalPlayer == rhs.isLocalPlayer
    }
}

/// ランキング未表示・空状態の理由種別（日英リアルタイム切替対応）
enum RankingEmptyReason: Equatable, Sendable {
    case notSignedIn
    case leaderboardPreparing
    case noEntriesYet
    case fetchFailed

    @MainActor
    var localizedMessage: String {
        switch self {
        case .notSignedIn:
            return L10n(
                "端末の「設定 > Game Center」にサインインすると、自分の世界順位と 1〜100位 のランキングが表示されます。",
                "Sign in to Game Center in iOS Settings to view your global rank and the Top 100 leaderboard."
            )
        case .leaderboardPreparing:
            return L10n(
                "現在ランキング集計サーバーを準備中です。",
                "The leaderboard server is currently being prepared."
            )
        case .noEntriesYet:
            return L10n(
                "まだランキング登録された記録がありません。KUMITEで連勝して最初のランクインを目指しましょう！",
                "No records have been submitted yet. Win in KUMITE to claim the first spot!"
            )
        case .fetchFailed:
            return L10n(
                "ランキングデータの取得に失敗しました。通信環境や Game Center 設定をご確認のうえ再読み込みしてください。",
                "Failed to load leaderboard data. Check your network and Game Center settings, then try again."
            )
        }
    }
}

/// Apple公式 Game Center による「KUMITE 連勝数 世界ランキング（自分の順位 ＆ 1〜100位）」本番連携マネージャー
@Observable
@MainActor
final class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()

    private let bestStreakKey = "BangBangBeam.bestWinStreak"

    /// Info.plist に `GKLeaderboardID` が設定されていれば優先使用し、未設定時は標準IDを使用
    var leaderboardID: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "GKLeaderboardID") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured
        }
        return "com.lldkinn9.BangBangBeam.kumite_streak"
    }

    var isAuthenticated: Bool = false
    var playerDisplayName: String = "PLAYER"
    var bestWinStreak: Int = 0
    var statusMessage: String? = nil

    // MARK: - World Ranking (自分の順位 & 1〜100位) State
    var myGlobalRank: Int? = nil
    var myGlobalScore: Int? = nil
    var totalRankedPlayers: Int = 0
    var top100Entries: [LeaderboardRowEntry] = []
    var isLoadingRanking: Bool = false
    var emptyReason: RankingEmptyReason? = nil

    private override init() {
        self.bestWinStreak = UserDefaults.standard.integer(forKey: bestStreakKey)
        super.init()
    }

    /// アプリ起動時に Game Center 認証を開始
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let vc = viewController {
                    self.presentViewController(vc)
                } else if localPlayer.isAuthenticated {
                    self.isAuthenticated = true
                    self.playerDisplayName = localPlayer.displayName
                    self.statusMessage = nil
                    if self.bestWinStreak > 0 {
                        self.submitWinStreak(self.bestWinStreak)
                    }
                    await self.fetchTop100Ranking()
                } else {
                    self.isAuthenticated = false
                    self.myGlobalRank = nil
                    self.myGlobalScore = nil
                    self.totalRankedPlayers = 0
                    self.top100Entries = []
                    self.emptyReason = .notSignedIn
                    if let error {
                        self.statusMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// 連勝記録を更新し、Game Center Leaderboard へスコア＋選択アイコンコードを送信
    func recordWinStreak(_ streak: Int) {
        guard streak > 0 else { return }
        if streak > bestWinStreak {
            bestWinStreak = streak
            UserDefaults.standard.set(streak, forKey: bestStreakKey)
        }
        PlayerIconManager.shared.syncWithBestWinStreak(bestWinStreak)
        if isAuthenticated {
            submitWinStreak(bestWinStreak)
        }
    }

    /// 設定画面でアイコンを変更した際、ランキング内の自分行と Game Center context を即時更新
    func refreshSelectedIconInRanking() {
        let newIcon = PlayerIconManager.shared.selectedIcon.unlockedAssetName
        if !top100Entries.isEmpty {
            top100Entries = top100Entries.map { entry in
                guard entry.isLocalPlayer else { return entry }
                return LeaderboardRowEntry(
                    id: entry.id,
                    rank: entry.rank,
                    displayName: entry.displayName,
                    score: entry.score,
                    iconAssetName: newIcon,
                    isLocalPlayer: true
                )
            }
        }
        if isAuthenticated && bestWinStreak > 0 {
            submitWinStreak(bestWinStreak)
        }
    }

    private func submitWinStreak(_ streak: Int) {
        let iconCode = PlayerIconManager.shared.selectedIcon.numericCode
        GKLeaderboard.submitScore(
            streak,
            context: iconCode,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { _ in }
    }

    /// Game Center から「自分の順位」および「世界 1位〜100位」の本番データを取得
    func fetchTop100Ranking() async {
        guard isAuthenticated else {
            myGlobalRank = nil
            myGlobalScore = nil
            totalRankedPlayers = 0
            top100Entries = []
            emptyReason = .notSignedIn
            return
        }

        isLoadingRanking = true
        emptyReason = nil
        defer { isLoadingRanking = false }

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else {
                myGlobalRank = nil
                myGlobalScore = nil
                totalRankedPlayers = 0
                top100Entries = []
                emptyReason = .leaderboardPreparing
                return
            }

            let (localEntry, entries, totalCount) = try await leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 100)
            )

            totalRankedPlayers = totalCount

            if let localEntry {
                myGlobalRank = localEntry.rank > 0 ? localEntry.rank : nil
                myGlobalScore = localEntry.score
                if localEntry.score > bestWinStreak {
                    bestWinStreak = localEntry.score
                    UserDefaults.standard.set(localEntry.score, forKey: bestStreakKey)
                    PlayerIconManager.shared.syncWithBestWinStreak(bestWinStreak)
                }
            } else {
                myGlobalRank = nil
                myGlobalScore = nil
            }

            let localID = GKLocalPlayer.local.gamePlayerID
            let mySelectedIcon = PlayerIconManager.shared.selectedIcon.unlockedAssetName

            top100Entries = entries.map { entry in
                let isMe = (entry.player.gamePlayerID == localID)
                let resolvedIcon = isMe
                    ? mySelectedIcon
                    : PlayerIconManager.shared.iconID(forNumericCode: entry.context)

                return LeaderboardRowEntry(
                    id: "\(entry.rank)_\(entry.player.gamePlayerID)",
                    rank: entry.rank,
                    displayName: entry.player.displayName,
                    score: entry.score,
                    iconAssetName: resolvedIcon,
                    isLocalPlayer: isMe
                )
            }

            if top100Entries.isEmpty {
                emptyReason = .noEntriesYet
            }
        } catch {
            emptyReason = .fetchFailed
        }
    }

    private weak var activeGameCenterVC: GKGameCenterViewController? = nil

    @discardableResult
    func presentWorldRanking() -> Bool {
        guard isAuthenticated else {
            return false
        }
        let gcVC = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        gcVC.gameCenterDelegate = self
        activeGameCenterVC = gcVC
        return presentViewController(gcVC)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor [weak self] in
            self?.activeGameCenterVC?.dismiss(animated: true)
            self?.activeGameCenterVC = nil
        }
    }

    @discardableResult
    private func presentViewController(_ vc: UIViewController) -> Bool {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return false
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(vc, animated: true)
        return true
    }
}
