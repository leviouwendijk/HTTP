import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpResponseModelParsingRegressionFlow = TestFlow(
        "http.response-model-parsing.regression",
        title: "HTTPResponse model-owned parsing separates retained syntax from acceptance while preserving legacy behavior",
        tags: [
            "http",
            "response",
            "parser",
            "validation",
            "regression",
        ]
    ) {
        Step("model-owned response initializer matches legacy parser") {
            let body = "hello"

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Type: text/plain",
                    "Content-Length: \(body.utf8.count)",
                    "X-Trace-ID: first",
                    "X-Trace-ID: second",
                ],
                body: body
            )

            let legacy = try HTTPResponse(
                parsing: raw
            )

            let response = try HTTPResponse(
                parsing: raw
            )

            try Expect.equal(
                response.status,
                legacy.status,
                "response-model-parsing.parity.status"
            )

            try Expect.equal(
                response.headers,
                legacy.headers,
                "response-model-parsing.parity.headers"
            )

            try Expect.equal(
                response.body,
                legacy.body,
                "response-model-parsing.parity.body"
            )
        }

        Step("response parser retains syntax without applying version or status policy") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/9.9 nope Whatever",
                    "X-Trace-ID: abc",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            try Expect.equal(
                parsed.statusLine.version,
                "HTTP/9.9",
                "response-model-parsing.syntax.version"
            )

            try Expect.equal(
                parsed.statusLine.statusCode,
                "nope",
                "response-model-parsing.syntax.code"
            )

            try Expect.equal(
                parsed.statusLine.reasonPhrase,
                "Whatever",
                "response-model-parsing.syntax.reason"
            )
        }

        Step("response parser retains raw header syntax until validation") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    " Content-Type :   text/plain   ",
                    " X-Trace-ID :   alpha:beta   ",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            try Expect.equal(
                parsed.headerFields[0].name,
                " Content-Type ",
                "response-model-parsing.raw-headers.name"
            )

            try Expect.equal(
                parsed.headerFields[0].value,
                "   text/plain   ",
                "response-model-parsing.raw-headers.value"
            )

            try Expect.equal(
                parsed.headerFields[1].value,
                "   alpha:beta   ",
                "response-model-parsing.raw-headers.colon-value"
            )

            let response = try HTTPResponse.Validator().validate(
                parsed
            )

            try Expect.equal(
                response.header(
                    "Content-Type"
                ),
                "text/plain",
                "response-model-parsing.normalized-headers.content-type"
            )

            try Expect.equal(
                response.header(
                    "X-Trace-ID"
                ),
                "alpha:beta",
                "response-model-parsing.normalized-headers.trace"
            )
        }

        Step("response validator rejects unsupported parsed version") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/9.9 200 OK",
                    "Content-Length: 0",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            try Expect.throwsError(
                "response-model-parsing.validation.version"
            ) {
                _ = try HTTPResponse.Validator().validate(
                    parsed
                )
            }
        }

        Step("response validator rejects nonnumeric parsed status code") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 nope Nope",
                    "Content-Length: 0",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            try Expect.throwsError(
                "response-model-parsing.validation.status-code"
            ) {
                _ = try HTTPResponse.Validator().validate(
                    parsed
                )
            }
        }

        Step("model-owned response initializer preserves duplicate singleton rejection") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Length: 0",
                    "content-length: 0",
                ]
            )

            try Expect.throwsError(
                "response-model-parsing.validation.duplicate-content-length"
            ) {
                _ = try HTTPResponse(
                    parsing: raw
                )
            }

            try Expect.throwsError(
                "response-model-parsing.validation.legacy-duplicate-content-length"
            ) {
                _ = try HTTPResponse(
                    parsing: raw
                )
            }
        }

        Step("same parsed response can be evaluated under different aggregate policies") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Length: 0",
                    "content-length: 0",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            let strict = HTTPPolicies.response.default

            let permissive = HTTPResponsePolicies(
                headers: .permissive,
                content: strict.content
            )

            try Expect.throwsError(
                "response-model-parsing.policy.strict-headers"
            ) {
                _ = try HTTPResponse.Validator(
                    policies: strict
                ).validate(
                    parsed
                )
            }

            let response = try HTTPResponse.Validator(
                policies: permissive
            ).validate(
                parsed
            )

            try Expect.equal(
                response.headers.values(
                    for: HTTPConstants.contentLengthHeader
                ).count,
                2,
                "response-model-parsing.policy.permissive-headers"
            )

            let initialized = try HTTPResponse(
                parsing: raw,
                policies: permissive
            )

            try Expect.equal(
                initialized.headers,
                response.headers,
                "response-model-parsing.policy.initializer"
            )
        }

        Step("response validator applies aggregate content policy") {
            let body = "hello"

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            let defaults = HTTPPolicies.response.default

            let restricted = HTTPResponsePolicies(
                headers: defaults.headers,
                content: .custom(
                    body.utf8.count - 1
                )
            )

            let allowed = HTTPResponsePolicies(
                headers: defaults.headers,
                content: .custom(
                    body.utf8.count
                )
            )

            try Expect.throwsError(
                "response-model-parsing.policy.content-restricted"
            ) {
                _ = try HTTPResponse.Validator(
                    policies: restricted
                ).validate(
                    parsed
                )
            }

            let response = try HTTPResponse.Validator(
                policies: allowed
            ).validate(
                parsed
            )

            try Expect.equal(
                response.body,
                body,
                "response-model-parsing.policy.content-allowed"
            )
        }

        Step("response parser owns bounded parsing limits") {
            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Length: 0",
                ]
            )

            try Expect.throwsError(
                "response-model-parsing.limits.header-count"
            ) {
                _ = try HTTPResponse.Parser(
                    maximumHeaderCount: 0
                ).parse(
                    raw
                )
            }
        }

        Step("response parser preserves body after first header separator") {
            let body = "alpha\r\n\r\nomega"

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/1.1 200 OK",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let response = try HTTPResponse(
                parsing: raw
            )

            try Expect.equal(
                response.body,
                body,
                "response-model-parsing.body-separator"
            )
        }

        Step("response parser and validator expose distinct error taxonomies") {
            let incomplete = "HTTP/1.1 200 OK\r\nContent-Length: 0"

            var parsingErrorObserved = false

            do {
                _ = try HTTPResponse.Parser().parse(
                    incomplete
                )
            } catch is HTTPParsingError {
                parsingErrorObserved = true
            }

            try Expect.equal(
                parsingErrorObserved,
                true,
                "response-model-parsing.error-taxonomy.parser"
            )

            let raw = httpRawMessage(
                headLines: [
                    "HTTP/9.0 200 OK",
                    "Content-Length: 0",
                ]
            )

            let parsed = try HTTPResponse.Parser().parse(
                raw
            )

            var validationErrorObserved = false

            do {
                _ = try HTTPResponse.Validator().validate(
                    parsed
                )
            } catch is HTTPValidationError {
                validationErrorObserved = true
            }

            try Expect.equal(
                validationErrorObserved,
                true,
                "response-model-parsing.error-taxonomy.validator"
            )
        }

        Step("programmatic response construction remains independent of wire parsing") {
            let response = HTTPResponse(
                status: HTTPStatus(
                    code: 777,
                    reason: "Programmatic"
                ),
                body: "value"
            )

            try Expect.equal(
                response.status.code,
                777,
                "response-model-parsing.programmatic.status"
            )

            try Expect.equal(
                response.body,
                "value",
                "response-model-parsing.programmatic.body"
            )
        }
    }
}
