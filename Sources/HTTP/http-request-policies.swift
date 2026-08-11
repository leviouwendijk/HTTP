public struct HTTPRequestPolicies: Sendable, Hashable, Equatable {
    public let headers: HTTPHeaderPolicy
    public let content: HTTPContentLengthPolicy
    public let target: HTTPRequestTargetPolicy

    public init(
        headers: HTTPHeaderPolicy,
        content: HTTPContentLengthPolicy,
        target: HTTPRequestTargetPolicy
    ) {
        self.headers = headers
        self.content = content
        self.target = target
    }
}
