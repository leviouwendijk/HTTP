import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpHeaderAccessRegressionFlow = TestFlow(
        "http.header-access.regression",
        title: "HTTP request and response header access remains case-insensitive",
        tags: [
            "http",
            "headers",
            "header-access",
            "regression"
        ]
    ) {
        Step("HTTPRequest.header performs case-insensitive lookup") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "Content-Type": "application/json",
                    "X-Trace-ID": "abc-123"
                ]
            )

            try Expect.equal(
                request.header("content-type"),
                "application/json",
                "header-access.request.content-type-lowercase"
            )

            try Expect.equal(
                request.header("CONTENT-TYPE"),
                "application/json",
                "header-access.request.content-type-uppercase"
            )

            try Expect.equal(
                request.header("x-trace-id"),
                "abc-123",
                "header-access.request.trace-lowercase"
            )
        }

        Step("HTTPResponse.header performs case-insensitive lookup") {
            let response = HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "application/json",
                    "X-Trace-ID": "abc-123"
                ],
                body: "{}"
            )

            try Expect.equal(
                response.header("content-type"),
                "application/json",
                "header-access.response.content-type-lowercase"
            )

            try Expect.equal(
                response.header("CONTENT-TYPE"),
                "application/json",
                "header-access.response.content-type-uppercase"
            )

            try Expect.equal(
                response.header("x-trace-id"),
                "abc-123",
                "header-access.response.trace-lowercase"
            )
        }

        Step("HTTPResponse.setHeader replaces existing header case-insensitively") {
            var response = HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "text/plain"
                ],
                body: "hello"
            )

            response.setHeader(
                "content-type",
                "application/json"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "application/json",
                "header-access.response.set-replaced-value"
            )

            try Expect.equal(
                response.headers.count,
                1,
                "header-access.response.set-replaced-count"
            )
        }

        Step("HTTPResponse.setHeader nil removes existing header case-insensitively") {
            var response = HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "text/plain",
                    "X-Trace-ID": "abc-123"
                ],
                body: "hello"
            )

            response.setHeader(
                "content-type",
                nil
            )

            try Expect.isNil(
                response.header("Content-Type"),
                "header-access.response.removed-content-type"
            )

            try Expect.equal(
                response.header("X-Trace-ID"),
                "abc-123",
                "header-access.response.preserved-other-header"
            )
        }
    }
}
