import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpMethodStatusRegressionFlow = TestFlow(
        "http.method-status.regression",
        title: "HTTP method semantics and canonical status resolution remain stable",
        tags: [
            "http",
            "method",
            "status",
            "query",
            "regression",
        ]
    ) {
        Step("QUERY is recognized with safe and idempotent semantics") {
            try Expect.equal(
                HTTPMethod.query.rawValue,
                "QUERY",
                "method-status.query.raw-value"
            )

            try Expect.equal(
                HTTPMethod.query.isSafe,
                true,
                "method-status.query.safe"
            )

            try Expect.equal(
                HTTPMethod.query.isIdempotent,
                true,
                "method-status.query.idempotent"
            )

            try Expect.equal(
                HTTPMethod.defaultServerAllowed.contains(
                    .query
                ),
                true,
                "method-status.query.default-server-allowed"
            )
        }

        Step("standard method safety and idempotence remain explicit") {
            let semantics: [
                (
                    method: HTTPMethod,
                    safe: Bool,
                    idempotent: Bool
                )
            ] = [
                (.get, true, true),
                (.head, true, true),
                (.options, true, true),
                (.query, true, true),
                (.trace, true, true),
                (.put, false, true),
                (.delete, false, true),
                (.connect, false, false),
                (.patch, false, false),
                (.post, false, false),
            ]

            for entry in semantics {
                try Expect.equal(
                    entry.method.isSafe,
                    entry.safe,
                    "method-status.\(entry.method.rawValue).safe"
                )

                try Expect.equal(
                    entry.method.isIdempotent,
                    entry.idempotent,
                    "method-status.\(entry.method.rawValue).idempotent"
                )
            }
        }

        Step("request parser accepts QUERY") {
            let body = #"{"term":"dogs"}"#

            let raw = httpRawMessage(
                headLines: [
                    "QUERY /search HTTP/1.1",
                    "Host: localhost",
                    "Content-Type: application/json",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let request = try HTTPRequest(
                parsing: raw
            )

            try Expect.equal(
                request.method,
                .query,
                "method-status.query.request-parser"
            )

            try Expect.equal(
                request.body,
                body,
                "method-status.query.request-body"
            )
        }

        Step("known status codes resolve to canonical statuses") {
            try Expect.equal(
                HTTPStatus.resolve(
                    code: 200
                ),
                .ok,
                "method-status.status.ok"
            )

            try Expect.equal(
                HTTPStatus.resolve(
                    code: 413
                ),
                .contentTooLarge,
                "method-status.status.content-too-large"
            )

            try Expect.equal(
                HTTPStatus.resolve(
                    code: 422
                ),
                .unprocessableContent,
                "method-status.status.unprocessable-content"
            )

            try Expect.equal(
                HTTPStatus.resolve(
                    code: 505
                ),
                .httpVersionNotSupported,
                "method-status.status.http-version-not-supported"
            )
        }

        Step("unused, obsolete, and unknown codes use family fallback") {
            try Expect.equal(
                HTTPStatus.resolve(
                    code: 418
                ).reason,
                "Client Error",
                "method-status.status.418-unused"
            )

            try Expect.equal(
                HTTPStatus.resolve(
                    code: 510
                ).reason,
                "Server Error",
                "method-status.status.510-obsolete"
            )

            try Expect.equal(
                HTTPStatus.resolve(
                    code: 499
                ).reason,
                "Client Error",
                "method-status.status.unknown-client"
            )
        }
    }
}
