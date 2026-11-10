import SwiftUI

/// アイテムの発動・適用区分
enum BattleItemCategory: String, Sendable {
    /// 持ち込むだけでKUMITE中に効果を発揮するパッシブ／自動発動アイテム（ハート・電池・防弾チョッキ）
    case passiveCarryIn
    /// 持ち込んでバトル中にREOのハート上のアイコンをタップした瞬間に発動するアイテム（回復薬・エナジードリンク）
    case activeCarryIn
    /// 購入と同時に自動適用され、持ち込みアイテムとも併用できる救急キット（小・中・大）
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

    /// 効果説明文
    var effectDescription: String {
        switch self {
        case .heart:
            return "初期体力を1増やす（体力が4からスタート）"
        case .battery:
            return "バトル開始時に最初からチャージが1溜まっている（1ターン目からビームも可能）"
        case .bulletproofVest:
            return "相手のビームを一度だけ防ぐ（必殺技も一度防げる）"
        case .healingPotion:
            return "（バトル中に使用）体力を全回復する"
        case .energyDrink:
            return "（バトル中に使用）チャージが2溜まる"
        case .medkitSmall:
            return "（購入と同時に自動適用）次のKUMITEでの広告動画を見て復活の回数が1回増える"
        case .medkitMedium:
            return "（購入と同時に自動適用）次のKUMITEでの広告動画を見て復活の回数が2回増える"
        case .medkitLarge:
            return "（購入と同時に自動適用）次のKUMITEでの広告動画を見て復活の回数が3回増える"
        }
    }

    /// アイテム種別
    var category: BattleItemCategory {
        switch self {
        case .heart, .battery, .bulletproofVest:
            return .passiveCarryIn
        case .healingPotion, .energyDrink:
            return .activeCarryIn
        case .medkitSmall, .medkitMedium, .medkitLarge:
            return .autoMedkit
        }
    }

    /// 持ち込み枠（1つ選択）の対象アイテムかどうか
    var isCarryInSelectable: Bool {
        category != .autoMedkit
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
        case .passiveCarryIn:
            return "持ち込み自動"
        case .activeCarryIn:
            return "バトル中使用"
        case .autoMedkit:
            return "購入時自動適用"
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

    /// SF Symbols ベースシンボル名
    var symbolName: String {
        switch self {
        case .heart:
            return "heart.fill"
        case .battery:
            return "battery.100.bolt"
        case .bulletproofVest:
            return "shield.checkered"
        case .healingPotion:
            return "cross.vial.fill"
        case .energyDrink:
            return "bolt.ring.closed"
        case .medkitSmall, .medkitMedium, .medkitLarge:
            return "cross.case.fill"
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

    /// 持ち込み可能な5種類一覧
    static var carryInItems: [BattleItem] {
        [.heart, .battery, .bulletproofVest, .healingPotion, .energyDrink]
    }

    /// 購入即時適用の救急キット3種類一覧
    static var medkitItems: [BattleItem] {
        [.medkitSmall, .medkitMedium, .medkitLarge]
    }
}
