import SwiftUI

final class RemoteLoader<Value>: ObservableObject {
    @Published var state: UiState<Value> = .idle
    private let loader: () async throws -> Value

    init(loader: @escaping () async throws -> Value) {
        self.loader = loader
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            state = .success(try await loader())
        } catch {
            state = .failure((error as? ApiError)?.errorDescription ?? error.localizedDescription)
        }
    }
}

/// 通用远程内容容器：加载/错误/空态/内容。
struct RemoteContent<Value, Content: View>: View {
    @StateObject private var loader: RemoteLoader<Value>
    private let emptyCheck: (Value) -> Bool
    private let emptyText: String
    private let content: (Value) -> Content

    init(
        loader: @escaping () async throws -> Value,
        emptyCheck: @escaping (Value) -> Bool = { _ in false },
        emptyText: String = "暂无数据",
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        _loader = StateObject(wrappedValue: RemoteLoader(loader: loader))
        self.emptyCheck = emptyCheck
        self.emptyText = emptyText
        self.content = content
    }

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                LoadingView()
            case .failure(let message):
                VStack(spacing: 12) {
                    ErrorBanner(message: message)
                    SecondaryButton(title: "重试") { Task { await loader.load() } }
                }
                .padding(Tokens.pagePadding)
            case .success(let value):
                if emptyCheck(value) {
                    EmptyStateView(text: emptyText)
                } else {
                    content(value)
                }
            }
        }
        .task {
            if case .idle = loader.state { await loader.load() }
        }
    }
}
