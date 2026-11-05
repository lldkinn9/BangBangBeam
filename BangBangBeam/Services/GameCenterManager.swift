import SwiftUI
@preconcurrency import GameKit
import Observation

/// Apple公式 Game Center による「KUMITE 連勝数 世界ランキング」連携マネージャー
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
    var playerDisplayName: String = "GUEST"
    var bestWinStreak: Int = 0
    var statusMessage: String? = nil

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
                    // ローカル自己ベストがあれば同期送信
                    if self.bestWinStreak > 0 {
                        self.submitWinStreak(self.bestWinStreak)
                    }
                } else {
                    self.isAuthenticated = false
                    if let error {
                        self.statusMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// 連勝記録を更新し、Game Center Leaderboard へスコア送信
    func recordWinStreak(_ streak: Int) {
        guard streak > 0 else { return }
        if streak > bestWinStreak {
            bestWinStreak = streak
            UserDefaults.standard.set(streak, forKey: bestStreakKey)
        }
        if isAuthenticated {
            submitWinStreak(streak)
        }
    }

    private func submitWinStreak(_ streak: Int) {
        GKLeaderboard.submitScore(
            streak,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { _ in }
    }

    private weak var activeGameCenterVC: GKGameCenterViewController? = nil

    /// Game Center 公式世界ランキング画面を表示（未サインインの場合はfalseを返しフォールバックシート表示）
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
