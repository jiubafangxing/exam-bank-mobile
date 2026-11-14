import Foundation

enum UiState<Value> {
    case idle
    case loading
    case success(Value)
    case failure(String)

    var value: Value? {
        if case .success(let v) = self { return v }
        return nil
    }
}
