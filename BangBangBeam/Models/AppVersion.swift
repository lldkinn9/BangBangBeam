import Foundation

/// アプリバージョン管理（デプロイごとに npm run version:bump で 0.0.1 ずつ自動更新）
enum AppVersion {
    static let current = "1.0.6"

    static var displayText: String {
        "v\(current)"
    }
}

