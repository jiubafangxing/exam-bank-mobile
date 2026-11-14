import SwiftUI

// MARK: - 卡片

struct SectionCard<Content: View>: View {
    var padding: CGFloat = Tokens.pagePadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
                    .stroke(Tokens.border.opacity(0.65), lineWidth: 1)
            )
            .cardShadow()
    }
}

/// 顶部渐变 Hero，带装饰光斑。
struct GradientHero<Content: View>: View {
    var gradient: LinearGradient = Tokens.heroGradient
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.13))
                .frame(width: 180, height: 180)
                .offset(x: 58, y: -62)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 108, height: 108)
                .offset(x: 24, y: 96)
            VStack(alignment: .leading, spacing: 0, content: content)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .heroShadow()
    }
}

/// 带柔和底色的图标块。
struct IconTile: View {
    let icon: String
    var tint: Color = Tokens.primary
    var bg: Color = Tokens.primarySoft
    var size: CGFloat = 44
    var iconSize: CGFloat = 22

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [bg, bg.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(tint)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 按钮

struct PrimaryButton: View {
    let title: String
    var loading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    private var active: Bool { enabled && !loading }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                active
                    ? AnyShapeStyle(Tokens.primaryGradient)
                    : AnyShapeStyle(Tokens.borderStrong)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: active ? Tokens.buttonShadowColor : Color.clear,
                radius: Tokens.buttonShadowRadius,
                x: 0,
                y: Tokens.buttonShadowY
            )
        }
        .disabled(!active)
    }
}

struct SecondaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(enabled ? Tokens.primary : Tokens.textTertiary)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(enabled ? Tokens.primarySoft : Tokens.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!enabled)
    }
}

struct SmallAction: View {
    let text: String
    var color: Color = Tokens.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? .white : Tokens.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? Tokens.primary : Tokens.surfaceAlt)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 列表行

struct ListRow: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var showArrow: Bool = true
    var icon: String? = nil
    var iconTint: Color = Tokens.primary
    var iconBg: Color = Tokens.primarySoft
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    IconTile(icon: icon, tint: iconTint, bg: iconBg, size: 34, iconSize: 16)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Tokens.textPrimary)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Tokens.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let trailing = trailing {
                    Text(trailing)
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.textSecondary)
                }
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Tokens.textTertiary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - 标签 / 标题

struct TagPill: View {
    let text: String
    var fg: Color = Tokens.primary
    var bg: Color = Tokens.primarySoft

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
}

/// 带左侧渐变强调条的分区标题，右侧可放「查看更多」。
struct SectionHeader: View {
    let title: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Tokens.primary, Tokens.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 18)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Tokens.textPrimary)
            Spacer(minLength: 8)
            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionLabel)
                            .font(.system(size: 12))
                            .foregroundColor(Tokens.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Tokens.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        SectionHeader(title: text)
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var tint: Color = Tokens.primary
    var bg: Color = Tokens.primarySoft

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Tokens.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            LinearGradient(
                colors: [bg, bg.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - 状态

struct EmptyStateView: View {
    var text: String = "暂无数据"

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Tokens.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
    }
}

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .tint(Tokens.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(Tokens.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Tokens.dangerSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Tokens.danger.opacity(0.15), lineWidth: 1)
            )
    }
}

struct CountdownText: View {
    let remaining: Int

    var body: some View {
        Text(Formatters.countdown(remaining))
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .foregroundColor(remaining <= 300 ? Tokens.danger : Tokens.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(remaining <= 300 ? Tokens.dangerSoft : Tokens.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct KeyValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Tokens.textSecondary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Tokens.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Tokens.border.opacity(0.7))
            .frame(height: 1)
    }
}

extension View {
    func pageBackground() -> some View {
        self.background(Tokens.background.ignoresSafeArea())
    }
}

/// 轻提示（顶部浮层，自动消失）
private struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message = message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.78))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        self.message = nil
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
