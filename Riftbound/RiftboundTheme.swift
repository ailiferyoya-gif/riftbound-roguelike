import SwiftUI

enum RiftboundTheme {
    static let background = Color(red: 0.035, green: 0.045, blue: 0.075)
    static let panel = Color(red: 0.08, green: 0.095, blue: 0.145)
    static let panelRaised = Color(red: 0.115, green: 0.125, blue: 0.19)
    static let text = Color(red: 0.95, green: 0.95, blue: 0.98)
    static let muted = Color(red: 0.58, green: 0.61, blue: 0.7)
    static let ember = Color(red: 1.0, green: 0.42, blue: 0.3)
    static let crimson = Color(red: 0.92, green: 0.18, blue: 0.36)
    static let lilac = Color(red: 0.65, green: 0.5, blue: 1.0)
    static let mint = Color(red: 0.34, green: 0.88, blue: 0.76)
    static let gold = Color(red: 1.0, green: 0.76, blue: 0.3)
    static let blue = Color(red: 0.3, green: 0.65, blue: 1.0)
    static let cyan = Color(red: 0.31, green: 0.85, blue: 1.0)
}

struct RiftCutCornerShape: Shape {
    var cut: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let c = min(cut, min(rect.width, rect.height) / 3)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + c, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + c))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: rect.maxX - c, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + c, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - c))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + c))
        path.closeSubpath()
        return path
    }
}

struct RiftboundBackground: View {
    var body: some View {
        ZStack {
            RiftboundTheme.background
            Image("rift-ui-frame")
                .resizable()
                .scaledToFill()
                .opacity(0.3)
                .blendMode(.screen)
                .padding(8)
            Circle()
                .fill(RiftboundTheme.lilac.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 55)
                .offset(x: 150, y: -300)
            Circle()
                .fill(RiftboundTheme.ember.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: -170, y: 280)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RiftCutCornerShape(cut: 12)
                    .fill(RiftboundTheme.panel.opacity(0.92))
                    .overlay(
                        RiftCutCornerShape(cut: 12)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
    }
}

struct RiftSignalView: View {
    let caption: String

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .stroke(RiftboundTheme.mint.opacity(0.6), lineWidth: 1)
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(RiftboundTheme.lilac.opacity(0.25), lineWidth: 1)
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(RiftboundTheme.mint)
                    .frame(width: 7, height: 7)
                    .shadow(color: RiftboundTheme.mint, radius: 7)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("RIFT SIGNAL")
                    .font(.caption2.weight(.black).monospaced())
                    .tracking(1.2)
                Text(caption)
                    .font(.caption2.weight(.medium).monospaced())
                    .foregroundStyle(RiftboundTheme.muted)
            }
            Spacer()
            Text("LIVE")
                .font(.caption2.weight(.black).monospaced())
                .foregroundStyle(RiftboundTheme.mint)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [RiftboundTheme.mint.opacity(0.12), RiftboundTheme.lilac.opacity(0.07)],
                startPoint: .leading,
                endPoint: .trailing
            ), in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(RiftboundTheme.mint.opacity(0.2), lineWidth: 1))
    }
}

struct RiftTelemetryCard: View {
    let depth: Int

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("RIFT TELEMETRY")
                    .font(.caption2.weight(.black).monospaced())
                    .tracking(1.3)
                    .foregroundStyle(RiftboundTheme.mint)
                Text("次の一手を、記録にする。")
                    .font(.headline.weight(.black))
                Text("永続強化・習熟・遺物は、次のサイクルへ残る。")
                    .font(.caption)
                    .foregroundStyle(RiftboundTheme.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            ZStack {
                Circle()
                    .stroke(RiftboundTheme.mint.opacity(0.38), lineWidth: 1)
                    .frame(width: 68, height: 68)
                Circle()
                    .stroke(RiftboundTheme.mint.opacity(0.15), lineWidth: 1)
                    .frame(width: 49, height: 49)
                Circle()
                    .fill(RiftboundTheme.gold)
                    .frame(width: 5, height: 5)
                    .offset(x: 16, y: -12)
                VStack(spacing: 1) {
                    Text(String(format: "%02d", depth))
                        .font(.title3.weight(.black).monospaced())
                    Text("DEPTH")
                        .font(.system(size: 7, weight: .black, design: .monospaced))
                        .foregroundStyle(RiftboundTheme.muted)
                }
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [RiftboundTheme.mint.opacity(0.12), RiftboundTheme.lilac.opacity(0.08), RiftboundTheme.gold.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ), in: RoundedRectangle(cornerRadius: 21, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(RiftboundTheme.mint.opacity(0.2), lineWidth: 1))
    }
}

struct RunCommandlineView: View {
    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(RiftboundTheme.mint)
                .frame(width: 6, height: 6)
                .shadow(color: RiftboundTheme.mint, radius: 5)
            Text("VEIL LINK // ONLINE")
                .font(.caption2.weight(.black).monospaced())
                .foregroundStyle(RiftboundTheme.mint)
            Spacer()
            Text("予兆を読んで、1ターン先を奪う")
                .font(.caption2.weight(.medium))
                .foregroundStyle(RiftboundTheme.muted)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(RiftboundTheme.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(RiftboundTheme.mint)
                .frame(width: 2)
        }
    }
}

struct RiftResonanceView: View {
    @EnvironmentObject private var game: GameStore

    private var rank: String {
        if game.combo >= 7 { return "OVERCLOCK" }
        if game.combo >= 4 { return "RESONANCE" }
        return "CHARGE"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("RIFT RESONANCE")
                .font(.caption2.weight(.black).monospaced())
                .foregroundStyle(RiftboundTheme.muted)
            Text(rank)
                .font(.caption2.weight(.black).monospaced())
                .foregroundStyle(RiftboundTheme.gold)
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index < game.combo ? RiftboundTheme.mint : RiftboundTheme.panelRaised)
                        .frame(maxWidth: .infinity, minHeight: 5)
                }
            }
            Text("\(game.combo) / \(game.comboBest)")
                .font(.caption2.weight(.bold).monospaced())
                .foregroundStyle(RiftboundTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [RiftboundTheme.mint.opacity(0.1), RiftboundTheme.lilac.opacity(0.09)], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(RiftboundTheme.mint.opacity(0.22), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("リフト共鳴、コンボ\(game.combo)、ベスト\(game.comboBest)")
    }
}

struct CapsuleLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.3)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct StatBar: View {
    let value: Int
    let maxValue: Int
    let color: Color
    let icon: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(RiftboundTheme.muted)
                Spacer()
                Text("\(value) / \(maxValue)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(RiftboundTheme.text)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * max(0, min(1, CGFloat(value) / CGFloat(maxValue))))
                }
            }
            .frame(height: 6)
        }
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(isPrimary ? RiftboundTheme.background : tint)
                    .background(isPrimary ? tint : tint.opacity(0.12), in: RiftCutCornerShape(cut: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(RiftboundTheme.text)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(RiftboundTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }
            .padding(13)
            .background(
                RiftCutCornerShape(cut: 10)
                    .fill(isPrimary ? tint.opacity(0.18) : RiftboundTheme.panelRaised.opacity(0.72))
                    .overlay(
                        RiftCutCornerShape(cut: 10)
                            .stroke(isPrimary ? tint.opacity(0.42) : .white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
