import Foundation
import SwiftUI

enum AuthRoute: Hashable {
    case sms
    case register
    case reset
}

struct AuthFlowView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        NavigationStack {
            LoginView(session: env.session, repository: env.repository)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .sms: SmsLoginView(session: env.session, repository: env.repository)
                    case .register: RegisterView(session: env.session, repository: env.repository)
                    case .reset: ResetPasswordView(session: env.session, repository: env.repository)
                    }
                }
        }
    }
}

struct AuthField: View {
    let title: String
    @Binding var text: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Tokens.textSecondary)
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Tokens.textTertiary)
                        .frame(width: 18)
                }
                Group {
                    if secure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboard)
                            .autocapitalization(.none)
                    }
                }
                .font(.system(size: 15))
            }
            .padding(12)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Tokens.border, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AuthHero: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        GradientHero {
            IconTile(
                icon: icon,
                tint: .white,
                bg: Color.white.opacity(0.20),
                size: 46,
                iconSize: 23
            )
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 14)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.88))
                .padding(.top, 5)
        }
    }
}

struct LoginView: View {
    @StateObject private var vm: AuthViewModel
    @State private var username = ""
    @State private var password = ""

    init(session: Session, repository: CandidateRepository) {
        _vm = StateObject(wrappedValue: AuthViewModel(session: session, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GradientHero {
                    IconTile(
                        icon: "lock.fill",
                        tint: .white,
                        bg: Color.white.opacity(0.20),
                        size: 50,
                        iconSize: 25
                    )
                    Text("在线考试")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    Text("登录后参加考试、练习与学习")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.88))
                        .padding(.top, 5)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                SectionCard(padding: 20) {
                    Text("账号登录")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Tokens.textPrimary)
                    AuthField(title: "账号", text: $username, icon: "person.crop.circle")
                        .padding(.top, 14)
                    AuthField(title: "密码", text: $password, secure: true, icon: "lock")
                        .padding(.top, 12)
                    PrimaryButton(title: "登录", loading: vm.submitting) {
                        Task { await vm.login(username, password) }
                    }
                    .padding(.top, 20)

                    HStack {
                        if vm.meta?.smsEnabled == true {
                            NavigationLink("短信登录", value: AuthRoute.sms)
                        } else {
                            Text("").hidden()
                        }
                        Spacer()
                        NavigationLink("注册账号", value: AuthRoute.register)
                        Spacer()
                        NavigationLink("忘记密码", value: AuthRoute.reset)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Tokens.primary)
                    .padding(.top, 14)
                }
                .padding(.horizontal, 20)
                .padding(.top, -28)

                Spacer(minLength: 24)
            }
        }
        .pageBackground()
        .navigationBarHidden(true)
        .toast($vm.toast)
        .sheet(isPresented: $vm.needsTenant) {
            TenantView(session: vm.session, repository: vm.repository, tenants: vm.tenants) {
                vm.needsTenant = false
            }
        }
        .task { await vm.loadMeta() }
    }
}

struct SmsLoginView: View {
    @StateObject private var vm: AuthViewModel
    @State private var phone = ""
    @State private var code = ""

    init(session: Session, repository: CandidateRepository) {
        _vm = StateObject(wrappedValue: AuthViewModel(session: session, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHero(
                    title: "短信登录",
                    subtitle: "输入手机号与验证码，快速进入学习",
                    icon: "phone.fill"
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)

                SectionCard {
                    AuthField(title: "手机号", text: $phone, keyboard: .phonePad, icon: "phone")
                    HStack(alignment: .bottom, spacing: 10) {
                        AuthField(title: "验证码", text: $code, keyboard: .numberPad, icon: "message")
                        SecondaryButton(title: "发送验证码") {
                            Task { await vm.sendOtp(phone: phone) }
                        }
                    }
                    .padding(.top, 12)
                    PrimaryButton(title: "登录", loading: vm.submitting) {
                        Task { await vm.smsLogin(phone: phone, code: code) }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, -24)
            }
        }
        .pageBackground()
        .navigationTitle("短信登录")
        .navigationBarTitleDisplayMode(.inline)
        .toast($vm.toast)
    }
}

struct RegisterView: View {
    @StateObject private var vm: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var realName = ""
    @State private var phone = ""

    init(session: Session, repository: CandidateRepository) {
        _vm = StateObject(wrappedValue: AuthViewModel(session: session, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHero(
                    title: "创建账号",
                    subtitle: "注册后即可参加考试与在线练习",
                    icon: "person.badge.plus"
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)

                SectionCard {
                    AuthField(title: "账号", text: $username, icon: "person.crop.circle")
                    AuthField(title: "密码", text: $password, secure: true, icon: "lock")
                        .padding(.top, 12)
                    AuthField(title: "姓名", text: $realName, icon: "person")
                        .padding(.top, 12)
                    AuthField(title: "手机号", text: $phone, keyboard: .phonePad, icon: "phone")
                        .padding(.top, 12)
                    PrimaryButton(title: "注册", loading: vm.submitting) {
                        Task { await vm.register(username: username, password: password, realName: realName, phone: phone) }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, -24)
            }
        }
        .pageBackground()
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
        .toast($vm.toast)
    }
}

struct ResetPasswordView: View {
    @StateObject private var vm: AuthViewModel
    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @Environment(\.dismiss) private var dismiss

    init(session: Session, repository: CandidateRepository) {
        _vm = StateObject(wrappedValue: AuthViewModel(session: session, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHero(
                    title: "重置密码",
                    subtitle: "通过手机号验证后设置新密码",
                    icon: "lock.rotation"
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)

                SectionCard {
                    AuthField(title: "手机号", text: $phone, keyboard: .phonePad, icon: "phone")
                    HStack(alignment: .bottom, spacing: 10) {
                        AuthField(title: "验证码", text: $code, keyboard: .numberPad, icon: "message")
                        SecondaryButton(title: "发送验证码") {
                            Task { await vm.sendOtp(phone: phone, scene: "reset") }
                        }
                    }
                    .padding(.top, 12)
                    AuthField(title: "新密码", text: $password, secure: true, icon: "lock")
                        .padding(.top, 12)
                    PrimaryButton(title: "确认重置", loading: vm.submitting) {
                        Task {
                            if await vm.resetPassword(phone: phone, code: code, newPassword: password) {
                                dismiss()
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, -24)
            }
        }
        .pageBackground()
        .navigationTitle("重置密码")
        .navigationBarTitleDisplayMode(.inline)
        .toast($vm.toast)
    }
}

struct TenantView: View {
    let session: Session
    let repository: CandidateRepository
    let tenants: [TenantMembership]
    var onDone: () -> Void

    @StateObject private var vm: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    init(session: Session, repository: CandidateRepository, tenants: [TenantMembership], onDone: @escaping () -> Void) {
        self.session = session
        self.repository = repository
        self.tenants = tenants
        self.onDone = onDone
        _vm = StateObject(wrappedValue: AuthViewModel(session: session, repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GradientHero {
                        Text("选择机构")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.white)
                        Text("当前账号属于多个机构，请选择要进入的机构")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.88))
                            .padding(.top, 5)
                    }

                    if tenants.isEmpty {
                        SectionCard {
                            Text("当前账号尚未加入任何机构，请联系机构管理员邀请。")
                                .font(.system(size: 13))
                                .foregroundColor(Tokens.textSecondary)
                                .lineSpacing(5)
                        }
                    }

                    ForEach(tenants) { tenant in
                        SectionCard {
                            Button {
                                Task {
                                    await vm.switchTenant(tenant.tenantId ?? "")
                                    onDone()
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    IconTile(icon: "building.2.fill", tint: Tokens.primary, bg: Tokens.primarySoft)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(tenant.tenantName ?? "机构")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Tokens.textPrimary)
                                        Text(tenant.tenantCode ?? "")
                                            .font(.system(size: 12))
                                            .foregroundColor(Tokens.textSecondary)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Tokens.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if vm.submitting {
                        ProgressView()
                            .tint(Tokens.primary)
                            .padding()
                    }
                }
                .padding(16)
            }
            .pageBackground()
            .navigationTitle("选择机构")
            .navigationBarTitleDisplayMode(.inline)
            .toast($vm.toast)
        }
    }
}
