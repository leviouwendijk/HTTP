import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpResponseFramingRegressionFlow = TestFlow(
        "http.response-framing.regression",
        title: "Response builder frames bodyless responses by method and status",
        tags: [
            "http",
            "response",
            "framing",
            "regression"
        ]
    ) {
        Step("HEAD sends the body length but no body") {
            let wire = HTTPResponseBuilder.build(
                .ok(
                    body: "HEADBODY"
                ),
                for: .head
            )

            try Expect.contains(
                wire,
                "Content-Length: 8",
                "response-framing.head.length"
            )

            try Expect.true(
                wire.hasSuffix(
                    "\r\n\r\n"
                ),
                "response-framing.head.no-body"
            )
        }

        Step("HEAD keeps an explicit Content-Length") {
            let wire = HTTPResponseBuilder.build(
                HTTPResponse(
                    status: .ok,
                    headers: [
                        "Content-Length": "42"
                    ]
                ),
                for: .head
            )

            try Expect.contains(
                wire,
                "Content-Length: 42",
                "response-framing.head.explicit-length"
            )
        }

        Step("204 sends neither Content-Length nor body") {
            let wire = HTTPResponseBuilder.build(
                HTTPResponse(
                    status: .noContent,
                    body: "ignored"
                ),
                for: .get
            )

            try Expect.doesNotContain(
                wire,
                "Content-Length",
                "response-framing.204.no-length"
            )

            try Expect.true(
                wire.hasSuffix(
                    "\r\n\r\n"
                ),
                "response-framing.204.no-body"
            )
        }

        Step("304 sends no body") {
            let wire = HTTPResponseBuilder.build(
                HTTPResponse(
                    status: .notModified,
                    body: "ignored"
                ),
                for: .get
            )

            try Expect.true(
                wire.hasSuffix(
                    "\r\n\r\n"
                ),
                "response-framing.304.no-body"
            )
        }

        Step("Transfer-Encoding is removed in favor of Content-Length") {
            let wire = HTTPResponseBuilder.build(
                HTTPResponse(
                    status: .ok,
                    headers: [
                        "Transfer-Encoding": "chunked"
                    ],
                    body: "abc"
                ),
                for: .get
            )

            try Expect.doesNotContain(
                wire,
                "Transfer-Encoding",
                "response-framing.te.removed"
            )

            try Expect.contains(
                wire,
                "Content-Length: 3",
                "response-framing.te.length"
            )
        }
    }
}
