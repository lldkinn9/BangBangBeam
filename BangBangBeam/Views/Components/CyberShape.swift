import SwiftUI

/// サイバーパンク風の斜めポリゴンカットアウト形状（左上・右下カット）
struct CyberShape: InsettableShape, Sendable {
    let cutSize: CGFloat
    let insetAmount: CGFloat

    init(cutSize: CGFloat = 14, insetAmount: CGFloat = 0) {
        self.cutSize = cutSize
        self.insetAmount = insetAmount
    }

    nonisolated func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard r.width > 0, r.height > 0 else { return Path() }

        let cut = min(cutSize, min(r.width, r.height) * 0.35)
        var path = Path()

        path.move(to: CGPoint(x: r.minX + cut, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cut))
        path.addLine(to: CGPoint(x: r.maxX - cut, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + cut))
        path.closeSubpath()

        return path
    }

    nonisolated func inset(by amount: CGFloat) -> CyberShape {
        CyberShape(cutSize: cutSize, insetAmount: insetAmount + amount)
    }
}
