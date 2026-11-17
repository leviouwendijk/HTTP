import Foundation

public struct HTTPResponseBuilder {
    public static func buildValidated(
        _ response: HTTPResponse
    ) throws -> String {
        try validatedHead(response) + response.body
    }

    /// Wire bytes: validated head followed by `bodyData` unchanged, so binary bodies survive.
    public static func buildValidatedData(
        _ response: HTTPResponse
    ) throws -> Data {
        var wire = Data(
            try validatedHead(response).utf8
        )
        wire.append(
            response.bodyData
        )
        return wire
    }

    public static func buildData(
        _ response: HTTPResponse
    ) -> Data {
        do {
            return try buildValidatedData(response)
        } catch {
            return Data(
                fallbackInternalServerError().utf8
            )
        }
    }

    /// Status line and headers, terminated by the blank line that precedes the body.
    private static func validatedHead(
        _ response: HTTPResponse
    ) throws -> String {
        var headers = HTTPHeaders(response.headers)
        let bodyData = response.bodyData

        headers.set(
            HTTPConstants.contentLengthHeader,
            "\(bodyData.count)"
        )

        if headers.get(HTTPConstants.contentTypeHeader) == nil {
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
        _ response: HTTPResponse
    ) -> String {
        do {
            return try buildValidated(response)
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

// public struct HTTPResponseBuilder {
//     public static func build(_ response: HTTPResponse) -> String {
//         var headers = HTTPHeaders(response.headers)
//         var body = response.body
//         if !body.isEmpty && !body.hasSuffix("\n") {
//             body.append("\n")
//         }

//         // Calculate and set Content-Length
//         let bodyData = body.data(using: .utf8) ?? Data()
//         headers.set(HTTPConstants.contentLengthHeader, "\(bodyData.count)")

//         // print("Response body before newline: '\(response.body.debugDescription)'")                                                 
//         // print("Response body after newline: '\(body.debugDescription)'")
//         // print("Content-Length will be: \(bodyData.count)")
        
//         // Set default Content-Type if not provided
//         if headers.get(HTTPConstants.contentTypeHeader) == nil {
//             headers.set(HTTPConstants.contentTypeHeader, HTTPConstants.defaultContentType)
//         }
        
//         // Build status line
//         let statusLine = "\(HTTPConstants.httpVersion) \(response.status.code) \(response.status.reason)"
        
//         // Build header lines (deterministic order)
//         let headerLines = headers.lines()
        
//         // Assemble response
//         var lines: [String] = [statusLine]
//         lines.append(contentsOf: headerLines)
//         lines.append("")  // blank line
        
//         let headerString = lines.joined(separator: HTTPConstants.crlf)
//         return headerString + HTTPConstants.crlf + body
//     }
// }
