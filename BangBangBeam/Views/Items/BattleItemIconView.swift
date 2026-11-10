import SwiftUI

/// サイバーパンク調でデザイン描画する各バトルアイテムの専用ネオンアイコン
struct BattleItemIconView: View {
    let item: BattleItem
    var size: CGFloat = 44
    var isInteractivePulse: Bool = false

    @State private var pulse: Bool = false

    var body: some View {
        let color = item.themeColor

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.09, blue: 0.17).opacity(0.95),
                            color.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.92), color, color.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isInteractivePulse ? 2.2 : 1.6
                        )
                )
                .shadow(color: color.opacity(isInteractivePulse ? (pulse ? 0.95 : 0.55) : 0.55), radius: isInteractivePulse ? (pulse ? 10 : 5) : 6)

            itemArtwork(size: size, color: color)

            if let tag = item.iconCornerTag {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(tag)
                            .font(.system(size: max(8.5, size * 0.21), weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, max(3.5, size * 0.09))
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(color, lineWidth: 1)
                                    )
                            )
                            .shadow(color: color, radius: 3)
                    }
                }
                .padding(2)
            }

            if isInteractivePulse {
                VStack {
                    Text("TAP")
                        .font(.system(size: max(7.5, size * 0.18), weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(color, in: Capsule())
                        .shadow(color: color, radius: 4)
                        .offset(y: -size * 0.14)
                    Spacer()
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isInteractivePulse && pulse ? 1.06 : 1.0)
        .onAppear {
            guard isInteractivePulse else { return }
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private func itemArtwork(size: CGFloat, color: Color) -> some View {
        switch item {
        case .heart:
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.48, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color, radius: 6)

                Image(systemName: "plus")
                    .font(.system(size: size * 0.20, weight: .black))
                    .foregroundStyle(Color(red: 0.12, green: 0.02, blue: 0.08))
            }

        case .battery:
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.09)
                    .strokeBorder(color, lineWidth: 2)
                    .frame(width: size * 0.34, height: size * 0.50)
                    .background(
                        RoundedRectangle(cornerRadius: size * 0.07)
                            .fill(color.opacity(0.35))
                    )
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.30, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: color, radius: 5)
            }

        case .bulletproofVest:
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: size * 0.50, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color, Color(red: 0.05, green: 0.42, blue: 0.68)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color, radius: 6)

                Image(systemName: "checkmark.shield")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.20))
            }

        case .healingPotion:
            ZStack {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: size * 0.48, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color, radius: 6)
            }

        case .energyDrink:
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(
                        LinearGradient(
                            colors: [.white, color, Color(red: 0.90, green: 0.42, blue: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.32, height: size * 0.52)
                    .shadow(color: color, radius: 6)

                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.28, weight: .black))
                    .foregroundStyle(Color(red: 0.15, green: 0.06, blue: 0.0))
            }

        case .medkitSmall, .medkitMedium, .medkitLarge:
            let rankLabel: String = {
                switch item {
                case .medkitSmall: return "S"
                case .medkitMedium: return "M"
                case .medkitLarge: return "L"
                default: return ""
                }
            }()

            ZStack {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: size * 0.48, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color, radius: 6)

                Text(rankLabel)
                    .font(.system(size: size * 0.19, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.08, blue: 0.16))
                    .offset(y: size * 0.04)
            }
        }
    }
}

/// バトル画面の「REOのハートの上」に表示するアイコンバー
/// - 1戦限定のVS選択アイテム（ハート・電池・防弾チョッキ）、KUMITE持ち込みアイテム（回復薬・エナジードリンク）、適用中の救急キットを表示
/// - バトル中に使用するアイテム（回復薬・エナジードリンク）はタップした瞬間に即座に効果が適用される
struct PlayerBattleItemHudBar: View {
    let battleBoostItem: BattleItem?
    let carryInItem: BattleItem?
    let medkitItem: BattleItem?
    let feedbackText: String?
    let onTapActiveItem: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if let feedbackText {
                Text(feedbackText)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.84))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.cyberCyan, lineWidth: 1.2)
                            )
                    )
                    .shadow(color: Color.cyberCyan.opacity(0.8), radius: 6)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            if battleBoostItem != nil || carryInItem != nil || medkitItem != nil {
                HStack(spacing: 7) {
                    if let carryIn = carryInItem {
                        if carryIn.isTapUsableInBattle {
                            Button(action: onTapActiveItem) {
                                BattleItemIconView(
                                    item: carryIn,
                                    size: 38,
                                    isInteractivePulse: true
                                )
                            }
                            .buttonStyle(.plain)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        } else {
                            BattleItemIconView(
                                item: carryIn,
                                size: 33,
                                isInteractivePulse: false
                            )
                            .allowsHitTesting(false)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                    }

                    if let boost = battleBoostItem {
                        BattleItemIconView(
                            item: boost,
                            size: 33,
                            isInteractivePulse: false
                        )
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }

                    if let medkit = medkitItem {
                        BattleItemIconView(
                            item: medkit,
                            size: 33,
                            isInteractivePulse: false
                        )
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: battleBoostItem)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: carryInItem)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: medkitItem)
        .animation(.easeInOut(duration: 0.20), value: feedbackText)
    }
}
