import Foundation

public struct HTTPResponse: Sendable {
    public let status: HTTPStatus
    public var headers: HTTPHeaders
    public var body: String

    /// Structured operational metadata. This is not serialized to the client.
    public var failure: HTTPFailure?

    public init(
        status: HTTPStatus,
        headers: [String: String] = [:],
        body: String = "",
        failure: HTTPFailure? = nil
    ) {
        self.init(
            status: status,
            headers: HTTPHeaders(headers),
            body: body,
            failure: failure
        )
    }

    public init(
        status: HTTPStatus,
        headers: HTTPHeaders,
        body: String = "",
        failure: HTTPFailure? = nil
    ) {
        self.status = status
        self.headers = headers
        self.body = body
        self.failure = failure
    }
}

public extension HTTPResponse {
    func reporting(
        _ failure: HTTPFailure
    ) -> HTTPResponse {
        var copy = self
        copy.failure = failure
        return copy
    }
}
