import Path

public struct Endpoint<Input, Output>: Sendable, Hashable {
    public let transport: HTTPEndpoint

    public var method: HTTPMethod {
        transport.method
    }

    public var path: String {
        transport.path
    }

    public init(
        _ transport: HTTPEndpoint
    ) {
        self.transport = transport
    }

    public init(
        method: HTTPMethod,
        path: String
    ) {
        self.init(
            HTTPEndpoint(
                method: method,
                path: path
            )
        )
    }

    public init(
        method: HTTPMethod,
        path: StandardPath
    ) {
        self.init(
            HTTPEndpoint(
                method: method,
                path: path
            )
        )
    }

    public init(
        method: HTTPMethod,
        components: [String]
    ) {
        self.init(
            HTTPEndpoint(
                method: method,
                components: components
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
