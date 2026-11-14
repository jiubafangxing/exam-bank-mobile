import Foundation
import Combine

/// 会话状态（ObservableObject）。令牌与用户信息存 Keychain。
final class Session: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var loggedIn: Bool

    init() {
        self.user = TokenStore.readUser()
        self.loggedIn = TokenStore.readToken() != nil
    }

    func save(token: String, user: User) {
        TokenStore.saveToken(token)
        TokenStore.saveUser(user)
        self.user = user
        self.loggedIn = true
    }

    func updateUser(_ user: User) {
        TokenStore.saveUser(user)
        self.user = user
    }

    func clear() {
        TokenStore.clear()
        self.user = nil
        self.loggedIn = false
    }
}
