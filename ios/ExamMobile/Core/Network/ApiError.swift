import Foundation

enum ApiError: LocalizedError {
    case notConfigured
    case business(Int, String)
    case http(Int, String)
    case network(String)
    case parse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "服务地址未配置"
        case .business(_, let m): return m
        case .http(let s, let m): return m.isEmpty ? "请求失败(\(s))" : m
        case .network(let m): return m
        case .parse: return "数据解析失败"
        }
    }

    var isUnauthorized: Bool {
        if case .http(401, _) = self { return true }
        return false
    }
}
