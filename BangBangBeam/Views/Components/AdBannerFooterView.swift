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

/// 非プレイ画面（タイトル・メニュー・設定・アイテム・ランキング）の最下部に配置する共通バナー広告領域
/// - GoogleMobileAds SDK リンク時は実バナー広告（DEBUG時はテスト広告、Release時は本番広告）を表示し、未リンク時はダミー枠を出さず非表示とする
struct AdBannerFooterView: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        VStack(spacing: 0) {
            Divider()
                .background(Color.cyberCyan.opacity(0.25))

            ZStack {
                Color.cyberBlack.opacity(0.94)

                GADBannerRepresentable(adUnitID: AdManager.shared.bannerAdUnitID)
                    .frame(width: 320, height: 50)
            }
            .frame(height: 50)
        }
        #else
        EmptyView()
        #endif
    }
}
