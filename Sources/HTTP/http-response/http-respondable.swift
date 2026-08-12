public protocol HTTPRespondable: Sendable {
    func response(
        status: HTTPStatus
    ) throws -> HTTPResponse
}

public extension HTTPRespondable {
    func response() throws -> HTTPResponse {
        try response(
            status: .ok
        )
    }
}

public extension HTTPRespondable where Self: Encodable {
    func response(
        status: HTTPStatus
    ) throws -> HTTPResponse {
        try HTTPResponse.json(
            self,
            status: status
        )
    }
}
