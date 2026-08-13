import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpProtocolBaselineRegressionFlow = TestFlow(
        "http.protocol-baseline.regression",
        title: "HTTP protocol grammar, framing boundaries, and duplicate header semantics remain stable",
        tags: [
            "http",
            "protocol",
            "grammar",
            "framing",
            "headers",
            "regression",
        ]
    ) {
        Step("request parser rejects unsupported HTTP version") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /health HTTP/1.0",
                    "Host: localhost",
                ]
            )

            try Expect.throwsError(
                "protocol-baseline.request.unsupported-version"
            ) {
                _ = try HTTPRequest(
                    parsing: raw
                )
            }
        }

        Step("request parser rejects extra request-line component") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /health HTTP/1.1 extra",
                    "Host: localhost",
                ]
            )

            try Expect.throwsError(
                "protocol-baseline.request.extra-component"
            ) {
                _ = try HTTPRequest(
                    parsing: raw
                )
            }
        }

        Step("request parser rejects ambiguous request-line spacing") {
            for requestLine in [
                "GET  /health HTTP/1.1",
                " GET /health HTTP/1.1",
                "GET /health HTTP/1.1 ",
            ] {
                let raw = httpRawMessage(
                    headLines: [
                        requestLine,
                        "Host: localhost",
                    ]
                )

                try Expect.throwsError(
                    "protocol-baseline.request.ambiguous-spacing"
                ) {
                    _ = try HTTPRequest(
                        parsing: raw
                    )
                }
            }
        }

        Step("request parser preserves body after first header separator") {
            let body = "alpha\r\n\r\nomega"

            let raw = httpRawMessage(
                headLines: [
                    "POST /body HTTP/1.1",
                    "Host: localhost",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let request = try HTTPRequest(
                parsing: raw
            )

            try Expect.equal(
                request.body,
                body,
                "protocol-baseline.request.body-separator"
            )
        }

        Step("request parser preserves duplicate non-singleton headers in order") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /headers HTTP/1.1",
                    "Host: localhost",
                    "X-Tag: one",
                    "x-tag: two",
                    "X-TAG: three",
                ]
            )

            let request = try HTTPRequest(
                parsing: raw
            )

            try Expect.equal(
                request.headers.values(
                    for: "x-tag"
                ),
                [
                    "one",
                    "two",
                    "three",
                ],
                "protocol-baseline.request.duplicate-values"
            )

            try Expect.equal(
                request.headers.keys.filter {
                    $0.lowercased() == "x-tag"
                },
                [
                    "X-Tag",
                    "x-tag",
                    "X-TAG",
                ],
                "protocol-baseline.request.duplicate-order"
            )
        }

        Step("response parser rejects unsupported HTTP version") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.0 200 OK",
                    "Content-Length: 0",
                ]
            )

            try Expect.throwsError(
                "protocol-baseline.response.unsupported-version"
            ) {
                _ = try HTTPResponse(
                    parsing: raw
                )
            }
        }

        Step("response parser accepts status line without reason phrase") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 204",
                    "Content-Length: 0",
                ]
            )

            let response = try HTTPResponse(
                parsing: raw
            )

            try Expect.equal(
                response.status.code,
                204,
                "protocol-baseline.response.reason-optional"
            )
        }

        Step("response parser preserves duplicate non-singleton headers in order") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "X-Tag: one",
                    "x-tag: two",
                    "X-TAG: three",
                    "Content-Length: 0",
                ]
            )

            let response = try HTTPResponse(
                parsing: raw
            )

            try Expect.equal(
                response.headers.values(
                    for: "x-tag"
                ),
                [
                    "one",
                    "two",
                    "three",
                ],
                "protocol-baseline.response.duplicate-values"
            )

            try Expect.equal(
                response.headers.keys.filter {
                    $0.lowercased() == "x-tag"
                },
                [
                    "X-Tag",
                    "x-tag",
                    "X-TAG",
                ],
                "protocol-baseline.response.duplicate-order"
            )
        }

        Step("request and response parsers require complete header terminator") {
            try Expect.throwsError(
                "protocol-baseline.request.header-terminator"
            ) {
                _ = try HTTPRequest(
                    parsing: "GET / HTTP/1.1\r\nHost: localhost\r\n"
                )
            }

            try Expect.throwsError(
                "protocol-baseline.response.header-terminator"
            ) {
                _ = try HTTPResponse(
                    parsing: "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n"
                )
            }
        }

        Step("HTTPHeaders set replaces all case-insensitive duplicates") {
            var headers = HTTPHeaders(
                [
                    (
                        "Vary",
                        "Origin"
                    ),
                    (
                        "vary",
                        "Accept-Encoding"
                    ),
                    (
                        "X-Trace-ID",
                        "abc-123"
                    ),
                ]
            )

            headers.set(
                "VARY",
                "Authorization"
            )

            try Expect.equal(
                headers.values(
                    for: "vary"
                ),
                [
                    "Authorization",
                ],
                "protocol-baseline.headers.set-values"
            )

            try Expect.equal(
                headers.count,
                2,
                "protocol-baseline.headers.set-count"
            )

            try Expect.equal(
                headers.get(
                    "x-trace-id"
                ),
                "abc-123",
                "protocol-baseline.headers.set-preserves-other"
            )
        }
    }
}
