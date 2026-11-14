import Foundation

enum Formatters {
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func epochToDateTime(_ millis: String?) -> String {
        guard let ms = Double(millis ?? ""), ms > 0 else { return "" }
        return dateTimeFormatter.string(from: Date(timeIntervalSince1970: ms / 1000))
    }

    static func epochToDate(_ millis: String?) -> String {
        guard let ms = Double(millis ?? ""), ms > 0 else { return "" }
        return dateFormatter.string(from: Date(timeIntervalSince1970: ms / 1000))
    }

    static func countdown(_ remainingSeconds: Int) -> String {
        let total = max(remainingSeconds, 0)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%02d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    static func durationText(_ seconds: Int?) -> String {
        let s = seconds ?? 0
        if s <= 0 { return "不限时" }
        let m = s / 60
        return m >= 60 ? "\(m / 60)小时\(m % 60)分" : "\(m)分钟"
    }

    static func scoreText(_ value: Double?) -> String {
        guard let value = value else { return "-" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    static func questionTypeLabel(_ type: String?) -> String {
        switch (type ?? "").uppercased() {
        case "SINGLE": return "单选题"
        case "MULTIPLE": return "多选题"
        case "JUDGE": return "判断题"
        case "FILL": return "填空题"
        case "ESSAY": return "问答题"
        default: return type ?? ""
        }
    }

    static func attemptStatusLabel(_ status: String?) -> String {
        switch (status ?? "").uppercased() {
        case "ASSIGNED": return "待开始"
        case "STARTED", "IN_PROGRESS": return "进行中"
        case "SUBMITTED": return "已交卷"
        case "GRADING": return "阅卷中"
        case "GRADED": return "已出分"
        case "EXPIRED": return "已过期"
        case "ABSENT": return "缺考"
        default: return status ?? ""
        }
    }

    static func orderStatusLabel(_ status: String?) -> String {
        switch (status ?? "").uppercased() {
        case "UNPAID", "PENDING": return "待支付"
        case "PAID", "SUCCESS": return "已支付"
        case "CANCELLED", "CANCELED": return "已取消"
        case "REFUNDED": return "已退款"
        default: return status ?? ""
        }
    }

    static func greeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5...10: return "早上好"
        case 11...12: return "中午好"
        case 13...17: return "下午好"
        case 18...22: return "晚上好"
        default: return "你好"
        }
    }
}
