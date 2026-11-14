import Foundation
import Security

/// 会话令牌与用户信息的 Keychain 存储。绝不持久化登录密码。
enum TokenStore {
    private static let service = "com.example.exammobile"
    private static let tokenAccount = "session_token"
    private static let userAccount = "session_user"
    private static let deviceKey = "exam_mobile_device_id"

    static func saveToken(_ token: String) {
        save(Data(token.utf8), account: tokenAccount)
    }

    static func readToken() -> String? {
        guard let data = read(tokenAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func saveUser(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        save(data, account: userAccount)
    }

    static func readUser() -> User? {
        guard let data = read(userAccount) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    static func clear() {
        delete(tokenAccount)
        delete(userAccount)
    }

    static func deviceId() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceKey), !existing.isEmpty { return existing }
        let generated = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        UserDefaults.standard.set(generated, forKey: deviceKey)
        return generated
    }

    // MARK: - Keychain primitives

    private static func save(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func read(_ account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
