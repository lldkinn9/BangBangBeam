import Foundation
import Observation

/// 勝利ポイント・ストック所持数・VS画面1バトル効果・KUMITE持ち込み設定・救急キット適用状態を永続管理するマネージャー
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

    /// ストック可能なアイテム（ハート・電池・防弾チョッキ・回復薬・エナジードリンク）の所持数
    private(set) var inventory: [BattleItem: Int] = [:]

    /// ITEM画面で「次のKUMITEへ持ち込む」として選択中のバトル中使用アイテム（回復薬 または エナジードリンク、最大1つ）
    private(set) var selectedCarryInItem: BattleItem? = nil

    /// 現在進行中のKUMITE挑戦で保持している持ち込みアイテム（バトル中にタップ使用すると nil になる）
    private(set) var activeRunCarryInItem: BattleItem? = nil

    /// 現在の1バトル限定で有効になっているVS画面選択アイテム（ハート・電池・防弾チョッキのいずれか最大1つ。バトル終了・次戦移行時にリセット）
    private(set) var activeBattleBoostItem: BattleItem? = nil

    /// KUMITE開始前に交換され、次のKUMITE挑戦に自動適用される待機中の救急キット（最大1つ）
    private(set) var queuedMedkit: BattleItem? = nil

    /// 現在進行中のKUMITE挑戦に適用されている救急キット（最大1つ）
    private(set) var activeRunMedkit: BattleItem? = nil

    /// 中断中のKUMITE状態でタイトルから交換された未使用の救急キットかどうか
    private var isActiveMedkitFreshlyExchangedAtTitle: Bool = false

    private init() {
        self.points = max(0, UserDefaults.standard.integer(forKey: pointsKey))

        if let rawDict = UserDefaults.standard.dictionary(forKey: inventoryKey) as? [String: Int] {
            var loaded: [BattleItem: Int] = [:]
            for (k, v) in rawDict {
                if let item = BattleItem(rawValue: k), item.isStockable, v > 0 {
                    loaded[item] = v
                }
            }
            self.inventory = loaded
        }

        if let rawSelected = UserDefaults.standard.string(forKey: selectedCarryInKey),
           let item = BattleItem(rawValue: rawSelected),
           item.isCarryInSelectable,
           (inventory[item] ?? 0) > 0 {
            self.selectedCarryInItem = item
        }

        if let rawActiveCarry = UserDefaults.standard.string(forKey: activeRunCarryInKey),
           let item = BattleItem(rawValue: rawActiveCarry),
           item.isCarryInSelectable {
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

        self.isActiveMedkitFreshlyExchangedAtTitle = UserDefaults.standard.bool(forKey: activeMedkitUnusedAtTitleKey)
    }

    // MARK: - Queries
    func ownedCount(for item: BattleItem) -> Int {
        max(0, inventory[item] ?? 0)
    }

    /// 現在いずれかの救急キットが適用済みかどうか
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

    // MARK: - Item Exchange & Carry-In Setup
    /// ストック可能なアイテム（ハート・電池・防弾チョッキ・回復薬・エナジードリンク）をポイントと交換する
    @discardableResult
    func exchangeStockableItem(_ item: BattleItem) -> Bool {
        guard item.isStockable, points >= item.pointCost else { return false }
        points -= item.pointCost
        let newCount = ownedCount(for: item) + 1
        inventory[item] = newCount

        // バトル中使用アイテム（回復薬・エナジードリンク）で、まだ持ち込み枠が空であれば自動セット
        if item.isCarryInSelectable && selectedCarryInItem == nil && activeRunCarryInItem == nil {
            selectedCarryInItem = item
        }

        saveState()
        return true
    }

    /// 所持しているバトル中使用アイテム（回復薬・エナジードリンク）を次のKUMITEへの持ち込み枠にセット／解除する（1つのみ選択可能）
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

    /// 救急キットをポイントと交換して即時自動適用する（1回のKUMITEにつき1つのみ適用可能）
    @discardableResult
    func exchangeAndApplyMedkit(_ item: BattleItem, hasSavedKumiteSession: Bool) -> Bool {
        guard item.category == .autoMedkit,
              !hasAppliedMedkit,
              points >= item.pointCost else {
            return false
        }

        points -= item.pointCost

        if hasSavedKumiteSession {
            activeRunMedkit = item
            isActiveMedkitFreshlyExchangedAtTitle = true
        } else {
            queuedMedkit = item
            isActiveMedkitFreshlyExchangedAtTitle = false
        }

        saveState()
        return true
    }

    // MARK: - Per-Battle VS Screen Boost Item (ハート / 電池 / 防弾チョッキ — 1バトルのみ有効)
    /// 毎バトル前のVS画面で「START」を押した際、選択されていたアイテムをストックから1個消費して今回の1バトルに適用する
    @discardableResult
    func consumeAndActivateVsBattleBoost(_ item: BattleItem?) -> BattleItem? {
        activeBattleBoostItem = nil
        guard let item,
              item.category == .vsBattleBoost,
              ownedCount(for: item) > 0 else {
            return nil
        }

        let remaining = ownedCount(for: item) - 1
        if remaining > 0 {
            inventory[item] = remaining
        } else {
            inventory.removeValue(forKey: item)
        }

        activeBattleBoostItem = item
        saveState()
        return item
    }

    /// バトル中に防弾チョッキが敵のビームまたは必殺技を1度防いだ際に消費消滅させる
    func consumeActiveBattleVestIfPresent() {
        if activeBattleBoostItem == .bulletproofVest {
            activeBattleBoostItem = nil
        }
    }

    /// 1バトル終了後（次のバトル準備時・復活再戦準備時・タイトル帰還時）に1バトル限定アイテムの効果をリセットする
    func clearPerBattleBoostItem() {
        activeBattleBoostItem = nil
    }

    // MARK: - KUMITE Lifecycle Integration
    /// 連勝0から新しくKUMITEを開始する際、予約中の持ち込みアイテム（1個消費）と待機中の救急キットを本挑戦へ確定適用する
    func activateLoadoutForNewKumiteRun() -> (carryIn: BattleItem?, medkit: BattleItem?) {
        let preservedMedkit: BattleItem? = isActiveMedkitFreshlyExchangedAtTitle ? activeRunMedkit : nil

        activeBattleBoostItem = nil
        activeRunCarryInItem = nil
        activeRunMedkit = nil
        isActiveMedkitFreshlyExchangedAtTitle = false

        if let chosen = selectedCarryInItem, chosen.isCarryInSelectable, ownedCount(for: chosen) > 0 {
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

        if let med = queuedMedkit ?? preservedMedkit {
            activeRunMedkit = med
            queuedMedkit = nil
        }

        saveState()
        return (activeRunCarryInItem, activeRunMedkit)
    }

    /// 勝利後タイトル中断状態からKUMITEを再開する際、未装備であれば新たに選択された持ち込みアイテム（1個消費）や救急キットを反映する
    func activatePendingLoadoutForResumedKumite() -> (carryIn: BattleItem?, medkit: BattleItem?) {
        activeBattleBoostItem = nil
        isActiveMedkitFreshlyExchangedAtTitle = false

        if activeRunCarryInItem == nil,
           let chosen = selectedCarryInItem,
           chosen.isCarryInSelectable,
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

    func markReviveUsedInActiveRun() {
        if isActiveMedkitFreshlyExchangedAtTitle {
            isActiveMedkitFreshlyExchangedAtTitle = false
            saveState()
        }
    }

    /// バトル中に回復薬・エナジードリンクをタップ使用した際に消費させる
    func consumeActiveRunCarryInItem() {
        activeRunCarryInItem = nil
        saveState()
    }

    /// KUMITEが完全終了した際に、その挑戦の適用中持ち込みアイテム・救急キット・1戦ブーストをクリアする
    func clearFinishedKumiteRunLoadout() {
        activeBattleBoostItem = nil
        activeRunCarryInItem = nil
        if !isActiveMedkitFreshlyExchangedAtTitle {
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

        UserDefaults.standard.set(isActiveMedkitFreshlyExchangedAtTitle, forKey: activeMedkitUnusedAtTitleKey)
    }
}
