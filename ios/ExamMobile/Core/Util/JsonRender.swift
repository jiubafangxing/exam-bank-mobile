import Foundation

/// 未知结构响应的通用可读化渲染。
func flattenJSON(_ value: Any, prefix: String = "") -> [(String, String)] {
    var out: [(String, String)] = []
    if let dict = value as? [String: Any] {
        for key in dict.keys.sorted() {
            let child = dict[key]!
            let path = prefix.isEmpty ? key : "\(prefix).\(key)"
            if child is [String: Any] || child is [Any] {
                out += flattenJSON(child, prefix: path)
            } else {
                out.append((path, stringValue(child)))
            }
        }
    } else if let array = value as? [Any] {
        for (index, child) in array.enumerated() {
            let path = "\(prefix)[\(index)]"
            if child is [String: Any] || child is [Any] {
                out += flattenJSON(child, prefix: path)
            } else {
                out.append((path, stringValue(child)))
            }
        }
    } else {
        out.append((prefix.isEmpty ? "内容" : prefix, stringValue(value)))
    }
    return out
}

private func stringValue(_ value: Any) -> String {
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return "\(value)"
}
