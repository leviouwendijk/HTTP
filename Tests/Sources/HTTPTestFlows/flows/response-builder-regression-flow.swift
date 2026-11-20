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
        Step("build text response with status line headers separator and exact body") {
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
                wire.hasSuffix("hello"),
                true,
                "response-builder.body-exact"
            )

            try Expect.equal(
                wire.hasSuffix("hello\n"),
                false,
                "response-builder.body-no-implicit-newline"
            )
        }

        Step("builder sets Content-Length from exact body bytes") {
            let response = HTTPResponse.text(
                "hello",
                status: .ok
            )

            let wire = HTTPResponseBuilder.build(
                response
            )

            try Expect.contains(
                wire,
                "Content-Length: 5",
                "response-builder.content-length-exact-body"
            )
        }

        Step("builder preserves an explicit terminal newline already present in body") {
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
            let parsed = try HTTPResponse(
                parsing: wire
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
                "5",
                "response-builder.roundtrip.content-length"
            )

            try Expect.equal(
                parsed.body,
                "hello",
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

            let parsed = try HTTPResponse(
                parsing: wire
            )

            try Expect.equal(
                parsed.header("Content-Type"),
                "application/json; charset=utf-8",
                "response-builder.explicit-content-type-roundtrip"
            )
        }

        Step("build binary response with byte-exact body and byte content length") {
            let bytes = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0xFF, 0xFE, 0x0D, 0x0A])

            let response = HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "image/png"
                ],
                bodyData: bytes
            )

            let wire = HTTPResponseBuilder.buildData(
                response
            )

            try Expect.equal(
                wire.suffix(bytes.count),
                bytes,
                "response-builder.binary-body-exact"
            )

            let head = String(
                decoding: wire.prefix(wire.count - bytes.count),
                as: UTF8.self
            )

            try Expect.contains(
                head,
                "Content-Length: \(bytes.count)",
                "response-builder.binary-content-length"
            )

            try Expect.equal(
                head.hasSuffix("\r\n\r\n"),
                true,
                "response-builder.binary-head-terminated"
            )
        }

        Step("text body and bodyData stay in sync") {
            var response = HTTPResponse.text(
                "héllo"
            )

            try Expect.equal(
                response.bodyData,
                Data("héllo".utf8),
                "response-builder.text-to-bytes"
            )

            response.body = "bye"

            try Expect.equal(
                response.bodyData,
                Data("bye".utf8),
                "response-builder.body-setter-updates-bytes"
            )

            try Expect.equal(
                String(decoding: HTTPResponseBuilder.buildData(response), as: UTF8.self),
                HTTPResponseBuilder.build(response),
                "response-builder.data-matches-string-for-text"
            )
        }
    }
}
