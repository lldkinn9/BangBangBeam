import SwiftUI

/// CPUの思考個性パラメータ（Lv.1〜Lv.11で明確な強弱と戦術差をつける）
struct AITraits: Sendable {
    /// チャージ不足なのに誤って攻撃を選んでしまい「無防備（お手つき）」になる確率
    let fumbleChance: Double
    /// 1チャージ以上あるときの通常ビーム積極度 (0.0〜1.0)
    let aggression: Double
    /// プレイヤーが1チャージ以上持っているときのバリア警戒度 (0.0〜1.0)
    let defenseAwareness: Double
    /// 4チャージ一撃必殺を狙ってチャージを優先する度合い (0.0〜1.0)
    let ultimateGreed: Double
    /// 状況判断の正確さ（相手チャージ0ならバリアを張らない、相手3チャージなら削りに行く等）(0.0〜1.0)
    let readPrecision: Double
}

/// キャラクター表情種別
enum CharacterExpression: String, Sendable {
    case normal
    case fun
    case sad
}

/// プレイヤー（Reo）および勝ち抜き戦の敵11キャラクター定義
struct CharacterProfile: Identifiable, Equatable, Sendable {
    let id: String
    let codeName: String
    let titleLabel: String
    let stageOrder: Int // 0 = Reo, 1...11 = 敵順番
    let ai: AITraits

    nonisolated static func == (lhs: CharacterProfile, rhs: CharacterProfile) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Asset Names
    func standingAsset(for expression: CharacterExpression) -> String {
        "char_\(id)_\(expression.rawValue)"
    }

    var cutinAsset: String {
        "char_\(id)_cutin"
    }

    var ultimateVideoName: String {
        "ult_\(id)"
    }

    // MARK: - Protagonist (Player Fixed)
    static let reo = CharacterProfile(
        id: "reo",
        codeName: "REO",
        titleLabel: "ネオ東京の閃光",
        stageOrder: 0,
        ai: AITraits(fumbleChance: 0, aggression: 0.5, defenseAwareness: 0.5, ultimateGreed: 0.5, readPrecision: 0.5)
    )

    // MARK: - KUMITE 11 Enemies Fixed Loop Order
    // geek → boarder → JK → engineer → alice → defective → spy → Ninja → pirate → skin → oldman
    static let kumiteRoster: [CharacterProfile] = [
        CharacterProfile(
            id: "geek",
            codeName: "GEEK",
            titleLabel: "STAGE 1 // 見習いハッカー (弱)",
            stageOrder: 1,
            ai: AITraits(
                fumbleChance: 0.18,
                aggression: 0.35,
                defenseAwareness: 0.20,
                ultimateGreed: 0.20,
                readPrecision: 0.15
            )
        ),
        CharacterProfile(
            id: "boarder",
            codeName: "BOARDER",
            titleLabel: "STAGE 2 // ストリートボーダー (弱)",
            stageOrder: 2,
            ai: AITraits(
                fumbleChance: 0.12,
                aggression: 0.55,
                defenseAwareness: 0.22,
                ultimateGreed: 0.15,
                readPrecision: 0.25
            )
        ),
        CharacterProfile(
            id: "jk",
            codeName: "JK",
            titleLabel: "STAGE 3 // 電脳ハイスクール (慎重)",
            stageOrder: 3,
            ai: AITraits(
                fumbleChance: 0.08,
                aggression: 0.38,
                defenseAwareness: 0.62,
                ultimateGreed: 0.25,
                readPrecision: 0.38
            )
        ),
        CharacterProfile(
            id: "engineer",
            codeName: "ENGINEER",
            titleLabel: "STAGE 4 // 蓄電クラフトマン (必殺狙い)",
            stageOrder: 4,
            ai: AITraits(
                fumbleChance: 0.05,
                aggression: 0.30,
                defenseAwareness: 0.40,
                ultimateGreed: 0.72,
                readPrecision: 0.45
            )
        ),
        CharacterProfile(
            id: "alice",
            codeName: "ALICE",
            titleLabel: "STAGE 5 // ネオンアイドル (バランス)",
            stageOrder: 5,
            ai: AITraits(
                fumbleChance: 0.03,
                aggression: 0.50,
                defenseAwareness: 0.50,
                ultimateGreed: 0.45,
                readPrecision: 0.55
            )
        ),
        CharacterProfile(
            id: "defective",
            codeName: "DEFECTIVE",
            titleLabel: "STAGE 6 // サイバー捜査官 (速攻連射)",
            stageOrder: 6,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.76,
                defenseAwareness: 0.38,
                ultimateGreed: 0.25,
                readPrecision: 0.65
            )
        ),
        CharacterProfile(
            id: "spy",
            codeName: "SPY",
            titleLabel: "STAGE 7 // 諜報エージェント (鉄壁カウンター)",
            stageOrder: 7,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.48,
                defenseAwareness: 0.75,
                ultimateGreed: 0.50,
                readPrecision: 0.74
            )
        ),
        CharacterProfile(
            id: "ninja",
            codeName: "NINJA",
            titleLabel: "STAGE 8 // 影のシノビ (高速撹乱)",
            stageOrder: 8,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.68,
                defenseAwareness: 0.58,
                ultimateGreed: 0.55,
                readPrecision: 0.82
            )
        ),
        CharacterProfile(
            id: "pirate",
            codeName: "PIRATE",
            titleLabel: "STAGE 9 // 電脳海賊キャプテン (重砲撃)",
            stageOrder: 9,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.62,
                defenseAwareness: 0.55,
                ultimateGreed: 0.78,
                readPrecision: 0.86
            )
        ),
        CharacterProfile(
            id: "skin",
            codeName: "SKIN",
            titleLabel: "STAGE 10 // アンダーボス (威圧制圧)",
            stageOrder: 10,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.70,
                defenseAwareness: 0.68,
                ultimateGreed: 0.68,
                readPrecision: 0.91
            )
        ),
        CharacterProfile(
            id: "oldman",
            codeName: "OLDMAN",
            titleLabel: "STAGE 11 // ネオ東京の達人 (最強)",
            stageOrder: 11,
            ai: AITraits(
                fumbleChance: 0.0,
                aggression: 0.72,
                defenseAwareness: 0.74,
                ultimateGreed: 0.82,
                readPrecision: 0.97
            )
        )
    ]

    /// 連勝数（0始まり）から対戦相手を取得（12人目以降は再度 geek から順番通りループ）
    static func enemy(forStreak streak: Int) -> (profile: CharacterProfile, loopNumber: Int, stageInLoop: Int) {
        let count = kumiteRoster.count
        let safeIndex = max(0, streak) % count
        let loop = (max(0, streak) / count) + 1
        return (kumiteRoster[safeIndex], loop, safeIndex + 1)
    }
}
