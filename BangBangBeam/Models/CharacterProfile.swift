import SwiftUI

/// CPUの思考個性パラメータ（お手つきは一切せず、キャラクターごとに明確な強弱と戦術差をつける）
struct AITraits: Sendable {
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

/// ステージ進行解決結果
struct EnemyStageInfo: Sendable {
    let profile: CharacterProfile
    let loopNumber: Int
    let stageInLoop: Int
    let totalStagesInLoop: Int
}

/// プレイヤー（Reo）および勝ち抜き戦の敵20キャラクター（1周目11名 ＋ 2周目23人目以降追加9名）定義
struct CharacterProfile: Identifiable, Equatable, Sendable {
    let id: String
    let codeName: String
    let titleLabel: String
    let stageOrder: Int // 0 = Reo, 1...11 = 1周目基本敵, 12...20 = 2周目追加敵
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
        ai: AITraits(aggression: 0.5, defenseAwareness: 0.5, ultimateGreed: 0.5, readPrecision: 0.5)
    )

    /// 1戦目・Practiceガイド相手（GEEK）
    static var geek: CharacterProfile {
        baseKumiteRoster[0]
    }

    // MARK: - 1周目 基本敵11キャラクター（2周目以降の前半11名としても登場）
    // geek → boarder → JK → engineer → alice → defective → spy → Ninja → pirate → skin → oldman
    static let baseKumiteRoster: [CharacterProfile] = [
        CharacterProfile(
            id: "geek",
            codeName: "GEEK",
            titleLabel: "見習いハッカー (弱)",
            stageOrder: 1,
            ai: AITraits(
                aggression: 0.35,
                defenseAwareness: 0.20,
                ultimateGreed: 0.20,
                readPrecision: 0.15
            )
        ),
        CharacterProfile(
            id: "boarder",
            codeName: "BOARDER",
            titleLabel: "ストリートボーダー (弱)",
            stageOrder: 2,
            ai: AITraits(
                aggression: 0.55,
                defenseAwareness: 0.22,
                ultimateGreed: 0.15,
                readPrecision: 0.25
            )
        ),
        CharacterProfile(
            id: "jk",
            codeName: "JK",
            titleLabel: "電脳ハイスクール (慎重)",
            stageOrder: 3,
            ai: AITraits(
                aggression: 0.38,
                defenseAwareness: 0.62,
                ultimateGreed: 0.25,
                readPrecision: 0.38
            )
        ),
        CharacterProfile(
            id: "engineer",
            codeName: "ENGINEER",
            titleLabel: "蓄電クラフトマン (必殺狙い)",
            stageOrder: 4,
            ai: AITraits(
                aggression: 0.30,
                defenseAwareness: 0.40,
                ultimateGreed: 0.72,
                readPrecision: 0.45
            )
        ),
        CharacterProfile(
            id: "alice",
            codeName: "ALICE",
            titleLabel: "ネオンアイドル (バランス)",
            stageOrder: 5,
            ai: AITraits(
                aggression: 0.50,
                defenseAwareness: 0.50,
                ultimateGreed: 0.45,
                readPrecision: 0.55
            )
        ),
        CharacterProfile(
            id: "defective",
            codeName: "DEFECTIVE",
            titleLabel: "サイバー捜査官 (速攻連射)",
            stageOrder: 6,
            ai: AITraits(
                aggression: 0.76,
                defenseAwareness: 0.38,
                ultimateGreed: 0.25,
                readPrecision: 0.65
            )
        ),
        CharacterProfile(
            id: "spy",
            codeName: "SPY",
            titleLabel: "諜報エージェント (鉄壁カウンター)",
            stageOrder: 7,
            ai: AITraits(
                aggression: 0.48,
                defenseAwareness: 0.75,
                ultimateGreed: 0.50,
                readPrecision: 0.74
            )
        ),
        CharacterProfile(
            id: "ninja",
            codeName: "NINJA",
            titleLabel: "影のシノビ (高速撹乱)",
            stageOrder: 8,
            ai: AITraits(
                aggression: 0.68,
                defenseAwareness: 0.58,
                ultimateGreed: 0.55,
                readPrecision: 0.82
            )
        ),
        CharacterProfile(
            id: "pirate",
            codeName: "PIRATE",
            titleLabel: "電脳海賊キャプテン (重砲撃)",
            stageOrder: 9,
            ai: AITraits(
                aggression: 0.62,
                defenseAwareness: 0.55,
                ultimateGreed: 0.78,
                readPrecision: 0.86
            )
        ),
        CharacterProfile(
            id: "skin",
            codeName: "SKIN",
            titleLabel: "アンダーボス (威圧制圧)",
            stageOrder: 10,
            ai: AITraits(
                aggression: 0.70,
                defenseAwareness: 0.68,
                ultimateGreed: 0.68,
                readPrecision: 0.91
            )
        ),
        CharacterProfile(
            id: "oldman",
            codeName: "OLDMAN",
            titleLabel: "ネオ東京の達人 (熟練)",
            stageOrder: 11,
            ai: AITraits(
                aggression: 0.72,
                defenseAwareness: 0.74,
                ultimateGreed: 0.82,
                readPrecision: 0.95
            )
        )
    ]

    // MARK: - 2周目（23人目）以降に解放される追加9キャラクター
    // tt → mei → clown → owl → rondo → ive → joker → elf → rui
    static let extraLoopRoster: [CharacterProfile] = [
        CharacterProfile(
            id: "tt",
            codeName: "TT",
            titleLabel: "2周目刺客 // ツインテック",
            stageOrder: 12,
            ai: AITraits(
                aggression: 0.66,
                defenseAwareness: 0.64,
                ultimateGreed: 0.62,
                readPrecision: 0.88
            )
        ),
        CharacterProfile(
            id: "mei",
            codeName: "MEI",
            titleLabel: "電脳武闘娘 (連撃ラッシュ)",
            stageOrder: 13,
            ai: AITraits(
                aggression: 0.78,
                defenseAwareness: 0.58,
                ultimateGreed: 0.55,
                readPrecision: 0.90
            )
        ),
        CharacterProfile(
            id: "clown",
            codeName: "CLOWN",
            titleLabel: "幻惑ピエロ (変幻トリックスター)",
            stageOrder: 14,
            ai: AITraits(
                aggression: 0.58,
                defenseAwareness: 0.80,
                ultimateGreed: 0.68,
                readPrecision: 0.91
            )
        ),
        CharacterProfile(
            id: "owl",
            codeName: "OWL",
            titleLabel: "夜天の監視者 (精密スナイプ)",
            stageOrder: 15,
            ai: AITraits(
                aggression: 0.72,
                defenseAwareness: 0.72,
                ultimateGreed: 0.60,
                readPrecision: 0.93
            )
        ),
        CharacterProfile(
            id: "rondo",
            codeName: "RONDO",
            titleLabel: "残響のマエストロ (拍子支配)",
            stageOrder: 16,
            ai: AITraits(
                aggression: 0.68,
                defenseAwareness: 0.76,
                ultimateGreed: 0.75,
                readPrecision: 0.94
            )
        ),
        CharacterProfile(
            id: "ive",
            codeName: "IVE",
            titleLabel: "ネオンヴァルキリー (高速制圧)",
            stageOrder: 17,
            ai: AITraits(
                aggression: 0.80,
                defenseAwareness: 0.68,
                ultimateGreed: 0.72,
                readPrecision: 0.95
            )
        ),
        CharacterProfile(
            id: "joker",
            codeName: "JOKER",
            titleLabel: "切り札の道化師 (必殺カウンター)",
            stageOrder: 18,
            ai: AITraits(
                aggression: 0.74,
                defenseAwareness: 0.78,
                ultimateGreed: 0.84,
                readPrecision: 0.96
            )
        ),
        CharacterProfile(
            id: "elf",
            codeName: "ELF",
            titleLabel: "星霊サイバネティクス (超蓄電)",
            stageOrder: 19,
            ai: AITraits(
                aggression: 0.70,
                defenseAwareness: 0.76,
                ultimateGreed: 0.88,
                readPrecision: 0.97
            )
        ),
        CharacterProfile(
            id: "rui",
            codeName: "RUI",
            titleLabel: "深淵の覇者 (真・最強)",
            stageOrder: 20,
            ai: AITraits(
                aggression: 0.78,
                defenseAwareness: 0.80,
                ultimateGreed: 0.88,
                readPrecision: 0.99
            )
        )
    ]

    /// 1周目の基本11名（既存互換プロパティ）
    static var kumiteRoster: [CharacterProfile] {
        baseKumiteRoster
    }

    /// 2周目以降の20名フルループ（既存11名 → 追加9名）
    static var fullLoopRoster: [CharacterProfile] {
        baseKumiteRoster + extraLoopRoster
    }

    /// 連勝数（0始まり）から対戦相手を取得
    /// - 0〜10連勝（1〜11人目 / 1周目）: 既存11名のみ
    /// - 11〜30連勝（12〜31人目 / 2周目）: 12〜22人目＝既存11名、23〜31人目＝追加9名(tt〜rui)
    /// - 31連勝以降（32人目以降 / 3周目〜）: 「既存11名 → 追加9名」の20名サイクルを周回
    static func enemy(forStreak streak: Int) -> EnemyStageInfo {
        let safeStreak = max(0, streak)
        let baseCount = baseKumiteRoster.count // 11

        if safeStreak < baseCount {
            return EnemyStageInfo(
                profile: baseKumiteRoster[safeStreak],
                loopNumber: 1,
                stageInLoop: safeStreak + 1,
                totalStagesInLoop: baseCount
            )
        }

        let full = fullLoopRoster // 20 (11 + 9)
        let offset = safeStreak - baseCount
        let loop = (offset / full.count) + 2
        let indexInFull = offset % full.count

        return EnemyStageInfo(
            profile: full[indexInFull],
            loopNumber: loop,
            stageInLoop: indexInFull + 1,
            totalStagesInLoop: full.count
        )
    }
}
