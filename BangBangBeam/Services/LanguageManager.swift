import Foundation
import Observation

/// アプリ内の表示言語（日本語 / 英語）
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case japanese = "ja"
    case english = "en"

    nonisolated var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese:
            return "日本語"
        case .english:
            return "English"
        }
    }

    var subtitle: String {
        switch self {
        case .japanese:
            return "Japanese"
        case .english:
            return "英語"
        }
    }
}

/// 初回起動時および設定画面での言語選択（日本語 / 英語）を永続管理するマネージャー
@Observable
@MainActor
final class LanguageManager {
    static let shared = LanguageManager()

    private let selectedLanguageKey = "BangBangBeam.selectedLanguage"
    private let hasSelectedInitialLanguageKey = "BangBangBeam.hasSelectedInitialLanguage"

    /// 現在選択されている言語（変更すると全画面のテキストが即座に切り替わる）
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: selectedLanguageKey)
        }
    }

    /// 初回起動時の言語選択ダイアログを完了済みかどうか
    var hasSelectedInitialLanguage: Bool {
        didSet {
            UserDefaults.standard.set(hasSelectedInitialLanguage, forKey: hasSelectedInitialLanguageKey)
        }
    }

    var isEnglish: Bool {
        language == .english
    }

    private init() {
        let completedInitial = UserDefaults.standard.bool(forKey: hasSelectedInitialLanguageKey)
        self.hasSelectedInitialLanguage = completedInitial

        if let savedRaw = UserDefaults.standard.string(forKey: selectedLanguageKey),
           let savedLang = AppLanguage(rawValue: savedRaw) {
            self.language = savedLang
        } else {
            let prefersJapanese = Locale.preferredLanguages.first?.lowercased().hasPrefix("ja") ?? false
            self.language = prefersJapanese ? .japanese : .english
        }
    }

    /// 初回起動時の言語選択を確定する
    func confirmInitialLanguage(_ chosen: AppLanguage) {
        language = chosen
        hasSelectedInitialLanguage = true
    }

    /// 現在の設定言語に応じたテキストを返す
    func text(_ ja: String, _ en: String) -> String {
        language == .english ? en : ja
    }
}

/// 全View・Modelから簡潔に日英テキストを解決するヘルパー（`@Observable` により言語切替時に自動再描画される）
@MainActor
func L10n(_ ja: String, _ en: String) -> String {
    LanguageManager.shared.language == .english ? en : ja
}
