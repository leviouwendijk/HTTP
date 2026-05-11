import Foundation

public struct HTTPResponse: Sendable {
    public let status: HTTPStatus
    public var headers: HTTPHeaders
    public var body: String

    public init(
        status: HTTPStatus,
        headers: [String: String] = [:],
        body: String = ""
    ) {
        self.init(
            status: status,
            headers: HTTPHeaders(headers),
            body: body
        )
    }

    public init(
        status: HTTPStatus,
        headers: HTTPHeaders,
        body: String = ""
    ) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}
