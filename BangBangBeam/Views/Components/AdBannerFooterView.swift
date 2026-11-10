import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// GoogleMobileAds SDK 導入時に実バナー広告を描画する UIViewRepresentable
private struct GADBannerRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = AdManager.topViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = AdManager.topViewController()
        }
    }
}
#endif

/// 非プレイ画面（タイトル・メニュー・設定・ランキング等）の最下部に配置する共通バナー広告領域
struct AdBannerFooterView: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.cyberCyan.opacity(0.25))

            ZStack {
                Color.cyberBlack.opacity(0.94)

                #if canImport(GoogleMobileAds)
                GADBannerRepresentable(adUnitID: AdManager.shared.bannerAdUnitID)
                    .frame(width: 320, height: 50)
                #else
                HStack(spacing: 8) {
                    Text("AD")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.cyberCyan, in: RoundedRectangle(cornerRadius: 3))

                    Text(L10n("バナー広告枠 (GoogleMobileAds SDK 追加で配信)", "Banner Ad Slot (GoogleMobileAds SDK)"))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                #endif
            }
            .frame(height: 50)
        }
    }
}

/// GoogleMobileAds SDK 未リンク時に「動画広告を見て復活（リワード広告）」の動作を検証できる明示オーバーレイ
struct FallbackRewardedAdOverlayView: View {
    let onRewardComplete: () -> Void
    let onCancel: () -> Void

    @State private var remainingSeconds: Int = 3

    var body: some View {
        ZStack {
            Color.black.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                HStack {
                    Text("REWARDED VIDEO AD SLOT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.cyberAmber)

                    Spacer()

                    Button {
                        onCancel()
                    } label: {
                        Text(L10n("✕ 閉じる（復活しない）", "✕ Close (Do Not Revive)"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.cyberAmber)

                    Text(L10n("復活リワード動画広告 確認枠", "Rewarded Video Ad Preview"))
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(.white)

                    Text(
                        L10n(
                            "Xcode に GoogleMobileAds パッケージを追加すると\n実際の動画広告（RewardedAd）が再生されます。",
                            "Link the GoogleMobileAds Swift Package in Xcode\nto display live Rewarded Video Ads."
                        )
                    )
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    if remainingSeconds > 0 {
                        Text(L10n("視聴完了まであと \(remainingSeconds) 秒...", "Reward ready in \(remainingSeconds)s..."))
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyberCyan)
                            .padding(.top, 6)
                    } else {
                        Button {
                            onRewardComplete()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.heart.fill")
                                Text(L10n("報酬を獲得してバトルに復活する", "Claim Reward & Revive"))
                            }
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                            .background(Color.cyberAmber, in: Capsule())
                            .shadow(color: Color.cyberAmber.opacity(0.75), radius: 10)
                        }
                        .padding(.top, 6)
                    }
                }

                Spacer()
            }
        }
        .task {
            while remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1.0))
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                }
            }
        }
    }
}
