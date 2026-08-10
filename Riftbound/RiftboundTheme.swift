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
}

struct RiftboundBackground: View {
    var body: some View {
        ZStack {
            RiftboundTheme.background
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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(RiftboundTheme.panel.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
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
                    .background(isPrimary ? tint : tint.opacity(0.12), in: Circle())
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPrimary ? tint.opacity(0.18) : RiftboundTheme.panelRaised.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isPrimary ? tint.opacity(0.42) : .white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
