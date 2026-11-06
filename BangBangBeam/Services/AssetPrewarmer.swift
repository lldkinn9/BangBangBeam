import UIKit

/// KUMITE 1戦目開始時や初手3拍目のPNG初回デコードによるカクつきを防ぐアセット事前デコード機構
@MainActor
enum AssetPrewarmer {
    /// 常駐保持するバトル共通デコード済みビットマップ（手イラスト4種・Reo立ち絵/カットイン・リザルト画像）
    private static var coreCache: [String: UIImage] = [:]

    /// 現在・次戦の敵キャラクター用デコード済みビットマップ（最大2体分のみ保持しメモリ消費を最小化）
    private static var stageEnemyCache: [String: UIImage] = [:]
    private static var isCoreWarmed: Bool = false

    /// アプリ起動時（タイトル待機中）にバトル共通画像と1戦目の敵画像をバックグラウンドでGPU表示用デコードする
    static func warmUpForInitialLaunch(startingStreak: Int) {
        let firstEnemy = CharacterProfile.enemy(forStreak: startingStreak).profile
        let secondEnemy = CharacterProfile.enemy(forStreak: startingStreak + 1).profile

        Task(priority: .userInitiated) {
            if !isCoreWarmed {
                let coreNames: [String] = [
                    "hand_clap",
                    "hand_charge",
                    "hand_beam",
                    "hand_barrier",
                    "result_reo_happy",
                    "result_reo_lose",
                    CharacterProfile.reo.standingAsset(for: .normal),
                    CharacterProfile.reo.standingAsset(for: .fun),
                    CharacterProfile.reo.standingAsset(for: .sad),
                    CharacterProfile.reo.cutinAsset
                ]

                for name in coreNames where coreCache[name] == nil {
                    if let raw = UIImage(named: name) {
                        let prepared = await raw.byPreparingForDisplay() ?? raw
                        coreCache[name] = prepared
                    }
                }
                isCoreWarmed = true
            }

            await warmUpEnemies([firstEnemy, secondEnemy])
        }
    }

    /// 現在および次戦の敵キャラクター立ち絵（3表情＋カットイン）を事前デコードし、古い敵キャッシュは解放する
    static func warmUpUpcomingEnemies(currentStreak: Int) {
        let currentEnemy = CharacterProfile.enemy(forStreak: currentStreak).profile
        let nextEnemy = CharacterProfile.enemy(forStreak: currentStreak + 1).profile

        Task(priority: .utility) {
            await warmUpEnemies([currentEnemy, nextEnemy])
        }
    }

    private static func warmUpEnemies(_ enemies: [CharacterProfile]) async {
        var neededNames: [String] = []
        for enemy in enemies {
            neededNames.append(enemy.standingAsset(for: .normal))
            neededNames.append(enemy.standingAsset(for: .fun))
            neededNames.append(enemy.standingAsset(for: .sad))
            neededNames.append(enemy.cutinAsset)
        }

        let neededSet = Set(neededNames)
        stageEnemyCache = stageEnemyCache.filter { neededSet.contains($0.key) }

        for name in neededNames where stageEnemyCache[name] == nil {
            if let raw = UIImage(named: name) {
                let prepared = await raw.byPreparingForDisplay() ?? raw
                stageEnemyCache[name] = prepared
            }
        }
    }
}
