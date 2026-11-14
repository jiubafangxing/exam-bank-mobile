import Foundation

/// 构建期注入的运行配置。域名经 Configs/Secrets.xcconfig 写入 Info.plist，不硬编码于源码。
enum AppConfig {
    static let apiBaseURL: String = {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, !raw.contains("$("), !raw.contains("your-host") else { return "" }
        return raw.hasSuffix("/") ? String(raw.dropLast()) : raw
    }()

    static let clientType = "IOS"
    static let registrationUrl: String = (Bundle.main.object(forInfoDictionaryKey: "REGISTRATION_URL") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    static let connectTimeout: TimeInterval = 20
    static let readTimeout: TimeInterval = 30

    // 作答状态机参数（与三端一致）
    static let debounceSaveMs: UInt64 = 500
    static let heartbeatSeconds: UInt64 = 30
    static let eventThrottleMs: Int = 1000

    static var isConfigured: Bool { !apiBaseURL.isEmpty }
}
