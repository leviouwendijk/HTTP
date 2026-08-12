public protocol HTTPRequestable: Sendable {
    static func parse(
        _ request: HTTPRequest
    ) throws -> Self
}

public extension HTTPRequestable where Self: Decodable {
    static func parse(
        _ request: HTTPRequest
    ) throws -> Self {
        try request.decode(
            Self.self
        )
    }
}
