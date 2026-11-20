import Foundation

public struct HTTPResponse: Sendable {
    public let status: HTTPStatus
    public var headers: HTTPHeaders

    /// Body bytes as sent on the wire. Binary payloads (images, fonts) live here.
    public var bodyData: Data

    /// UTF-8 view of `bodyData`, for textual bodies.
    public var body: String {
        get {
            String(
                decoding: bodyData,
                as: UTF8.self
            )
        }
        set {
            bodyData = Data(
                newValue.utf8
            )
        }
    }

    public var trailers: HTTPHeaders

    /// Structured operational metadata. This is not serialized to the client.
    public var failure: HTTPFailure?

    public init(
        status: HTTPStatus,
        headers: [String: String] = [:],
        body: String = "",
        trailers: [String: String] = [:],
        failure: HTTPFailure? = nil
    ) {
        self.init(
            status: status,
            headers: HTTPHeaders(
                headers
            ),
            body: body,
            trailers: HTTPHeaders(
                trailers
            ),
            failure: failure
        )
    }

    public init(
        status: HTTPStatus,
        headers: HTTPHeaders,
        body: String = "",
        trailers: HTTPHeaders = HTTPHeaders(),
        failure: HTTPFailure? = nil
    ) {
        self.init(
            status: status,
            headers: headers,
            bodyData: Data(
                body.utf8
            ),
            trailers: trailers,
            failure: failure
        )
    }

    public init(
        status: HTTPStatus,
        headers: [String: String] = [:],
        bodyData: Data,
        trailers: [String: String] = [:],
        failure: HTTPFailure? = nil
    ) {
        self.init(
            status: status,
            headers: HTTPHeaders(
                headers
            ),
            bodyData: bodyData,
            trailers: HTTPHeaders(
                trailers
            ),
            failure: failure
        )
    }

    public init(
        status: HTTPStatus,
        headers: HTTPHeaders,
        bodyData: Data,
        trailers: HTTPHeaders = HTTPHeaders(),
        failure: HTTPFailure? = nil
    ) {
        self.status = status
        self.headers = headers
        self.bodyData = bodyData
        self.trailers = trailers
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
