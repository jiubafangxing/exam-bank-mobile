import SwiftUI

struct SectionCard<Content: View>: View {
    var padding: CGFloat = Tokens.pagePadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

struct ListRow: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var showArrow: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15)).foregroundColor(Tokens.textPrimary)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 13)).foregroundColor(Tokens.textSecondary).lineLimit(1)
                    }
                }
                Spacer()
                if let trailing = trailing {
                    Text(trailing).font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                }
                if showArrow {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Tokens.textTertiary)
                }
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

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

struct PrimaryButton: View {
    let title: String
    var loading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                Text(title).font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundColor(.white)
            .background((enabled && !loading) ? Tokens.primary : Tokens.primary.opacity(0.4))
            .clipShape(Capsule())
        }
        .disabled(!enabled || loading)
    }
}

struct SecondaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(enabled ? Tokens.primary : Tokens.textTertiary)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .overlay(Capsule().stroke(enabled ? Tokens.primary : Tokens.borderStrong, lineWidth: 1))
        }
        .disabled(!enabled)
    }
}

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
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CountdownText: View {
    let remaining: Int
    var body: some View {
        Text(Formatters.countdown(remaining))
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .foregroundColor(remaining <= 300 ? Tokens.danger : Tokens.primary)
    }
}

struct KeyValueRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 13)).foregroundColor(Tokens.textSecondary).frame(width: 84, alignment: .leading)
            Text(value).font(.system(size: 13)).foregroundColor(Tokens.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle().fill(Tokens.border).frame(height: 1)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Tokens.textPrimary)
            .padding(.top, 18)
            .padding(.bottom, 8)
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
