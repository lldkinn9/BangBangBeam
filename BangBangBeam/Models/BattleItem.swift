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

/// ポイント交換アイテム全8種の定義
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
            return "ハート"
        case .battery:
            return "電池"
        case .bulletproofVest:
            return "防弾チョッキ"
        case .healingPotion:
            return "回復薬"
        case .energyDrink:
            return "エナジードリンク"
        case .medkitSmall:
            return "救急キット(小)"
        case .medkitMedium:
            return "救急キット(中)"
        case .medkitLarge:
            return "救急キット(大)"
        }
    }

    /// VS画面のコンパクト選択ボタン用の短縮名
    var compactVsLabel: String {
        switch self {
        case .heart:
            return "ハート"
        case .battery:
            return "電池"
        case .bulletproofVest:
            return "チョッキ"
        default:
            return displayName
        }
    }

    /// VS画面で選択した際に表示する1行効果ガイド
    var vsSelectionSummary: String {
        switch self {
        case .heart:
            return "このバトルの体力が 4 からスタート！"
        case .battery:
            return "チャージ 1 の状態からバトルスタート！"
        case .bulletproofVest:
            return "相手のビーム・必殺技を一度だけ防御！"
        default:
            return ""
        }
    }

    /// 必要ポイント数
    var pointCost: Int {
        switch self {
        case .heart:
            return 10
        case .battery:
            return 10
        case .bulletproofVest:
            return 20
        case .healingPotion:
            return 30
        case .energyDrink:
            return 30
        case .medkitSmall:
            return 30
        case .medkitMedium:
            return 40
        case .medkitLarge:
            return 50
        }
    }

    /// 効果説明文（指定文言準拠）
    var effectDescription: String {
        switch self {
        case .heart:
            return "初期体力を1増やす（体力が4からスタート）"
        case .battery:
            return "チャージが1溜まった状態からバトルスタート\n（1ターン目からビームも可能）"
        case .bulletproofVest:
            return "相手のビームを一度だけ防ぐ（必殺技も一度防げる）"
        case .healingPotion:
            return "体力を全回復する（バトル中に使用）"
        case .energyDrink:
            return "チャージが2溜まる（バトル中に使用）"
        case .medkitSmall:
            return "次のKUMITEでの広告動画を見てリセットの回数が1回増える"
        case .medkitMedium:
            return "次のKUMITEでの広告動画を見てリセットの回数が2回増える"
        case .medkitLarge:
            return "次のKUMITEでの広告動画を見てリセットの回数が3回増える"
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

    /// 交換して複数ストック可能なアイテムかどうか（ハート・電池・防弾チョッキ・回復薬・エナジードリンク）
    var isStockable: Bool {
        category != .autoMedkit
    }

    /// ITEM画面の「KUMITE持ち込み枠（1つ選択）」の対象アイテムかどうか（回復薬・エナジードリンク）
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
            return "VS画面で選択（1戦）"
        case .activeCarryIn:
            return "バトル中使用"
        case .autoMedkit:
            return "交換時自動適用"
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
            return "1回"
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

    /// 毎バトル前のVS画面で選択可能な3種類一覧（1バトル効果・複数ストック可能）
    static var vsBattleBoostItems: [BattleItem] {
        [.heart, .battery, .bulletproofVest]
    }

    /// ITEM画面でKUMITEへ持ち込み設定するバトル中使用アイテム2種類一覧
    static var carryInItems: [BattleItem] {
        [.healingPotion, .energyDrink]
    }

    /// 交換と同時に自動適用の救急キット3種類一覧
    static var medkitItems: [BattleItem] {
        [.medkitSmall, .medkitMedium, .medkitLarge]
    }
}
