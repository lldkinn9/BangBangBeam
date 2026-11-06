import SwiftUI
import Observation

/// プレイヤーが選択・解放できるアイコン定義（全21キャラ × 4種 ＝ 全84個）
struct PlayerIconItem: Identifiable, Equatable, Sendable {
    let id: String
    let numericCode: Int
    let characterID: String
    let characterCodeName: String
    let variantLabel: String
    let unlockConditionText: String

    var unlockedAssetName: String {
        id
    }

    var lockedSilhouetteAssetName: String {
        "\(id)_locked"
    }

    nonisolated static func == (lhs: PlayerIconItem, rhs: PlayerIconItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// キャラクター単位のアイコングループ（1キャラ4個ずつ表示用）
struct CharacterIconGroup: Identifiable, Sendable {
    let id: String
    let codeName: String
    let subtitle: String
    let icons: [PlayerIconItem]
}

/// アイコン選択状態・KUMITE撃破／連勝による解放状態を永続管理するマネージャー
@Observable
@MainActor
final class PlayerIconManager {
    static let shared = PlayerIconManager()

    private let selectedIconKey = "BangBangBeam.selectedPlayerIconID"
    private let unlockedIconsKey = "BangBangBeam.unlockedPlayerIconIDs"
    private let reoIcon3RuleMigratedKey = "BangBangBeam.migratedReoIcon3To50Wins"

    static let defaultIconID = "icon_reo_1"
    /// 初期解放は reo の icon1, icon2 のみ（icon3 は 50連勝、icon100 は 100連勝で解放）
    static let initialUnlockedIDs: Set<String> = [
        "icon_reo_1",
        "icon_reo_2"
    ]

    let characterGroups: [CharacterIconGroup]
    let allIcons: [PlayerIconItem]

    var unlockedIconIDs: Set<String>
    var selectedIconID: String {
        didSet {
            UserDefaults.standard.set(selectedIconID, forKey: selectedIconKey)
        }
    }

    var selectedIcon: PlayerIconItem {
        allIcons.first(where: { $0.id == selectedIconID }) ?? allIcons[0]
    }

    private init() {
        let builtGroups = Self.buildCatalog()
        self.characterGroups = builtGroups
        self.allIcons = builtGroups.flatMap(\.icons)

        let existingBestStreak = UserDefaults.standard.integer(forKey: "BangBangBeam.bestWinStreak")
        var savedSet = Set(UserDefaults.standard.stringArray(forKey: unlockedIconsKey) ?? [])

        // 旧バージョンで初期解放扱いだった icon_reo_3 を、50連勝未満なら未解放へ移行
        if !UserDefaults.standard.bool(forKey: reoIcon3RuleMigratedKey) {
            if existingBestStreak < 50 {
                savedSet.remove("icon_reo_3")
            }
            UserDefaults.standard.set(true, forKey: reoIcon3RuleMigratedKey)
        }

        var mergedUnlocked = Self.initialUnlockedIDs.union(savedSet)
        if existingBestStreak > 0 {
            mergedUnlocked.formUnion(Self.computeUnlockedIDs(forWinStreak: existingBestStreak))
        }
        self.unlockedIconIDs = mergedUnlocked

        let savedSelected = UserDefaults.standard.string(forKey: selectedIconKey) ?? Self.defaultIconID
        if mergedUnlocked.contains(savedSelected) {
            self.selectedIconID = savedSelected
        } else {
            self.selectedIconID = Self.defaultIconID
            UserDefaults.standard.set(Self.defaultIconID, forKey: selectedIconKey)
        }

        persistUnlocked()
    }

    // MARK: - Queries & Selection
    func isUnlocked(_ iconID: String) -> Bool {
        unlockedIconIDs.contains(iconID)
    }

    @discardableResult
    func selectIcon(_ iconID: String) -> Bool {
        guard isUnlocked(iconID) else { return false }
        selectedIconID = iconID
        return true
    }

    func iconID(forNumericCode code: Int) -> String {
        guard let matched = allIcons.first(where: { $0.numericCode == code }) else {
            return Self.defaultIconID
        }
        return matched.id
    }

    // MARK: - Unlock Progression (KUMITE)
    /// KUMITEで敵を1人撃破するたびに呼び出し、周回数に応じたアイコンおよび50連勝・100連勝アイコンを解放する
    func recordKumiteVictory(enemy: CharacterProfile, loopNumber: Int, newWinStreak: Int) {
        var updated = false

        let isExtraCharacter = enemy.stageOrder >= 12
        // 既存11キャラ: 1周目->icon1, 2周目->icon2, 3周目->icon3, 4周目以降->icon4
        // 追加9キャラ(2周目から出現): 2周目->icon1, 3周目->icon2, 4周目->icon3, 5周目以降->icon4
        let rawTier = isExtraCharacter ? (loopNumber - 1) : loopNumber
        if rawTier >= 1 {
            let unlockedTier = min(4, rawTier)
            for tier in 1...unlockedTier {
                let targetID = "icon_\(enemy.id)_\(tier)"
                if unlockedIconIDs.insert(targetID).inserted {
                    updated = true
                }
            }
        }

        // KUMITE 50連勝達成で reo-icon3 を解放
        if newWinStreak >= 50 {
            if unlockedIconIDs.insert("icon_reo_3").inserted {
                updated = true
            }
        }

        // KUMITE 100連勝達成で reo-icon100 を解放
        if newWinStreak >= 100 {
            if unlockedIconIDs.insert("icon_reo_100").inserted {
                updated = true
            }
        }

        if updated {
            persistUnlocked()
        }
    }

    /// 自己ベスト連勝数から解放漏れがないよう同期
    func syncWithBestWinStreak(_ bestStreak: Int) {
        guard bestStreak > 0 else { return }
        let earned = Self.computeUnlockedIDs(forWinStreak: bestStreak)
        let beforeCount = unlockedIconIDs.count
        unlockedIconIDs.formUnion(earned)
        if unlockedIconIDs.count != beforeCount {
            persistUnlocked()
        }
    }

    private func persistUnlocked() {
        UserDefaults.standard.set(Array(unlockedIconIDs).sorted(), forKey: unlockedIconsKey)
    }

    // MARK: - Catalog Builder
    private static func computeUnlockedIDs(forWinStreak streak: Int) -> Set<String> {
        guard streak > 0 else { return [] }
        var result: Set<String> = []
        let maxSim = min(streak, 95)
        for s in 0..<maxSim {
            let stageInfo = CharacterProfile.enemy(forStreak: s)
            let isExtra = stageInfo.profile.stageOrder >= 12
            let rawTier = isExtra ? (stageInfo.loopNumber - 1) : stageInfo.loopNumber
            if rawTier >= 1 {
                let tier = min(4, rawTier)
                result.insert("icon_\(stageInfo.profile.id)_\(tier)")
            }
        }
        if streak >= 50 {
            result.insert("icon_reo_3")
        }
        if streak >= 100 {
            result.insert("icon_reo_100")
        }
        return result
    }

    private static func buildCatalog() -> [CharacterIconGroup] {
        var groups: [CharacterIconGroup] = []
        var nextCode = 1

        // 1. 主人公 REO (icon1〜2: 初期解放 / icon3: 50連勝 / icon100: 100連勝)
        let reoVariants: [(suffix: String, label: String, condition: String)] = [
            ("1", "ICON 1", "初期解放"),
            ("2", "ICON 2", "初期解放"),
            ("3", "ICON 3", "KUMITE 50連勝達成で解放"),
            ("100", "ICON 100", "KUMITE 100連勝達成で解放")
        ]
        var reoItems: [PlayerIconItem] = []
        for v in reoVariants {
            reoItems.append(
                PlayerIconItem(
                    id: "icon_reo_\(v.suffix)",
                    numericCode: nextCode,
                    characterID: "reo",
                    characterCodeName: "REO",
                    variantLabel: v.label,
                    unlockConditionText: v.condition
                )
            )
            nextCode += 1
        }
        groups.append(
            CharacterIconGroup(
                id: "reo",
                codeName: "REO",
                subtitle: "初期解放(1・2) / 50連勝(3) / 100連勝(100)",
                icons: reoItems
            )
        )

        // 2. 基本敵11キャラクター (1〜4周目で icon1〜4 解放)
        for enemy in CharacterProfile.baseKumiteRoster {
            var items: [PlayerIconItem] = []
            for tier in 1...4 {
                items.append(
                    PlayerIconItem(
                        id: "icon_\(enemy.id)_\(tier)",
                        numericCode: nextCode,
                        characterID: enemy.id,
                        characterCodeName: enemy.codeName,
                        variantLabel: "ICON \(tier)",
                        unlockConditionText: "KUMITE \(tier)周目で \(enemy.codeName) を撃破"
                    )
                )
                nextCode += 1
            }
            groups.append(
                CharacterIconGroup(
                    id: enemy.id,
                    codeName: enemy.codeName,
                    subtitle: "1周目〜登場（1〜4周目撃破で解放）",
                    icons: items
                )
            )
        }

        // 3. 追加敵9キャラクター (2周目から出現するため 2〜5周目で icon1〜4 解放)
        for enemy in CharacterProfile.extraLoopRoster {
            var items: [PlayerIconItem] = []
            for tier in 1...4 {
                let requiredLoop = tier + 1
                items.append(
                    PlayerIconItem(
                        id: "icon_\(enemy.id)_\(tier)",
                        numericCode: nextCode,
                        characterID: enemy.id,
                        characterCodeName: enemy.codeName,
                        variantLabel: "ICON \(tier)",
                        unlockConditionText: "KUMITE \(requiredLoop)周目で \(enemy.codeName) を撃破"
                    )
                )
                nextCode += 1
            }
            groups.append(
                CharacterIconGroup(
                    id: enemy.id,
                    codeName: enemy.codeName,
                    subtitle: "2周目〜登場（2〜5周目撃破で解放）",
                    icons: items
                )
            )
        }

        return groups
    }
}
