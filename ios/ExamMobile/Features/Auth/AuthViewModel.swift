import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published var submitting = false
    @Published var meta: AuthMeta?
    @Published var tenants: [TenantMembership] = []
    @Published var needsTenant = false
    @Published var toast: String?

    let session: Session
    let repository: CandidateRepository

    init(session: Session, repository: CandidateRepository) {
        self.session = session
        self.repository = repository
    }

    @MainActor
    func loadMeta() async {
        meta = try? await repository.meta()
    }

    @MainActor
    func login(_ username: String, _ password: String) async {
        guard !username.isEmpty, !password.isEmpty else { toast = "请输入账号和密码"; return }
        submitting = true
        defer { submitting = false }
        do {
            let resp = try await repository.login(username: username, password: password)
            guard let token = resp.token, let user = resp.user else { toast = "登录失败"; return }
            session.save(token: token, user: user)
            if resp.requiresTenantSelection == true && resp.tenantId == nil {
                tenants = resp.tenants ?? []
                needsTenant = true
            }
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "登录失败"
        }
    }

    @MainActor
    func smsLogin(phone: String, code: String) async {
        guard !phone.isEmpty, !code.isEmpty else { toast = "请输入手机号和验证码"; return }
        submitting = true
        defer { submitting = false }
        do {
            let resp = try await repository.smsLogin(phone: phone, code: code)
            guard let token = resp.token, let user = resp.user else { toast = "登录失败"; return }
            session.save(token: token, user: user)
            if resp.requiresTenantSelection == true && resp.tenantId == nil {
                tenants = resp.tenants ?? []
                needsTenant = true
            }
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "登录失败"
        }
    }

    @MainActor
    func sendOtp(phone: String, scene: String = "login") async {
        guard !phone.isEmpty else { toast = "请输入手机号"; return }
        do {
            _ = try await repository.sendOtp(phone: phone, scene: scene)
            toast = "验证码已发送"
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "发送失败"
        }
    }

    @MainActor
    func register(username: String, password: String, realName: String, phone: String) async {
        guard !username.isEmpty, !password.isEmpty else { toast = "请输入账号和密码"; return }
        submitting = true
        defer { submitting = false }
        do {
            let resp = try await repository.register(username: username, password: password, realName: realName, phone: phone)
            guard let token = resp.token, let user = resp.user else { toast = "注册失败"; return }
            session.save(token: token, user: user)
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "注册失败"
        }
    }

    @MainActor
    func resetPassword(phone: String, code: String, newPassword: String) async -> Bool {
        guard !phone.isEmpty, !code.isEmpty, !newPassword.isEmpty else { toast = "请完整填写"; return false }
        submitting = true
        defer { submitting = false }
        do {
            _ = try await repository.resetPassword(phone: phone, code: code, newPassword: newPassword)
            toast = "密码已重置，请登录"
            return true
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "重置失败"
            return false
        }
    }

    @MainActor
    func switchTenant(_ tenantId: String) async {
        submitting = true
        defer { submitting = false }
        do {
            let resp = try await repository.switchTenant(tenantId: tenantId)
            guard let token = resp.token, let user = resp.user else { toast = "切换失败"; return }
            session.save(token: token, user: user)
            needsTenant = false
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "切换失败"
        }
    }

    @MainActor
    func refreshMe() async {
        if let user = try? await repository.me() { session.updateUser(user) }
    }

    @MainActor
    func logout() {
        session.clear()
    }
}
