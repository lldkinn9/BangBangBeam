import Foundation

/// アプリ内の主要画面定義
enum AppScreen: Equatable, Sendable {
    case title
    case kumiteBattle
    case practiceTutorial

    /// プレイ画面以外では最下部にバナー広告を表示する（将来画面が増えてもデフォルトtrueで安全）
    var showsBottomBannerAd: Bool {
        switch self {
        case .kumiteBattle, .practiceTutorial:
            return false
        case .title:
            return true
        }
    }
}
