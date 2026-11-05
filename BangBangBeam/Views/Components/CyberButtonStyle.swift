import SwiftUI

/// サイバーパンク仕様のポリゴン発光ボタンスタイル
struct CyberButtonStyle: ButtonStyle {
    var primaryColor: Color = .cyberCyan
    var secondaryColor: Color = .cyberEmerald
    var cutSize: CGFloat = 14
    var fillOpacity: Double = 0.22

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    CyberShape(cutSize: cutSize)
                        .fill(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(configuration.isPressed ? fillOpacity + 0.22 : fillOpacity),
                                    secondaryColor.opacity(configuration.isPressed ? fillOpacity + 0.16 : fillOpacity * 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    CyberShape(cutSize: cutSize)
                        .fill(Color.cyberBlack.opacity(0.45))

                    CyberShape(cutSize: cutSize)
                        .strokeBorder(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: configuration.isPressed ? 2.4 : 1.6
                        )
                }
            )
            .clipShape(CyberShape(cutSize: cutSize))
            .shadow(
                color: primaryColor.opacity(configuration.isPressed ? 0.75 : 0.42),
                radius: configuration.isPressed ? 14 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

