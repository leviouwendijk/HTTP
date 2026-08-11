public struct HTTPResponsePolicies: Sendable, Hashable, Equatable {
    public let headers: HTTPHeaderPolicy
    public let content: HTTPContentLengthPolicy

    public init(
        headers: HTTPHeaderPolicy,
        content: HTTPContentLengthPolicy
    ) {
        self.headers = headers
        self.content = content
    }
}
