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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
            Group {
                if secure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text).keyboardType(keyboard).autocapitalization(.none)
                }
            }
            .padding(12)
            .background(Tokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Tokens.border, lineWidth: 1))
        }
    }
}

private struct AuthHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 26, weight: .bold)).foregroundColor(Tokens.textPrimary)
            Text(subtitle).font(.system(size: 14)).foregroundColor(Tokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 48)
        .padding(.bottom, 24)
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
            VStack(spacing: 12) {
                AuthHeader(title: "在线考试", subtitle: "登录后参加考试、练习与学习")
                AuthField(title: "账号", text: $username)
                AuthField(title: "密码", text: $password, secure: true)
                PrimaryButton(title: "登录", loading: vm.submitting) {
                    Task { await vm.login(username, password) }
                }
                .padding(.top, 8)

                HStack {
                    if vm.meta?.smsEnabled == true {
                        NavigationLink("短信登录", value: AuthRoute.sms).font(.system(size: 13))
                    }
                    Spacer()
                    NavigationLink("注册账号", value: AuthRoute.register).font(.system(size: 13))
                    Spacer()
                    NavigationLink("忘记密码", value: AuthRoute.reset).font(.system(size: 13))
                }
                .foregroundColor(Tokens.primary)
                .padding(.top, 4)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
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
            VStack(spacing: 12) {
                AuthHeader(title: "短信登录", subtitle: "输入手机号与验证码")
                AuthField(title: "手机号", text: $phone, keyboard: .phonePad)
                HStack(spacing: 12) {
                    AuthField(title: "验证码", text: $code, keyboard: .numberPad)
                    SecondaryButton(title: "发送验证码") {
                        Task { await vm.sendOtp(phone: phone) }
                    }
                }
                PrimaryButton(title: "登录", loading: vm.submitting) {
                    Task { await vm.smsLogin(phone: phone, code: code) }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
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
            VStack(spacing: 12) {
                AuthHeader(title: "创建账号", subtitle: "注册后即可参加考试")
                AuthField(title: "账号", text: $username)
                AuthField(title: "密码", text: $password, secure: true)
                AuthField(title: "姓名", text: $realName)
                AuthField(title: "手机号", text: $phone, keyboard: .phonePad)
                PrimaryButton(title: "注册", loading: vm.submitting) {
                    Task { await vm.register(username: username, password: password, realName: realName, phone: phone) }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
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
            VStack(spacing: 12) {
                AuthHeader(title: "重置密码", subtitle: "通过手机号验证后设置新密码")
                AuthField(title: "手机号", text: $phone, keyboard: .phonePad)
                HStack(spacing: 12) {
                    AuthField(title: "验证码", text: $code, keyboard: .numberPad)
                    SecondaryButton(title: "发送验证码") {
                        Task { await vm.sendOtp(phone: phone, scene: "reset") }
                    }
                }
                AuthField(title: "新密码", text: $password, secure: true)
                PrimaryButton(title: "确认重置", loading: vm.submitting) {
                    Task {
                        if await vm.resetPassword(phone: phone, code: code, newPassword: password) { dismiss() }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
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
                VStack(spacing: 10) {
                    Text("当前账号属于多个机构，请选择要进入的机构")
                        .font(.system(size: 14))
                        .foregroundColor(Tokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    ForEach(tenants) { tenant in
                        SectionCard {
                            Button {
                                Task {
                                    await vm.switchTenant(tenant.tenantId ?? "")
                                    onDone()
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tenant.tenantName ?? "机构").font(.system(size: 16, weight: .semibold)).foregroundColor(Tokens.textPrimary)
                                    Text(tenant.tenantCode ?? "").font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if vm.submitting { ProgressView().padding() }
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
