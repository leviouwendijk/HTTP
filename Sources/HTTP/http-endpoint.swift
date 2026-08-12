public struct HTTPEndpoint: Sendable, Hashable {
    public let method: HTTPMethod
    public let path: String

    public init(
        method: HTTPMethod,
        path: String
    ) {
        self.method = method
        self.path = path
    }

    public init(
        method: HTTPMethod,
        components: [String]
    ) {
        self.init(
            method: method,
            path: Self.path(
                components
            )
        )
    }

    public init(
        method: HTTPMethod,
        _ components: String...
    ) {
        self.init(
            method: method,
            components: components
        )
    }

    private static func path(
        _ components: [String]
    ) -> String {
        components.isEmpty
            ? "/"
            : "/" + components.joined(
                separator: "/"
            )
    }
}
