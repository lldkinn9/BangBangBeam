import SwiftUI

/// バトル中に選択可能なコマンド（通常3コマンド CHARGE / BEAM / BARRIER ＋ 4チャージ解放 ULTIMATE）
enum GameAction: String, CaseIterable, Identifiable, Sendable {
    case charge
    case beam
    case barrier
    case megaBeam

    nonisolated var id: String { rawValue }

    /// 通常時に横並びで表示する3つの基本コマンド
    static let standardCommands: [GameAction] = [.charge, .beam, .barrier]

    /// コマンド名（日英対応）
    var label: String {
        switch self {
        case .charge:   return L10n("チャージ", "CHARGE")
        case .beam:     return L10n("ビーム", "BEAM")
        case .barrier:  return L10n("バリア", "BARRIER")
        case .megaBeam: return "ULTIMATE"
        }
    }

    /// ボタン表示用の英語コマンド名
    var codeName: String {
        switch self {
        case .charge:   return "CHARGE"
        case .beam:     return "BEAM"
        case .barrier:  return "BARRIER"
        case .megaBeam: return "ULTIMATE"
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

    /// 消費チャージ数（ULTIMATEは4チャージで一撃必殺）
    var cost: Int {
        switch self {
        case .charge:   return 0
        case .beam:     return 1
        case .barrier:  return 0
        case .megaBeam: return 4
        }
    }

    /// 獲得チャージ数
    var gain: Int {
        switch self {
        case .charge:   return 1
        case .beam:     return 0
        case .barrier:  return 0
        case .megaBeam: return 0
        }
    }

    /// 横並び3ボタン用のコンパクト効果表記
    var shortBadge: String {
        switch self {
        case .charge:   return L10n("気力 +1", "Charge +1")
        case .beam:     return L10n("消費 1", "Cost 1")
        case .barrier:  return L10n("防御", "Guard")
        case .megaBeam: return L10n("一撃必殺", "One-Hit KO")
        }
    }

    /// コスト・効果バッジ文字列
    var costBadge: String {
        switch self {
        case .charge:   return L10n("気力 +1", "Charge +1")
        case .beam:     return L10n("消費 1 / HP-1", "Cost 1 / HP-1")
        case .barrier:  return L10n("消費 0 / 防御", "Cost 0 / Guard")
        case .megaBeam: return L10n("消費 4 / 一撃必殺", "Cost 4 / One-Hit KO")
        }
    }

    /// 対応する手イラストアセット名
    var handAssetName: String {
        switch self {
        case .charge:   return "hand_charge"
        case .beam:     return "hand_beam"
        case .barrier:  return "hand_barrier"
        case .megaBeam: return "hand_beam"
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

/// 3拍目で実際に解決された行動結果（チャージ不足時はお手つき無防備状態 .fumble になる）
enum ResolvedMove: Equatable, Sendable {
    case valid(GameAction)
    case fumble(attempted: GameAction)

    nonisolated static func == (lhs: ResolvedMove, rhs: ResolvedMove) -> Bool {
        switch (lhs, rhs) {
        case let (.valid(a), .valid(b)):
            return a == b
        case let (.fumble(a), .fumble(b)):
            return a == b
        default:
            return false
        }
    }

    var displayLabel: String {
        switch self {
        case .valid(let act):
            return "\(act.emoji) \(act.label)"
        case .fumble(let attempted):
            return L10n("💦 お手つき(\(attempted.label)不発)", "💦 Fumble (\(attempted.label))")
        }
    }

    var accentColor: Color {
        switch self {
        case .valid(let act):
            return act.accentColor
        case .fumble:
            return .cyberDanger
        }
    }

    var handAssetName: String? {
        switch self {
        case .valid(let act):
            return act.handAssetName
        case .fumble:
            return nil
        }
    }

    /// 無防備状態（通常ビームが直撃する状態：チャージ中 または お手つき不発）
    var isVulnerableToBeam: Bool {
        switch self {
        case .valid(.charge):
            return true
        case .fumble:
            return true
        default:
            return false
        }
    }
}
