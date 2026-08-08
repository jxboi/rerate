import SwiftUI

/// Price and the underlying business, both rebased to 100 at purchase.
///
/// This is the single most important picture in the app. When the two lines sit
/// on top of each other, the gain was earned. When they separate, the gap is
/// what investors changed their mind about. Nothing else on the screen explains
/// re-rating as quickly as watching the space open up.
struct DivergenceChart: View {
    let points: [PricePoint]
    let anchorLabel: String
    var height: CGFloat = 132
    @State private var progress: CGFloat = 0
    @State private var highlight: Int?

    private var series: (price: [Double], anchor: [Double]) {
        guard let first = points.first, first.price > 0, first.anchor > 0 else { return ([], []) }
        return (
            points.map { $0.price / first.price * 100 },
            points.map { $0.anchor / first.anchor * 100 }
        )
    }

    private var bounds: (min: Double, max: Double) {
        let all = series.price + series.anchor
        guard let lo = all.min(), let hi = all.max() else { return (90, 110) }
        let pad = (hi - lo) * 0.12
        return (lo - pad, hi + pad)
    }

    private func path(_ values: [Double], in size: CGSize) -> Path {
        var p = Path()
        guard values.count > 1 else { return p }
        let (lo, hi) = bounds
        let span = max(hi - lo, 0.0001)
        for (i, v) in values.enumerated() {
            let x = size.width * CGFloat(i) / CGFloat(values.count - 1)
            let y = size.height * (1 - CGFloat((v - lo) / span))
            i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }

    /// The shaded wedge between the two lines is literally the re-rating.
    private func gap(in size: CGSize) -> Path {
        let s = series
        guard s.price.count > 1 else { return Path() }
        var p = path(s.price, in: size)
        let anchorPath = path(s.anchor, in: size)
        p.addPath(anchorPath.reversedSubpath())
        p.closeSubpath()
        return p
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                let size = geo.size
                ZStack(alignment: .topLeading) {
                    gap(in: size)
                        .fill(
                            LinearGradient(
                                colors: [Palette.caution.opacity(0.26), Palette.caution.opacity(0.07)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .opacity(progress > 0.95 ? 1 : 0)
                        .animation(Motion.gentle, value: progress)

                    path(series.anchor, in: size)
                        .trim(from: 0, to: progress)
                        .stroke(
                            Palette.inkTertiary,
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [3, 4])
                        )

                    path(series.price, in: size)
                        .trim(from: 0, to: progress)
                        .stroke(Palette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: height)
            .onAppear {
                withAnimation(Motion.draw.delay(0.15)) { progress = 1 }
            }

            HStack(spacing: 16) {
                legend(color: Palette.ink, dashed: false, label: "Price")
                legend(color: Palette.inkTertiary, dashed: true, label: anchorLabel)
                Spacer()
                Text("Rebased to purchase")
                    .font(Type.micro)
                    .foregroundStyle(Palette.inkQuaternary)
            }
        }
    }

    private func legend(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .strokeBorder(color, style: StrokeStyle(lineWidth: 2, dash: dashed ? [2, 2.5] : []))
                .frame(width: 14, height: 2)
            Text(label)
                .font(Type.micro)
                .foregroundStyle(Palette.inkSecondary)
        }
    }
}

extension Path {
    /// Reverses a path so two line paths can be joined into a closed band.
    func reversedSubpath() -> Path {
        var points: [CGPoint] = []
        forEach { element in
            switch element {
            case .move(let p): points.append(p)
            case .line(let p): points.append(p)
            case .quadCurve(let p, _): points.append(p)
            case .curve(let p, _, _): points.append(p)
            case .closeSubpath: break
            }
        }
        var p = Path()
        guard let last = points.last else { return p }
        p.move(to: last)
        for point in points.dropLast().reversed() {
            p.addLine(to: point)
        }
        return p
    }
}
