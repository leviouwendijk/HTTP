public struct HTTPRequestPolicies: Sendable, Hashable, Equatable {
    public let headers: HTTPHeaderPolicy
    public let content: HTTPContentPolicy
    public let target: HTTPRequestTargetPolicy

    public init(
        headers: HTTPHeaderPolicy,
        content: HTTPContentPolicy,
        target: HTTPRequestTargetPolicy
    ) {
        self.headers = headers
        self.content = content
        self.target = target
    }
}
