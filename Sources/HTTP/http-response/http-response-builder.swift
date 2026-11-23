import Foundation

/// Serializes responses with `Content-Length` framing.
///
/// Pass the request method so bodyless responses frame correctly (RFC 9110 §6.4.1, §8.6):
/// - 1xx and 204: no `Content-Length`, no body.
/// - 304: no body; an explicit `Content-Length` is kept.
/// - HEAD: no body; `Content-Length` is the explicit header if set, else the body's length.
/// `Transfer-Encoding` is always removed, since the body is never chunked.
public struct HTTPResponseBuilder {
    public static func buildValidated(
        _ response: HTTPResponse,
        for method: HTTPMethod? = nil
    ) throws -> String {
        String(
            decoding: try buildValidatedData(
                response,
                for: method
            ),
            as: UTF8.self
        )
    }

    /// Wire bytes: validated head followed by `bodyData` unchanged, so binary bodies survive.
    public static func buildValidatedData(
        _ response: HTTPResponse,
        for method: HTTPMethod? = nil
    ) throws -> Data {
        let framing = Framing(
            status: response.status,
            method: method
        )

        var wire = Data(
            try validatedHead(
                response,
                framing: framing
            ).utf8
        )

        if framing.sendsBody {
            wire.append(
                response.bodyData
            )
        }

        return wire
    }

    public static func buildData(
        _ response: HTTPResponse,
        for method: HTTPMethod? = nil
    ) -> Data {
        do {
            return try buildValidatedData(
                response,
                for: method
            )
        } catch {
            return Data(
                fallbackInternalServerError().utf8
            )
        }
    }

    private struct Framing {
        let sendsBody: Bool
        let sendsContentLength: Bool
        let keepsExplicitContentLength: Bool

        init(
            status: HTTPStatus,
            method: HTTPMethod?
        ) {
            let code = status.code

            if (100...199).contains(code) || code == 204 {
                sendsBody = false
                sendsContentLength = false
                keepsExplicitContentLength = false
            } else if code == 304 {
                sendsBody = false
                sendsContentLength = false
                keepsExplicitContentLength = true
            } else if method == .head {
                sendsBody = false
                sendsContentLength = true
                keepsExplicitContentLength = true
            } else {
                sendsBody = true
                sendsContentLength = true
                keepsExplicitContentLength = false
            }
        }
    }

    /// Status line and headers, terminated by the blank line that precedes the body.
    private static func validatedHead(
        _ response: HTTPResponse,
        framing: Framing
    ) throws -> String {
        var headers = HTTPHeaders(response.headers)
        let bodyData = response.bodyData

        headers.remove(
            HTTPConstants.transferEncodingHeader
        )

        let explicitContentLength = headers.get(
            HTTPConstants.contentLengthHeader
        )

        if framing.keepsExplicitContentLength,
           let explicitContentLength {
            headers.set(
                HTTPConstants.contentLengthHeader,
                explicitContentLength
            )
        } else if framing.sendsContentLength {
            headers.set(
                HTTPConstants.contentLengthHeader,
                "\(bodyData.count)"
            )
        } else {
            headers.remove(
                HTTPConstants.contentLengthHeader
            )
        }

        if framing.sendsContentLength,
           headers.get(HTTPConstants.contentTypeHeader) == nil {
            headers.set(
                HTTPConstants.contentTypeHeader,
                HTTPConstants.defaultContentType
            )
        }

        try HTTPWireValidation.validateStatusCode(
            response.status.code
        )

        try HTTPWireValidation.validateStatusReason(
            response.status.reason
        )

        let statusLine = "\(HTTPConstants.httpVersion) \(response.status.code) \(response.status.reason)"

        var headerPairs: [(String, String)] = []
        headers.forEach {
            headerPairs.append(
                ($0, $1)
            )
        }

        let headerLines = try HTTPWireValidation.headerLines(
            headerPairs
        )

        var lines: [String] = [statusLine]
        lines.append(contentsOf: headerLines)
        lines.append("")

        let headerString = lines.joined(
            separator: HTTPConstants.crlf
        )

        return headerString + HTTPConstants.crlf
    }

    public static func build(
        _ response: HTTPResponse,
        for method: HTTPMethod? = nil
    ) -> String {
        do {
            return try buildValidated(
                response,
                for: method
            )
        } catch {
            return fallbackInternalServerError()
        }
    }

    private static func fallbackInternalServerError() -> String {
        let body = "Internal Server Error\n"

        let bodyLength = body.data(
            using: .utf8
        )?.count ?? 0

        let lines = [
            "\(HTTPConstants.httpVersion) 500 Internal Server Error",
            "\(HTTPConstants.contentLengthHeader): \(bodyLength)",
            "\(HTTPConstants.contentTypeHeader): \(HTTPConstants.defaultContentType)",
            "",
        ]

        return lines.joined(
            separator: HTTPConstants.crlf
        ) + HTTPConstants.crlf + body
    }
}
