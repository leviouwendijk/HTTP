import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpResponseBuilderRegressionFlow = TestFlow(
        "http.response-builder.regression",
        title: "HTTPResponseBuilder preserves ordinary wire serialization behavior",
        tags: [
            "http",
            "response",
            "builder",
            "builder-regression",
            "regression"
        ]
    ) {
        Step("build text response with status line headers separator and newline-terminated body") {
            let response = HTTPResponse.text(
                "hello",
                status: .ok,
                headers: [
                    "X-Trace-ID": "abc-123"
                ]
            )

            let wire = HTTPResponseBuilder.build(
                response
            )

            try Expect.contains(
                wire,
                "HTTP/1.1 200 OK",
                "response-builder.status-line"
            )

            try Expect.contains(
                wire,
                "Content-Type: text/plain; charset=utf-8",
                "response-builder.content-type"
            )

            try Expect.contains(
                wire,
                "X-Trace-ID: abc-123",
                "response-builder.trace-id"
            )

            try Expect.contains(
                wire,
                "\r\n\r\n",
                "response-builder.header-body-separator"
            )

            try Expect.equal(
                wire.hasSuffix("hello\n"),
                true,
                "response-builder.body-newline"
            )
        }

        Step("builder sets Content-Length after appending terminal newline") {
            let response = HTTPResponse.text(
                "hello",
                status: .ok
            )

            let wire = HTTPResponseBuilder.build(
                response
            )

            try Expect.contains(
                wire,
                "Content-Length: 6",
                "response-builder.content-length-with-appended-newline"
            )
        }

        Step("builder does not append duplicate newline when body already has one") {
            let response = HTTPResponse.text(
                "hello\n",
                status: .ok
            )

            let wire = HTTPResponseBuilder.build(
                response
            )

            try Expect.contains(
                wire,
                "Content-Length: 6",
                "response-builder.content-length-existing-newline"
            )

            try Expect.equal(
                wire.hasSuffix("hello\n"),
                true,
                "response-builder.single-existing-newline"
            )

            try Expect.equal(
                wire.hasSuffix("hello\n\n"),
                false,
                "response-builder.no-duplicate-newline"
            )
        }

        Step("builder output round-trips through response parser") {
            let original = HTTPResponse.text(
                "hello",
                status: .ok,
                headers: [
                    "X-Trace-ID": "abc-123"
                ]
            )

            let wire = HTTPResponseBuilder.build(
                original
            )
            let parsed = try HTTPResponseParser.parse(
                wire
            )

            try Expect.equal(
                parsed.status.code,
                200,
                "response-builder.roundtrip.status-code"
            )

            try Expect.equal(
                parsed.header("Content-Type"),
                "text/plain; charset=utf-8",
                "response-builder.roundtrip.content-type"
            )

            try Expect.equal(
                parsed.header("X-Trace-ID"),
                "abc-123",
                "response-builder.roundtrip.trace-id"
            )

            try Expect.equal(
                parsed.header("Content-Length"),
                "6",
                "response-builder.roundtrip.content-length"
            )

            try Expect.equal(
                parsed.body,
                "hello\n",
                "response-builder.roundtrip.body"
            )
        }

        Step("builder preserves explicit content type") {
            let response = HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "application/json; charset=utf-8"
                ],
                body: "{}"
            )

            let wire = HTTPResponseBuilder.build(
                response
            )

            try Expect.contains(
                wire,
                "Content-Type: application/json; charset=utf-8",
                "response-builder.explicit-content-type"
            )

            let parsed = try HTTPResponseParser.parse(
                wire
            )

            try Expect.equal(
                parsed.header("Content-Type"),
                "application/json; charset=utf-8",
                "response-builder.explicit-content-type-roundtrip"
            )
        }
    }
}
