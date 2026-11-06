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

/// Apple公式 Game Center による「KUMITE 連勝数 世界ランキング（自分の順位 ＆ 1〜100位）」連携マネージャー
@Observable
@MainActor
final class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()

    /// 【表示確認用モックフラグ】オーナー依頼により仮モックデータを表示中（App Store 提出前に false へ切替可能）
    static let useMockRankingForPreview: Bool = true

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
    var rankingStatusNote: String? = nil

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
                    if let error {
                        self.statusMessage = error.localizedDescription
                    }
                    if Self.useMockRankingForPreview {
                        self.applyMockRankingData()
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
        if Self.useMockRankingForPreview {
            applyMockRankingData()
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

    /// Game Center（または表示確認用モック）から「自分の順位」および「世界 1位〜100位」を取得
    func fetchTop100Ranking() async {
        if Self.useMockRankingForPreview {
            applyMockRankingData()
            return
        }

        guard isAuthenticated else {
            myGlobalRank = nil
            myGlobalScore = nil
            top100Entries = []
            rankingStatusNote = "端末の「設定 > Game Center」にサインインすると、自分の世界順位と 1〜100位 のランキングが表示されます。"
            return
        }

        isLoadingRanking = true
        rankingStatusNote = nil
        defer { isLoadingRanking = false }

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else {
                myGlobalRank = nil
                myGlobalScore = nil
                top100Entries = []
                rankingStatusNote = "現在ランキング集計サーバーを準備中です（App Store Connect で Leaderboard 公開後に反映されます）。"
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
                rankingStatusNote = "まだランキング登録された記録がありません。KUMITEで連勝して最初のランクインを目指しましょう！"
            }
        } catch {
            rankingStatusNote = "ランキングデータの取得に失敗しました。通信環境や Game Center 設定をご確認のうえ再読み込みしてください。"
        }
    }

    // MARK: - Temporary Mock Ranking Generator (1位〜100位 表示＆アイコン反映確認用)
    private func applyMockRankingData() {
        let rivalNames: [String] = [
            "AKIRA_NEO", "CYBER_ZERO", "KAGURA_X", "RAIDEN_JP", "VORTEX_99",
            "SHINOBI_K", "LUNA_BEAM", "BLITZ_777", "PHANTOM_R", "NOCTIS_V",
            "SPARK_01", "VALKYRIE_Z", "ZENITH_JP", "NOVA_PULSE", "CRIMSON_AI",
            "ECHO_BEAT", "HAYATE_88", "MIRAGE_04", "ORION_CLAP", "STELLA_GG",
            "KURO_BLADE", "HYPER_ION", "SILVER_FOX", "TACHYON_S", "AETHER_11"
        ]

        let allCatalogIcons = PlayerIconManager.shared.allIcons.map(\.unlockedAssetName)
        let regularIcons = allCatalogIcons.filter { $0 != "icon_reo_100" }

        struct RawCandidate {
            let id: String
            let name: String
            let score: Int
            let icon: String
            let isLocal: Bool
        }

        var candidates: [RawCandidate] = []

        // 99名のライバルモックデータ（1位: 138連勝 〜 99人目: 12連勝）
        for idx in 0..<99 {
            let baseName = rivalNames[idx % rivalNames.count]
            let suffix = idx >= rivalNames.count ? "_\(idx + 1)" : ""
            let mockScore = max(5, 138 - (idx * 1) - (idx / 4))
            let iconName: String
            if mockScore >= 100 && idx % 2 == 0 {
                iconName = "icon_reo_100"
            } else {
                iconName = regularIcons[(idx * 7 + 3) % max(1, regularIcons.count)]
            }
            candidates.append(
                RawCandidate(
                    id: "mock_rival_\(idx)",
                    name: "\(baseName)\(suffix)",
                    score: mockScore,
                    icon: iconName,
                    isLocal: false
                )
            )
        }

        // 自分のエントリー（実スコアがあれば優先、未プレイでも上位で確認しやすいよう仮スコア 96 連勝を付与）
        let myPreviewScore = bestWinStreak > 0 ? bestWinStreak : 96
        let myName = isAuthenticated ? playerDisplayName : "YOU (PLAYER)"
        let myIcon = PlayerIconManager.shared.selectedIcon.unlockedAssetName

        candidates.append(
            RawCandidate(
                id: "mock_local_player",
                name: myName,
                score: myPreviewScore,
                icon: myIcon,
                isLocal: true
            )
        )

        // スコア降順（同点なら自分を優先表示）でソートし、1〜100位を採番
        candidates.sort { a, b in
            if a.score != b.score {
                return a.score > b.score
            }
            return a.isLocal && !b.isLocal
        }

        var builtRows: [LeaderboardRowEntry] = []
        var detectedMyRank: Int? = nil

        for (index, item) in candidates.prefix(100).enumerated() {
            let rank = index + 1
            if item.isLocal {
                detectedMyRank = rank
            }
            builtRows.append(
                LeaderboardRowEntry(
                    id: "\(rank)_\(item.id)",
                    rank: rank,
                    displayName: item.name,
                    score: item.score,
                    iconAssetName: item.icon,
                    isLocalPlayer: item.isLocal
                )
            )
        }

        // 万一実スコアが低く100位圏外だった場合も自分の順位を算出
        if detectedMyRank == nil,
           let fullIdx = candidates.firstIndex(where: { $0.isLocal }) {
            detectedMyRank = fullIdx + 1
        }

        self.myGlobalRank = detectedMyRank
        self.myGlobalScore = myPreviewScore
        self.totalRankedPlayers = 1284
        self.top100Entries = builtRows
        self.rankingStatusNote = nil
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
