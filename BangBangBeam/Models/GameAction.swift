import SwiftUI

/// バトル中に選択可能な4種類のコマンド
enum GameAction: String, CaseIterable, Identifiable, Sendable {
    case charge
    case beam
    case barrier
    case megaBeam

    nonisolated var id: String { rawValue }

    /// 日本語コマンド名
    var label: String {
        switch self {
        case .charge:   return "チャージ"
        case .beam:     return "ビーム"
        case .barrier:  return "バリア"
        case .megaBeam: return "メガビーム"
        }
    }

    /// 英語サブタイトル
    var codeName: String {
        switch self {
        case .charge:   return "CHARGE"
        case .beam:     return "BEAM"
        case .barrier:  return "BARRIER"
        case .megaBeam: return "MEGA BEAM"
        }
    }

    /// アイコン絵文字
    var emoji: String {
        switch self {
        case .charge:   return "⚡️"
        case .beam:     return "💥"
        case .barrier:  return "🛡️"
        case .megaBeam: return "🌟"
        }
    }

    /// 消費気力
    var cost: Int {
        switch self {
        case .charge:   return 0
        case .beam:     return 1
        case .barrier:  return 0
        case .megaBeam: return 2
        }
    }

    /// 獲得気力（決着がつかなかったターン終了時に付与）
    var gain: Int {
        switch self {
        case .charge:   return 1
        case .beam:     return 0
        case .barrier:  return 0
        case .megaBeam: return 0
        }
    }

    /// コスト・効果バッジ文字列
    var costBadge: String {
        switch self {
        case .charge:   return "気力 +1"
        case .beam:     return "消費 1"
        case .barrier:  return "消費 0"
        case .megaBeam: return "消費 2・貫通"
        }
    }

    /// コマンドごとのネオンアクセントカラー
    var accentColor: Color {
        switch self {
        case .charge:   return .cyberEmerald
        case .beam:     return .cyberCyan
        case .barrier:  return Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255)
        case .megaBeam: return .cyberAmber
        }
    }
}

