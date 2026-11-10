import Foundation
import Observation

/// 勝利ポイント・所持アイテム・KUMITE持ち込み設定・救急キット適用状態を永続管理するマネージャー
@Observable
@MainActor
final class ItemManager {
    static let shared = ItemManager()

    // MARK: - Persistence Keys
    private let pointsKey = "BangBangBeam.battlePoints"
    private let inventoryKey = "BangBangBeam.itemInventory"
    private let selectedCarryInKey = "BangBangBeam.selectedCarryInItem"
    private let activeRunCarryInKey = "BangBangBeam.activeRunCarryInItem"
    private let queuedMedkitKey = "BangBangBeam.queuedMedkitItem"
    private let activeRunMedkitKey = "BangBangBeam.activeRunMedkitItem"
    private let activeMedkitUnusedAtTitleKey = "BangBangBeam.activeMedkitUnusedAtTitle"

    // MARK: - Observable State
    /// 現在の所持ポイント（KUMITE 1勝ごとに +1 PT、アイテム交換時に消費）
    private(set) var points: Int = 0

    /// 持ち込み用アイテムの所持数（救急キットは購入即時適用のためここには入らない）
    private(set) var inventory: [BattleItem: Int] = [:]

    /// ITEM画面で「次のKUMITEへ持ち込む」として予約選択中のアイテム（最大1つ）
    private(set) var selectedCarryInItem: BattleItem? = nil

    /// 現在進行中のKUMITE挑戦で有効になっている持ち込みアイテム（消費されると nil になる）
    private(set) var activeRunCarryInItem: BattleItem? = nil

    /// KUMITE開始前に購入され、次のKUMITE挑戦に自動適用される待機中の救急キット（最大1つ）
    private(set) var queuedMedkit: BattleItem? = nil

    /// 現在進行中のKUMITE挑戦に適用されている救急キット（最大1つ）
    private(set) var activeRunMedkit: BattleItem? = nil

    /// 中断中のKUMITE状態でタイトルから購入された未使用の救急キットかどうか（万一そのまま「最初から挑戦」を選んだ場合にも無駄にならないよう保護）
    private var isActiveMedkitFreshlyBoughtAtTitle: Bool = false

    private init() {
        self.points = max(0, UserDefaults.standard.integer(forKey: pointsKey))

        if let rawDict = UserDefaults.standard.dictionary(forKey: inventoryKey) as? [String: Int] {
            var loaded: [BattleItem: Int] = [:]
            for (k, v) in rawDict {
                if let item = BattleItem(rawValue: k), v > 0 {
                    loaded[item] = v
                }
            }
            self.inventory = loaded
        }

        if let rawSelected = UserDefaults.standard.string(forKey: selectedCarryInKey),
           let item = BattleItem(rawValue: rawSelected),
           (inventory[item] ?? 0) > 0 {
            self.selectedCarryInItem = item
        }

        if let rawActiveCarry = UserDefaults.standard.string(forKey: activeRunCarryInKey),
           let item = BattleItem(rawValue: rawActiveCarry) {
            self.activeRunCarryInItem = item
        }

        if let rawQueuedMed = UserDefaults.standard.string(forKey: queuedMedkitKey),
           let item = BattleItem(rawValue: rawQueuedMed),
           item.category == .autoMedkit {
            self.queuedMedkit = item
        }

        if let rawActiveMed = UserDefaults.standard.string(forKey: activeRunMedkitKey),
           let item = BattleItem(rawValue: rawActiveMed),
           item.category == .autoMedkit {
            self.activeRunMedkit = item
        }

        self.isActiveMedkitFreshlyBoughtAtTitle = UserDefaults.standard.bool(forKey: activeMedkitUnusedAtTitleKey)
    }

    // MARK: - Queries
    func ownedCount(for item: BattleItem) -> Int {
        max(0, inventory[item] ?? 0)
    }

    /// 現在いずれかの救急キットが適用済み（重複購入不可）かどうか
    var appliedMedkit: BattleItem? {
        activeRunMedkit ?? queuedMedkit
    }

    var hasAppliedMedkit: Bool {
        appliedMedkit != nil
    }

    // MARK: - Point Operations
    /// KUMITE勝利時に 1 ポイント加算
    func addVictoryPoint() {
        points += 1
        saveState()
    }

    // MARK: - Shop Purchase & Equip
    /// 持ち込み可能アイテムをポイントと交換（購入）する
    @discardableResult
    func purchaseCarryInItem(_ item: BattleItem) -> Bool {
        guard item.isCarryInSelectable, points >= item.pointCost else { return false }
        points -= item.pointCost
        let newCount = ownedCount(for: item) + 1
        inventory[item] = newCount

        // まだ持ち込みアイテムが未選択で、かつ進行中KUMITEに別アイテムがロックされていなければ自動セット
        if selectedCarryInItem == nil && activeRunCarryInItem == nil {
            selectedCarryInItem = item
        }

        saveState()
        return true
    }

    /// 所持しているアイテムを次のKUMITEへの持ち込み枠にセット／解除する（1つのみ選択可能）
    func toggleCarryInSelection(_ item: BattleItem) {
        guard item.isCarryInSelectable else { return }
        if selectedCarryInItem == item {
            selectedCarryInItem = nil
        } else if ownedCount(for: item) > 0 {
            selectedCarryInItem = item
        }
        saveState()
    }

    func clearCarryInSelection() {
        selectedCarryInItem = nil
        saveState()
    }

    /// 救急キットを購入して即時自動適用する（1回のKUMITEにつき1つのみ適用可能）
    @discardableResult
    func purchaseAndApplyMedkit(_ item: BattleItem, hasSavedKumiteSession: Bool) -> Bool {
        guard item.category == .autoMedkit,
              !hasAppliedMedkit,
              points >= item.pointCost else {
            return false
        }

        points -= item.pointCost

        if hasSavedKumiteSession {
            activeRunMedkit = item
            isActiveMedkitFreshlyBoughtAtTitle = true
        } else {
            queuedMedkit = item
            isActiveMedkitFreshlyBoughtAtTitle = false
        }

        saveState()
        return true
    }

    // MARK: - KUMITE Lifecycle Integration
    /// 連勝0から新しくKUMITEを開始する際、予約中の持ち込みアイテム（1個消費）と待機中の救急キットを本挑戦へ確定適用する
    func activateLoadoutForNewKumiteRun() -> (carryIn: BattleItem?, medkit: BattleItem?) {
        // 万一、タイトル中断中に救急キットを買った直後に「最初から挑戦」を選んだ場合はその未使用キットを引き継ぐ
        let preservedMedkit: BattleItem? = isActiveMedkitFreshlyBoughtAtTitle ? activeRunMedkit : nil

        activeRunCarryInItem = nil
        activeRunMedkit = nil
        isActiveMedkitFreshlyBoughtAtTitle = false

        // 1. 持ち込みアイテムを所持数から1個消費して有効化
        if let chosen = selectedCarryInItem, ownedCount(for: chosen) > 0 {
            let remaining = ownedCount(for: chosen) - 1
            if remaining > 0 {
                inventory[chosen] = remaining
            } else {
                inventory.removeValue(forKey: chosen)
            }
            activeRunCarryInItem = chosen
            selectedCarryInItem = nil
        } else {
            selectedCarryInItem = nil
        }

        // 2. 救急キットを有効化
        if let med = queuedMedkit ?? preservedMedkit {
            activeRunMedkit = med
            queuedMedkit = nil
        }

        saveState()
        return (activeRunCarryInItem, activeRunMedkit)
    }

    /// 勝利後タイトル中断状態からKUMITEを再開する際、未装備であれば新たに選択された持ち込みアイテム（1個消費）や救急キットを反映する
    func activatePendingLoadoutForResumedKumite() -> (carryIn: BattleItem?, medkit: BattleItem?) {
        isActiveMedkitFreshlyBoughtAtTitle = false

        if activeRunCarryInItem == nil,
           let chosen = selectedCarryInItem,
           ownedCount(for: chosen) > 0 {
            let remaining = ownedCount(for: chosen) - 1
            if remaining > 0 {
                inventory[chosen] = remaining
            } else {
                inventory.removeValue(forKey: chosen)
            }
            activeRunCarryInItem = chosen
            selectedCarryInItem = nil
        }

        if activeRunMedkit == nil, let queued = queuedMedkit {
            activeRunMedkit = queued
            queuedMedkit = nil
        }

        saveState()
        return (activeRunCarryInItem, activeRunMedkit)
    }

    /// リワード広告復活を実行した際、救急キットが使用段階に入ったことを記録
    func markReviveUsedInActiveRun() {
        if isActiveMedkitFreshlyBoughtAtTitle {
            isActiveMedkitFreshlyBoughtAtTitle = false
            saveState()
        }
    }

    /// バトル中に防弾チョッキ・回復薬・エナジードリンクが発動して消費された際に呼び出す
    func consumeActiveRunCarryInItem() {
        activeRunCarryInItem = nil
        saveState()
    }

    /// KUMITEが完全終了（ゲームオーバー確定でタイトルへ戻る等）した際に、その挑戦の適用中アイテム・救急キットをクリアする
    func clearFinishedKumiteRunLoadout() {
        activeRunCarryInItem = nil
        if !isActiveMedkitFreshlyBoughtAtTitle {
            activeRunMedkit = nil
        }
        saveState()
    }

    // MARK: - Persistence
    private func saveState() {
        UserDefaults.standard.set(points, forKey: pointsKey)

        var rawDict: [String: Int] = [:]
        for (k, v) in inventory where v > 0 {
            rawDict[k.rawValue] = v
        }
        UserDefaults.standard.set(rawDict, forKey: inventoryKey)

        if let selectedCarryInItem {
            UserDefaults.standard.set(selectedCarryInItem.rawValue, forKey: selectedCarryInKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedCarryInKey)
        }

        if let activeRunCarryInItem {
            UserDefaults.standard.set(activeRunCarryInItem.rawValue, forKey: activeRunCarryInKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeRunCarryInKey)
        }

        if let queuedMedkit {
            UserDefaults.standard.set(queuedMedkit.rawValue, forKey: queuedMedkitKey)
        } else {
            UserDefaults.standard.removeObject(forKey: queuedMedkitKey)
        }

        if let activeRunMedkit {
            UserDefaults.standard.set(activeRunMedkit.rawValue, forKey: activeRunMedkitKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeRunMedkitKey)
        }

        UserDefaults.standard.set(isActiveMedkitFreshlyBoughtAtTitle, forKey: activeMedkitUnusedAtTitleKey)
    }
}
