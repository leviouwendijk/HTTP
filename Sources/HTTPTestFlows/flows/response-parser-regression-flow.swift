import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpResponseParserRegressionFlow = TestFlow(
        "http.response-parser.regression",
        title: "HTTPResponseParser preserves ordinary response parsing behavior",
        tags: [
            "http",
            "response",
            "parser",
            "parser-regression",
            "regression"
        ]
    ) {
        Step("parse simple 200 response with headers and body") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: text/plain; charset=utf-8",
                    "Content-Length: 5"
                ],
                body: "hello"
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.status.code,
                200,
                "response-parser.simple.status-code"
            )

            try Expect.equal(
                response.status.reason,
                "Success",
                "response-parser.simple.status-reason"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "text/plain; charset=utf-8",
                "response-parser.simple.content-type"
            )

            try Expect.equal(
                response.header("Content-Length"),
                "5",
                "response-parser.simple.content-length"
            )

            try Expect.equal(
                response.body,
                "hello",
                "response-parser.simple.body"
            )
        }

        Step("parse CRLF response headers without retaining carriage returns") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: text/plain; charset=utf-8",
                    "X-Trace-ID: abc-123",
                    "Content-Length: 5"
                ],
                body: "hello"
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.header("Content-Type"),
                "text/plain; charset=utf-8",
                "response-parser.crlf-headers.content-type"
            )

            try Expect.equal(
                response.header("X-Trace-ID"),
                "abc-123",
                "response-parser.crlf-headers.trace-id"
            )

            try Expect.equal(
                response.header("Content-Length"),
                "5",
                "response-parser.crlf-headers.content-length"
            )

            try Expect.equal(
                response.headers.keys.contains("Content-Type\r"),
                false,
                "response-parser.crlf-headers.no-carriage-return-in-key"
            )

            try Expect.equal(
                response.headers.values.contains("text/plain; charset=utf-8\r"),
                false,
                "response-parser.crlf-headers.no-carriage-return-in-value"
            )
        }

        Step("response header lookup is case-insensitive after parsing") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: application/json; charset=utf-8",
                    "X-Trace-ID: abc-123",
                    "Content-Length: 2"
                ],
                body: "{}"
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.header("content-type"),
                "application/json; charset=utf-8",
                "response-parser.header-lookup.content-type-lowercase"
            )

            try Expect.equal(
                response.header("CONTENT-TYPE"),
                "application/json; charset=utf-8",
                "response-parser.header-lookup.content-type-uppercase"
            )

            try Expect.equal(
                response.header("x-trace-id"),
                "abc-123",
                "response-parser.header-lookup.trace-lowercase"
            )
        }

        Step("parse no-content response with empty body") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 204 No Content",
                    "Content-Length: 0"
                ]
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.status.code,
                204,
                "response-parser.no-content.status-code"
            )

            try Expect.equal(
                response.body,
                "",
                "response-parser.no-content.body"
            )
        }

        Step("parse response header value containing colon") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 302 Found",
                    "Location: https://example.test/a:b?token=c:d",
                    "Content-Length: 0"
                ]
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.status.code,
                302,
                "response-parser.header-value-colon.status-code"
            )

            try Expect.equal(
                response.header("Location"),
                "https://example.test/a:b?token=c:d",
                "response-parser.header-value-colon.location"
            )
        }

        Step("trim ordinary whitespace around response header keys and values") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    " Content-Type :   text/plain   ",
                    " X-Trace-ID :   abc-123   "
                ],
                body: "ok"
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.header("Content-Type"),
                "text/plain",
                "response-parser.trim.content-type"
            )

            try Expect.equal(
                response.header("X-Trace-ID"),
                "abc-123",
                "response-parser.trim.trace-id"
            )
        }

        Step("parse response body containing normal newlines unchanged") {
            let body = "line one\nline two\nline three"

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: text/plain; charset=utf-8",
                    "Content-Length: \(body.utf8.count)"
                ],
                body: body
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.body,
                body,
                "response-parser.body-newlines"
            )
        }

        Step("parse response body containing CRLFCRLF unchanged") {
            let body = "alpha\r\n\r\nbeta"

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: text/plain; charset=utf-8",
                    "Content-Length: \(body.utf8.count)"
                ],
                body: body
            )

            let response = try HTTPResponseParser.parse(raw)

            try Expect.equal(
                response.body,
                body,
                "response-parser.body-containing-header-separator"
            )
        }

        Step("extract Content-Length from ordinary response headers") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "HTTP/1.1 200 OK",
                        "Content-Length: 5"
                    ]
                ).utf8
            )

            let contentLength = HTTPResponseParser.extractContentLength(
                from: headerData
            )

            try Expect.equal(
                contentLength,
                5,
                "response-parser.content-length.normal"
            )
        }

        Step("extract response Content-Length case-insensitively") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "HTTP/1.1 200 OK",
                        "content-length: 5"
                    ]
                ).utf8
            )

            let contentLength = HTTPResponseParser.extractContentLength(
                from: headerData
            )

            try Expect.equal(
                contentLength,
                5,
                "response-parser.content-length.lowercase"
            )
        }

        Step("missing response Content-Length returns nil") {
            let headerData = Data(
                httpRawMessage(
                    headLines: [
                        "HTTP/1.1 200 OK",
                        "Content-Type: text/plain"
                    ]
                ).utf8
            )

            let contentLength = HTTPResponseParser.extractContentLength(
                from: headerData
            )

            try Expect.isNil(
                contentLength,
                "response-parser.content-length.missing"
            )
        }

        Step("invalid response status code throws") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 nope OK",
                    "Content-Length: 0"
                ]
            )

            try Expect.throwsError(
                "response-parser.invalid-status-code"
            ) {
                _ = try HTTPResponseParser.parse(raw)
            }
        }

        Step("malformed response header throws") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type text/plain"
                ],
                body: "ok"
            )

            try Expect.throwsError(
                "response-parser.malformed-header"
            ) {
                _ = try HTTPResponseParser.parse(raw)
            }
        }
    }
}
