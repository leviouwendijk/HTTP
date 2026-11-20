import Path

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
        path: StandardPath
    ) {
        self.init(
            method: method,
            path: path.render(
                as: .root,
                filetype: true
            )
        )
    }

    public init(
        method: HTTPMethod,
        components: [String]
    ) {
        self.init(
            method: method,
            path: StandardPath(
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
}
