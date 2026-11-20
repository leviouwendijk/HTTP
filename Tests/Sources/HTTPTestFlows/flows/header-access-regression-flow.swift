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

        Step("HTTPHeaders.vary inserts values without replacing existing values") {
            var headers = HTTPHeaders(
                [
                    "Vary": "Authorization"
                ]
            )

            headers.vary.insert(
                "Origin"
            )

            try Expect.equal(
                headers["Vary"],
                "Authorization, Origin",
                "header-access.vary.insert"
            )
        }

        Step("HTTPHeaders.vary deduplicates values case-insensitively") {
            var headers = HTTPHeaders(
                [
                    (
                        "Vary",
                        "Authorization"
                    ),
                    (
                        "vary",
                        "Accept-Encoding, origin"
                    ),
                ]
            )

            headers.vary.insert(
                "Origin"
            )

            try Expect.equal(
                headers["Vary"],
                "Authorization, Accept-Encoding, origin",
                "header-access.vary.deduplicate"
            )

            try Expect.equal(
                headers.values(
                    for: "Vary"
                ).count,
                1,
                "header-access.vary.collapsed"
            )
        }

        Step("HTTPHeaders.vary wildcard remains dominant") {
            var headers = HTTPHeaders(
                [
                    "Vary": "*"
                ]
            )

            headers.vary.insert(
                "Origin"
            )

            try Expect.equal(
                headers["Vary"],
                "*",
                "header-access.vary.wildcard"
            )
        }

        Step("HTTPHeaders.contentType owns Content-Type access and mutation") {
            var headers = HTTPHeaders(
                [
                    (
                        "content-type",
                        "text/plain"
                    ),
                    (
                        "Content-Type",
                        "application/json"
                    ),
                ]
            )

            try Expect.equal(
                headers.contentType,
                "text/plain",
                "header-access.content-type.read"
            )

            headers.contentType = "text/html; charset=utf-8"

            try Expect.equal(
                headers.contentType,
                "text/html; charset=utf-8",
                "header-access.content-type.write"
            )

            try Expect.equal(
                headers.values(
                    for: "Content-Type"
                ).count,
                1,
                "header-access.content-type.collapsed"
            )

            headers.contentType = nil

            try Expect.isNil(
                headers.contentType,
                "header-access.content-type.removed"
            )
        }

        Step("HTTPHeaders.authorization owns Authorization access and mutation") {
            var headers = HTTPHeaders(
                [
                    (
                        "authorization",
                        "Bearer first"
                    ),
                    (
                        "Authorization",
                        "Bearer second"
                    ),
                ]
            )

            try Expect.equal(
                headers.authorization,
                "Bearer first",
                "header-access.authorization.read"
            )

            headers.authorization = "Bearer replacement"

            try Expect.equal(
                headers.authorization,
                "Bearer replacement",
                "header-access.authorization.write"
            )

            try Expect.equal(
                headers.values(
                    for: "Authorization"
                ).count,
                1,
                "header-access.authorization.collapsed"
            )

            headers.authorization = nil

            try Expect.isNil(
                headers.authorization,
                "header-access.authorization.removed"
            )
        }

        Step("HTTPHeaders.wwwAuthenticate owns WWW-Authenticate access and mutation") {
            var headers = HTTPHeaders(
                [
                    (
                        "www-authenticate",
                        "Bearer realm=\"first\""
                    ),
                    (
                        "WWW-Authenticate",
                        "Bearer realm=\"second\""
                    ),
                ]
            )

            try Expect.equal(
                headers.wwwAuthenticate,
                "Bearer realm=\"first\"",
                "header-access.www-authenticate.read"
            )

            headers.wwwAuthenticate = "Bearer realm=\"replacement\""

            try Expect.equal(
                headers.wwwAuthenticate,
                "Bearer realm=\"replacement\"",
                "header-access.www-authenticate.write"
            )

            try Expect.equal(
                headers.values(
                    for: "WWW-Authenticate"
                ).count,
                1,
                "header-access.www-authenticate.collapsed"
            )

            headers.wwwAuthenticate = nil

            try Expect.isNil(
                headers.wwwAuthenticate,
                "header-access.www-authenticate.removed"
            )
        }
    }
}
