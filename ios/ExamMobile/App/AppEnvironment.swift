import Foundation

final class AppEnvironment: ObservableObject {
    let session: Session
    let repository: CandidateRepository

    init() {
        let session = Session()
        self.session = session
        let client = ApiClient(
            tokenProvider: { TokenStore.readToken() },
            onUnauthorized: {
                DispatchQueue.main.async {
                    session.clear()
                }
            }
        )
        self.repository = CandidateRepository(client: client)
    }
}
