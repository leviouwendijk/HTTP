public struct HTTPResponsePolicies: Sendable, Hashable, Equatable {
    public let headers: HTTPHeaderPolicy
    public let content: HTTPContentPolicy

    public init(
        headers: HTTPHeaderPolicy,
        content: HTTPContentPolicy
    ) {
        self.headers = headers
        self.content = content
    }
}
