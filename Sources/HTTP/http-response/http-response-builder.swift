import Foundation

public struct HTTPResponseBuilder {
    public static func buildValidated(
        _ response: HTTPResponse
    ) throws -> String {
        var headers = HTTPHeaders(response.headers)
        var body = response.body

        if !body.isEmpty && !body.hasSuffix("\n") {
            body.append("\n")
        }

        let bodyData = body.data(using: .utf8) ?? Data()

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

        return headerString + HTTPConstants.crlf + body
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
