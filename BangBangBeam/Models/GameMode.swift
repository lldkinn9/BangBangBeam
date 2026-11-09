import Foundation

/// バトルのゲームモード定義
enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case kumite
    case practice

    nonisolated var id: String { rawValue }

    var title: String {
        switch self {
        case .kumite:
            return "KUMITE"
        case .practice:
            return "PRACTICE"
        }
    }

    var subtitle: String {
        switch self {
        case .kumite:
            return "1vs1 CPU対戦（勝負制）"
        case .practice:
            return "実践画面で学ぶルールガイド"
        }
    }
}

