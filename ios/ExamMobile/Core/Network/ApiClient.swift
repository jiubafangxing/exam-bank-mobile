import Foundation

/// 统一网络客户端：baseUrl + Bearer + X-Client-Type + 信封解包 + 401 处理。
final class ApiClient {
    private let session: URLSession
    private let tokenProvider: () -> String?
    private let onUnauthorized: () -> Void
    private let decoder = JSONDecoder()

    init(tokenProvider: @escaping () -> String?, onUnauthorized: @escaping () -> Void) {
        self.tokenProvider = tokenProvider
        self.onUnauthorized = onUnauthorized
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.connectTimeout
        config.timeoutIntervalForResource = AppConfig.readTimeout
        self.session = URLSession(configuration: config)
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        try decode(try await execute(method: "GET", path: path, query: query))
    }

    func post<T: Decodable>(_ path: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> T {
        try decode(try await execute(method: "POST", path: path, body: body, headers: headers))
    }

    func put<T: Decodable>(_ path: String, body: Data? = nil) async throws -> T {
        try decode(try await execute(method: "PUT", path: path, body: body))
    }

    func delete<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        try decode(try await execute(method: "DELETE", path: path, query: query))
    }

    func getRaw(_ path: String, query: [String: String] = [:]) async throws -> Any {
        let data = try await execute(method: "GET", path: path, query: query)
        return (try? JSONSerialization.jsonObject(with: data)) ?? NSNull()
    }

    @discardableResult
    func postEmpty(_ path: String, body: Data? = nil) async throws -> Any {
        let data = try await execute(method: "POST", path: path, body: body)
        return (try? JSONSerialization.jsonObject(with: data)) ?? NSNull()
    }

    func upload<T: Decodable>(_ path: String, field: String = "file", filename: String, data: Data, mime: String) async throws -> T {
        guard !AppConfig.apiBaseURL.isEmpty else { throw ApiError.notConfigured }
        guard let url = URL(string: AppConfig.apiBaseURL + path) else { throw ApiError.network("服务地址配置无效") }
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfig.clientType, forHTTPHeaderField: "X-Client-Type")
        if let token = tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw ApiError.network("网络异常，请检查网络后重试")
        }
        guard let http = response as? HTTPURLResponse else { throw ApiError.network("响应异常") }
        if http.statusCode == 401 {
            onUnauthorized()
            throw ApiError.http(401, "登录已过期，请重新登录")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ApiError.http(http.statusCode, "上传失败(\(http.statusCode))")
        }
        return try decode(try unwrap(responseData))
    }

    // MARK: - 内部

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ApiError.parse
        }
    }

    private func execute(
        method: String,
        path: String,
        query: [String: String] = [:],
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> Data {
        guard !AppConfig.apiBaseURL.isEmpty else { throw ApiError.notConfigured }
        guard var components = URLComponents(string: AppConfig.apiBaseURL + path) else {
            throw ApiError.network("服务地址配置无效")
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw ApiError.network("服务地址配置无效") }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfig.clientType, forHTTPHeaderField: "X-Client-Type")
        if let token = tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let body = body {
            request.httpBody = body
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ApiError.network("网络异常，请检查网络后重试")
        }

        guard let http = response as? HTTPURLResponse else { throw ApiError.network("响应异常") }
        if http.statusCode == 401 {
            onUnauthorized()
            throw ApiError.http(401, "登录已过期，请重新登录")
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { ($0["message"] as? String) ?? ($0["msg"] as? String) } ?? "请求失败(\(http.statusCode))"
            throw ApiError.http(http.statusCode, msg)
        }
        return try unwrap(data)
    }

    private func unwrap(_ data: Data) throws -> Data {
        if data.isEmpty { return Data("null".utf8) }
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return data }
        if let dict = obj as? [String: Any], let code = dict["code"] as? Int {
            if code != 0 {
                throw ApiError.business(code, (dict["message"] as? String) ?? "请求失败")
            }
            let payload = dict["data"] ?? NSNull()
            return (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("null".utf8)
        }
        return data
    }
}

struct EmptyResponse: Codable {}

/// 便捷：JSONEncoder 编码请求体
enum Body {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
}
