import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpRequestParserRegressionFlow = TestFlow(
        "http.request-parser.regression",
        title: "HTTPRequestParser preserves ordinary request parsing behavior",
        tags: [
            "http",
            "request",
            "parser",
            "parser-regression",
            "regression"
        ]
    ) {
        Step("parse simple GET request with headers and empty body") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /health HTTP/1.1",
                    "Host: localhost",
                    "User-Agent: HTTPFlow/1.0"
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.method,
                .get,
                "request-parser.simple.method"
            )

            try Expect.equal(
                request.path,
                "/health",
                "request-parser.simple.path"
            )

            try Expect.equal(
                request.header("Host"),
                "localhost",
                "request-parser.simple.host"
            )

            try Expect.equal(
                request.header("User-Agent"),
                "HTTPFlow/1.0",
                "request-parser.simple.user-agent"
            )

            try Expect.equal(
                request.body,
                "",
                "request-parser.simple.body"
            )
        }

        Step("parse request target with query string unchanged") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /search?q=dog%20training&page=2 HTTP/1.1",
                    "Host: localhost"
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.method,
                .get,
                "request-parser.query.method"
            )

            try Expect.equal(
                request.path,
                "/search?q=dog%20training&page=2",
                "request-parser.query.path"
            )
        }

        Step("parse POST request with JSON body unchanged") {
            let body = #"{"name":"Levi","count":3}"#

            let raw = httpRawMessage(
                headLines: [
                    "POST /api/items HTTP/1.1",
                    "Host: localhost",
                    "Content-Type: application/json",
                    "Content-Length: \(body.utf8.count)"
                ],
                body: body
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.method,
                .post,
                "request-parser.post.method"
            )

            try Expect.equal(
                request.path,
                "/api/items",
                "request-parser.post.path"
            )

            try Expect.equal(
                request.header("Content-Type"),
                "application/json",
                "request-parser.post.content-type"
            )

            try Expect.equal(
                request.header("Content-Length"),
                "\(body.utf8.count)",
                "request-parser.post.content-length"
            )

            try Expect.equal(
                request.body,
                body,
                "request-parser.post.body"
            )
        }

        Step("parse header value containing colon") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /callback HTTP/1.1",
                    "Host: localhost",
                    "X-Callback: https://example.test/a:b?token=c:d"
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.header("X-Callback"),
                "https://example.test/a:b?token=c:d",
                "request-parser.header-value-colon"
            )
        }

        Step("trim ordinary whitespace around header keys and values") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /trim HTTP/1.1",
                    " Host :   localhost   ",
                    " X-Trace-ID :   abc-123   "
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.header("Host"),
                "localhost",
                "request-parser.trim.host"
            )

            try Expect.equal(
                request.header("X-Trace-ID"),
                "abc-123",
                "request-parser.trim.trace-id"
            )
        }

        Step("lookup request headers case-insensitively") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /headers HTTP/1.1",
                    "Host: localhost",
                    "X-Trace-ID: abc-123"
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.header("host"),
                "localhost",
                "request-parser.header-lookup.host-lowercase"
            )

            try Expect.equal(
                request.header("x-trace-id"),
                "abc-123",
                "request-parser.header-lookup.trace-lowercase"
            )

            try Expect.equal(
                request.header("X-TRACE-ID"),
                "abc-123",
                "request-parser.header-lookup.trace-uppercase"
            )
        }

        Step("extract bearer token from parsed Authorization header") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /auth HTTP/1.1",
                    "Host: localhost",
                    "Authorization: Bearer test-token-123"
                ]
            )

            let request = try HTTPRequestParser.parse(raw)

            try Expect.equal(
                request.bearerToken(),
                "test-token-123",
                "request-parser.bearer-token"
            )

            try Expect.equal(
                request.authorizationHeader(),
                "Bearer test-token-123",
                "request-parser.authorization-header"
            )
        }

        Step("decode JSON request body into Decodable payload") {
            let body = #"{"name":"Levi","count":3}"#

            let raw = httpRawMessage(
                headLines: [
                    "POST /decode HTTP/1.1",
                    "Host: localhost",
                    "Content-Type: application/json",
                    "Content-Length: \(body.utf8.count)"
                ],
                body: body
            )

            let request = try HTTPRequestParser.parse(raw)
            let payload = try request.decode(
                HTTPParserRegressionPayload.self
            )

            try Expect.equal(
                payload,
                HTTPParserRegressionPayload(
                    name: "Levi",
                    count: 3
                ),
                "request-parser.decode-json"
            )
        }

        Step("extract Content-Length from ordinary request headers") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "POST / HTTP/1.1",
                        "Host: localhost",
                        "Content-Length: 27"
                    ]
                ).utf8
            )

            let contentLength = HTTPRequestParser.extractContentLength(
                from: headerData
            )

            try Expect.equal(
                contentLength,
                27,
                "request-parser.content-length.normal"
            )
        }

        Step("extract request Content-Length case-insensitively") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "POST / HTTP/1.1",
                        "Host: localhost",
                        "content-length: 12"
                    ]
                ).utf8
            )

            let contentLength = HTTPRequestParser.extractContentLength(
                from: headerData
            )

            try Expect.equal(
                contentLength,
                12,
                "request-parser.content-length.lowercase"
            )
        }

        Step("missing request Content-Length returns nil") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "GET / HTTP/1.1",
                        "Host: localhost"
                    ]
                ).utf8
            )

            let contentLength = HTTPRequestParser.extractContentLength(
                from: headerData
            )

            try Expect.isNil(
                contentLength,
                "request-parser.content-length.missing"
            )
        }

        Step("unknown method throws") {
            let raw = httpRawMessage(
                headLines: [
                    "BREW /coffee HTTP/1.1",
                    "Host: localhost"
                ]
            )

            try Expect.throwsError(
                "request-parser.unknown-method"
            ) {
                _ = try HTTPRequestParser.parse(raw)
            }
        }

        Step("request line without path throws") {
            let raw = httpRawMessage(
                headLines: [
                    "GET",
                    "Host: localhost"
                ]
            )

            try Expect.throwsError(
                "request-parser.missing-path"
            ) {
                _ = try HTTPRequestParser.parse(raw)
            }
        }

        Step("malformed request header throws") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /bad HTTP/1.1",
                    "Host localhost"
                ]
            )

            try Expect.throwsError(
                "request-parser.malformed-header"
            ) {
                _ = try HTTPRequestParser.parse(raw)
            }
        }
    }
}
