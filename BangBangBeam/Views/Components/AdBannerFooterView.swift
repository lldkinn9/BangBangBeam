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

                    Text("バナー広告枠 (GoogleMobileAds SDK 追加で配信)")
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

/// GoogleMobileAds SDK 未リンク時にリトライ広告の発火タイミングを検証できる明示確認オーバーレイ
struct FallbackInterstitialOverlayView: View {
    let onSkip: () -> Void
    @State private var canSkip: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("INTERSTITIAL AD SLOT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.cyberCyan)
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text(canSkip ? "✕ SKIP AD" : "SKIP IN 1s...")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(canSkip ? .black : Color.white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                canSkip ? Color.cyberEmerald : Color.white.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .disabled(!canSkip)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "rectangle.inset.filled.and.person.filled")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.cyberCyan)

                    Text("全画面広告表示タイミング確認枠")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)

                    Text("リトライ \(AdManager.shared.retryAdFrequency) 回ごとのインタースティシャル広告枠です。\nXcode に GoogleMobileAds パッケージを追加すると\n実際のスキップ可能広告が表示されます。")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.0))
            canSkip = true
        }
    }
}
