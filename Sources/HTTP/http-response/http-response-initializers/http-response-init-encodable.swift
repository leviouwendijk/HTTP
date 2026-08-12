import Foundation
import Primitives

public extension HTTPResponse {
    static func json<Value: Encodable>(
        _ value: Value,
        status: HTTPStatus = .ok,
        headers: HTTPHeaders = HTTPHeaders(),
        using encoder: JSONEncoder = HTTPJSONCoding.current.encoder()
    ) throws -> HTTPResponse {
        let data = try encoder.encode(
            value
        )

        var headers = headers

        headers[
            "Content-Type"
        ] = "application/json; charset=utf-8"

        return HTTPResponse(
            status: status,
            headers: headers,
            body: String(
                decoding: data,
                as: UTF8.self
            )
        )
    }
}
