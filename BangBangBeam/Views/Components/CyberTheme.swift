import SwiftUI
import UIKit
import CoreHaptics

// MARK: - Cyberpunk Color Palette (Neo Tokyo 2099)
extension Color {
    /// メインカラー1: ネオンシアン (#06B6D4)
    static let cyberCyan = Color(red: 0x06 / 255.0, green: 0xB6 / 255.0, blue: 0xD4 / 255.0)

    /// メインカラー2: エメラルドグリーン (#10B981)
    static let cyberEmerald = Color(red: 0x10 / 255.0, green: 0xB9 / 255.0, blue: 0x81 / 255.0)

    /// ベースブラック (#05080F)
    static let cyberBlack = Color(red: 0x05 / 255.0, green: 0x08 / 255.0, blue: 0x0F / 255.0)

    /// パネル背景ダークスレート (#0D1526)
    static let cyberPanel = Color(red: 0x0D / 255.0, green: 0x15 / 255.0, blue: 0x26 / 255.0)

    /// 超必殺技アクセント: ネオンアンバー (#F59E0B)
    static let cyberAmber = Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)

    /// 警告・敗北アクセント: ネオンクリムゾン (#EF4444)
    static let cyberDanger = Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0)
}

// MARK: - Haptic Feedback Manager（共有ジェネレータ再利用＋事前ウォームアップで1戦目初拍のIPC遅延を防止）
@MainActor
enum HapticManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)

    /// 1戦目開始前などにTaptic Engineを事前準備し、初回拍でのメインスレッド詰まりを防ぐ
    static func warmUp(enabled: Bool = true) {
        guard enabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        rigidGenerator.prepare()
    }

    /// 1・2拍目「バン！」: Light Impact
    static func playLight(enabled: Bool = true) {
        guard enabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// コマンド選択時: Medium Impact
    static func playMedium(enabled: Bool = true) {
        guard enabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// 3拍目「ビーム！」激突解決時: Heavy Impact
    static func playHeavy(enabled: Bool = true) {
        guard enabled else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    /// お手つき自滅時: Rigid Impact
    static func playRigid(enabled: Bool = true) {
        guard enabled else { return }
        rigidGenerator.impactOccurred()
        rigidGenerator.prepare()
    }
}
