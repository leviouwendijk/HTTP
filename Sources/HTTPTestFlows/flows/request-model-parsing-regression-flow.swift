import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpRequestModelParsingRegressionFlow = TestFlow(
        "http.request-model-parsing.regression",
        title: "HTTPRequest model-owned parsing separates syntax from validation while preserving legacy behavior",
        tags: [
            "http",
            "request",
            "parser",
            "validation",
            "regression",
        ]
    ) {
        Step("model-owned request initializer matches legacy parser") {
            let body = #"{"value":"hello"}"#

            let raw = httpRawMessage(
                headLines: [
                    "POST /items?mode=test HTTP/1.1",
                    "Host: localhost",
                    "Content-Type: application/json",
                    "Content-Length: \(body.utf8.count)",
                    "X-Trace-ID: first",
                    "X-Trace-ID: second",
                ],
                body: body
            )

            let legacy = try HTTPRequest(
                parsing: raw
            )

            let request = try HTTPRequest(
                parsing: raw
            )

            try Expect.equal(
                request.method,
                legacy.method,
                "request-model-parsing.parity.method"
            )

            try Expect.equal(
                request.path,
                legacy.path,
                "request-model-parsing.parity.path"
            )

            try Expect.equal(
                request.headers,
                legacy.headers,
                "request-model-parsing.parity.headers"
            )

            try Expect.equal(
                request.body,
                legacy.body,
                "request-model-parsing.parity.body"
            )
        }

        Step("programmatic request retains target while exposing routing path and query") {
            let request = HTTPRequest(
                method: .get,
                path:
                    "/webhook"
                    + "?hub.mode=subscribe"
                    + "&hub.challenge=abc123"
            )

            try Expect.equal(
                request.target,
                "/webhook"
                    + "?hub.mode=subscribe"
                    + "&hub.challenge=abc123",
                "request-target.programmatic.target"
            )

            try Expect.equal(
                request.path,
                "/webhook",
                "request-target.programmatic.path"
            )

            try Expect.equal(
                request.query,
                "hub.mode=subscribe"
                    + "&hub.challenge=abc123",
                "request-target.programmatic.query"
            )
        }

        Step("request parser parses syntax without method or version policy") {
            let raw = httpRawMessage(
                headLines: [
                    "BREW /coffee HTTP/9.9",
                    "Host: localhost",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            try Expect.equal(
                parsed.requestLine.method,
                "BREW",
                "request-model-parsing.syntax.method"
            )

            try Expect.equal(
                parsed.requestLine.target,
                "/coffee",
                "request-model-parsing.syntax.target"
            )

            try Expect.equal(
                parsed.requestLine.version,
                "HTTP/9.9",
                "request-model-parsing.syntax.version"
            )
        }

        Step("request validator rejects unsupported parsed method") {
            let raw = httpRawMessage(
                headLines: [
                    "BREW /coffee HTTP/1.1",
                    "Host: localhost",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            try Expect.throwsError(
                "request-model-parsing.validation.method"
            ) {
                _ = try HTTPRequest.Validator().validate(
                    parsed
                )
            }
        }

        Step("request validator rejects unsupported parsed version") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /health HTTP/9.9",
                    "Host: localhost",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            try Expect.throwsError(
                "request-model-parsing.validation.version"
            ) {
                _ = try HTTPRequest.Validator().validate(
                    parsed
                )
            }
        }

        Step("model-owned initializer preserves hardened validation") {
            let invalidRequests = [
                httpRawMessage(
                    headLines: [
                        "BREW /coffee HTTP/1.1",
                        "Host: localhost",
                    ]
                ),
                httpRawMessage(
                    headLines: [
                        "GET /a//b HTTP/1.1",
                        "Host: localhost",
                    ]
                ),
                httpRawMessage(
                    headLines: [
                        "GET / HTTP/1.1",
                        "Host: first",
                        "Host: second",
                    ]
                ),
                httpRawMessage(
                    headLines: [
                        "POST / HTTP/1.1",
                        "Host: localhost",
                        "Transfer-Encoding: chunked",
                    ]
                ),
            ]

            for raw in invalidRequests {
                try Expect.throwsError(
                    "request-model-parsing.validation.new"
                ) {
                    _ = try HTTPRequest(
                        parsing: raw
                    )
                }

                try Expect.throwsError(
                    "request-model-parsing.validation.legacy"
                ) {
                    _ = try HTTPRequest(
                        parsing: raw
                    )
                }
            }
        }

        Step("same parsed request can be evaluated under different aggregate policies") {
            let raw = httpRawMessage(
                headLines: [
                    "GET /a//b HTTP/1.1",
                    "Host: localhost",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            let strict = HTTPPolicies.request.default

            let permissive = HTTPRequestPolicies(
                headers: strict.headers,
                content: strict.content,
                target: .permissive
            )

            try Expect.throwsError(
                "request-model-parsing.policy.strict-target"
            ) {
                _ = try HTTPRequest.Validator(
                    policies: strict
                ).validate(
                    parsed
                )
            }

            let request = try HTTPRequest.Validator(
                policies: permissive
            ).validate(
                parsed
            )

            try Expect.equal(
                request.path,
                "/a//b",
                "request-model-parsing.policy.permissive-target"
            )

            let initialized = try HTTPRequest(
                parsing: raw,
                policies: permissive
            )

            try Expect.equal(
                initialized.path,
                request.path,
                "request-model-parsing.policy.initializer"
            )
        }

        Step("request validator applies aggregate content policy") {
            let body = "hello"

            let raw = httpRawMessage(
                headLines: [
                    "POST / HTTP/1.1",
                    "Host: localhost",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            let defaults = HTTPPolicies.request.default

            let restricted = HTTPRequestPolicies(
                headers: defaults.headers,
                content: .custom(
                    body.utf8.count - 1
                ),
                target: defaults.target
            )

            let allowed = HTTPRequestPolicies(
                headers: defaults.headers,
                content: .custom(
                    body.utf8.count
                ),
                target: defaults.target
            )

            try Expect.throwsError(
                "request-model-parsing.policy.content-restricted"
            ) {
                _ = try HTTPRequest.Validator(
                    policies: restricted
                ).validate(
                    parsed
                )
            }

            let request = try HTTPRequest.Validator(
                policies: allowed
            ).validate(
                parsed
            )

            try Expect.equal(
                request.body,
                body,
                "request-model-parsing.policy.content-allowed"
            )
        }

        Step("request parser owns bounded parsing limits") {
            let raw = httpRawMessage(
                headLines: [
                    "GET / HTTP/1.1",
                    "Host: localhost",
                ]
            )

            try Expect.throwsError(
                "request-model-parsing.limits.header-count"
            ) {
                _ = try HTTPRequest.Parser(
                    maximumHeaderCount: 0
                ).parse(
                    raw
                )
            }
        }

        Step("request parser retains raw header syntax until validation") {
            let raw = httpRawMessage(
                headLines: [
                    "GET / HTTP/1.1",
                    " Host :   localhost   ",
                    " X-Trace-ID :   alpha:beta   ",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            try Expect.equal(
                parsed.headerFields.count,
                2,
                "request-model-parsing.raw-headers.count"
            )

            try Expect.equal(
                parsed.headerFields[0].name,
                " Host ",
                "request-model-parsing.raw-headers.name"
            )

            try Expect.equal(
                parsed.headerFields[0].value,
                "   localhost   ",
                "request-model-parsing.raw-headers.value"
            )

            try Expect.equal(
                parsed.headerFields[1].value,
                "   alpha:beta   ",
                "request-model-parsing.raw-headers.colon-value"
            )

            let request = try HTTPRequest.Validator().validate(
                parsed
            )

            try Expect.equal(
                request.header(
                    "Host"
                ),
                "localhost",
                "request-model-parsing.normalized-headers.host"
            )

            try Expect.equal(
                request.header(
                    "X-Trace-ID"
                ),
                "alpha:beta",
                "request-model-parsing.normalized-headers.trace"
            )
        }

        Step("request parser and validator expose distinct error taxonomies") {
            let incomplete = "GET / HTTP/1.1\r\nHost: localhost"

            var parsingErrorObserved = false

            do {
                _ = try HTTPRequest.Parser().parse(
                    incomplete
                )
            } catch is HTTPParsingError {
                parsingErrorObserved = true
            }

            try Expect.equal(
                parsingErrorObserved,
                true,
                "request-model-parsing.error-taxonomy.parser"
            )

            let raw = httpRawMessage(
                headLines: [
                    "BREW / HTTP/1.1",
                    "Host: localhost",
                ]
            )

            let parsed = try HTTPRequest.Parser().parse(
                raw
            )

            var validationErrorObserved = false

            do {
                _ = try HTTPRequest.Validator().validate(
                    parsed
                )
            } catch is HTTPValidationError {
                validationErrorObserved = true
            }

            try Expect.equal(
                validationErrorObserved,
                true,
                "request-model-parsing.error-taxonomy.validator"
            )
        }

        Step("programmatic request construction remains independent of wire validation") {
            let request = HTTPRequest(
                method: .get,
                path: "programmatic-value"
            )

            try Expect.equal(
                request.path,
                "programmatic-value",
                "request-model-parsing.programmatic.path"
            )
        }
    }
}
