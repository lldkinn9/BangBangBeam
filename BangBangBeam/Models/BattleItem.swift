import SwiftUI

/// アイテムの発動・適用区分
enum BattleItemCategory: String, Sendable {
    /// 複数交換してストック可能・毎バトル前のVS画面で使用するかを選択する「1バトル限定」アイテム（ハート・電池・防弾チョッキ）
    case vsBattleBoost
    /// ITEM画面で次のKUMITEへ1つ持ち込み、バトル中にREOのハート上のアイコンをタップした瞬間に発動するアイテム（回復薬・エナジードリンク）
    case activeCarryIn
    /// 交換と同時に自動適用され、他アイテムとも併用できる救急キット（小・中・大）
    case autoMedkit
}

/// ポイント交換アイテム全8種の定義（日英リアルタイム切替対応）
enum BattleItem: String, CaseIterable, Identifiable, Sendable {
    case heart
    case battery
    case bulletproofVest
    case healingPotion
    case energyDrink
    case medkitSmall
    case medkitMedium
    case medkitLarge

    nonisolated var id: String { rawValue }

    /// 表示名称
    var displayName: String {
        switch self {
        case .heart:
            return L10n("ハート", "Heart")
        case .battery:
            return L10n("電池", "Battery")
        case .bulletproofVest:
            return L10n("防弾チョッキ", "Bulletproof Vest")
        case .healingPotion:
            return L10n("回復薬", "Healing Potion")
        case .energyDrink:
            return L10n("エナジードリンク", "Energy Drink")
        case .medkitSmall:
            return L10n("救急キット(小)", "Medkit (S)")
        case .medkitMedium:
            return L10n("救急キット(中)", "Medkit (M)")
        case .medkitLarge:
            return L10n("救急キット(大)", "Medkit (L)")
        }
    }

    /// VS画面のコンパクト選択ボタン用の短縮名
    var compactVsLabel: String {
        switch self {
        case .heart:
            return L10n("ハート", "Heart")
        case .battery:
            return L10n("電池", "Battery")
        case .bulletproofVest:
            return L10n("チョッキ", "Vest")
        default:
            return displayName
        }
    }

    /// VS画面で選択した際に表示する1行効果ガイド
    var vsSelectionSummary: String {
        switch self {
        case .heart:
            return L10n("このバトルの体力が 4 からスタート！", "Start this battle with 4 HP!")
        case .battery:
            return L10n("チャージ 1 の状態からバトルスタート！", "Start this battle with 1 Charge!")
        case .bulletproofVest:
            return L10n("相手のビーム・必殺技を一度だけ防御！", "Blocks an enemy Beam or Ultimate once!")
        default:
            return ""
        }
    }

    /// 必要ポイント数
    var pointCost: Int {
        switch self {
        case .heart:
            return 5
        case .battery:
            return 5
        case .bulletproofVest:
            return 15
        case .healingPotion:
            return 20
        case .energyDrink:
            return 20
        case .medkitSmall:
            return 10
        case .medkitMedium:
            return 25
        case .medkitLarge:
            return 35
        }
    }

    /// 効果説明文
    var effectDescription: String {
        switch self {
        case .heart:
            return L10n(
                "初期体力を1増やす（体力が4からスタート）",
                "Increases starting HP by 1 (Start battle with 4 HP)"
            )
        case .battery:
            return L10n(
                "チャージが1溜まった状態からバトルスタート\n（1ターン目からビームも可能）",
                "Start battle with 1 Charge already stored\n(Can fire BEAM on Turn 1)"
            )
        case .bulletproofVest:
            return L10n(
                "相手のビームを一度だけ防ぐ（必殺技も一度防げる）",
                "Blocks an enemy Beam once (Can also block Ultimate once)"
            )
        case .healingPotion:
            return L10n(
                "体力を全回復する（バトル中に使用）",
                "Fully restores HP (Tap icon during battle)"
            )
        case .energyDrink:
            return L10n(
                "チャージが2溜まる（バトル中に使用）",
                "Gains +2 Charge instantly (Tap icon during battle)"
            )
        case .medkitSmall:
            return L10n(
                "次のKUMITEでの広告動画を見てリセットの回数が1回増える",
                "Adds +1 video-ad revive reset for your next KUMITE"
            )
        case .medkitMedium:
            return L10n(
                "次のKUMITEでの広告動画を見てリセットの回数が2回増える",
                "Adds +2 video-ad revive resets for your next KUMITE"
            )
        case .medkitLarge:
            return L10n(
                "次のKUMITEでの広告動画を見てリセットの回数が3回増える",
                "Adds +3 video-ad revive resets for your next KUMITE"
            )
        }
    }

    /// アイテム種別
    var category: BattleItemCategory {
        switch self {
        case .heart, .battery, .bulletproofVest:
            return .vsBattleBoost
        case .healingPotion, .energyDrink:
            return .activeCarryIn
        case .medkitSmall, .medkitMedium, .medkitLarge:
            return .autoMedkit
        }
    }

    /// 交換して複数ストック可能なアイテムかどうか
    var isStockable: Bool {
        category != .autoMedkit
    }

    /// ITEM画面の「KUMITE持ち込み枠（1つ選択）」の対象アイテムかどうか
    var isCarryInSelectable: Bool {
        category == .activeCarryIn
    }

    /// バトル中にアイコンタップで即時発動するアイテムかどうか
    var isTapUsableInBattle: Bool {
        category == .activeCarryIn
    }

    /// 救急キットの追加復活回数
    var bonusRevives: Int {
        switch self {
        case .medkitSmall:
            return 1
        case .medkitMedium:
            return 2
        case .medkitLarge:
            return 3
        default:
            return 0
        }
    }

    /// 種別バッジテキスト
    var usageBadgeText: String {
        switch category {
        case .vsBattleBoost:
            return L10n("VS画面で選択（1戦）", "VS Select (1 Battle)")
        case .activeCarryIn:
            return L10n("バトル中使用", "In-Battle Use")
        case .autoMedkit:
            return L10n("交換時自動適用", "Auto-Applied")
        }
    }

    /// サイバーネオンテーマカラー
    var themeColor: Color {
        switch self {
        case .heart:
            return Color(red: 1.0, green: 0.30, blue: 0.58)
        case .battery:
            return Color.cyberEmerald
        case .bulletproofVest:
            return Color.cyberCyan
        case .healingPotion:
            return Color(red: 0.25, green: 1.0, blue: 0.68)
        case .energyDrink:
            return Color.cyberAmber
        case .medkitSmall:
            return Color(red: 0.38, green: 0.88, blue: 1.0)
        case .medkitMedium:
            return Color(red: 0.85, green: 0.42, blue: 1.0)
        case .medkitLarge:
            return Color(red: 1.0, green: 0.82, blue: 0.22)
        }
    }

    /// アイコン右下に添えるミニサブテキスト
    var iconCornerTag: String? {
        switch self {
        case .heart:
            return "+1"
        case .battery:
            return "+1"
        case .bulletproofVest:
            return L10n("1回", "1x")
        case .healingPotion:
            return "MAX"
        case .energyDrink:
            return "+2"
        case .medkitSmall:
            return "+1"
        case .medkitMedium:
            return "+2"
        case .medkitLarge:
            return "+3"
        }
    }

    static var vsBattleBoostItems: [BattleItem] {
        [.heart, .battery, .bulletproofVest]
    }

    static var carryInItems: [BattleItem] {
        [.healingPotion, .energyDrink]
    }

    static var medkitItems: [BattleItem] {
        [.medkitSmall, .medkitMedium, .medkitLarge]
    }
}
