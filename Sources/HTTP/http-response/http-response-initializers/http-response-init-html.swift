import Foundation

public extension HTTPResponse {
    /// Create an HTML response
    static func html(_ body: String, status: HTTPStatus = .ok, headers: [String: String] = [:]) -> HTTPResponse {
        var h = HTTPHeaders(
            headers
        )

        h.contentType = "text/html; charset=utf-8"
        return HTTPResponse(status: status, headers: h, body: body)
    }
}
