import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpQueryMethodSemanticsRegressionFlow = TestFlow(
        "http.query-method-semantics.regression",
        title: "QUERY fields and generic request semantics follow RFC 10008",
        tags: [
            "http",
            "query",
            "headers",
            "content-type",
            "regression",
        ]
    ) {
        Step("standard discovery and resource fields round-trip") {
            var headers = HTTPHeaders()

            headers.allow = [
                "GET",
                "QUERY",
                "OPTIONS",
            ]
            headers.accept = "application/json"
            headers.location = "/queries/123"
            headers.contentLocation = "/results/123"

            try Expect.equal(
                headers.get(
                    "Allow"
                ),
                "GET, QUERY, OPTIONS",
                "query-semantics.allow.raw"
            )

            try Expect.equal(
                headers.allow,
                [
                    "GET",
                    "QUERY",
                    "OPTIONS",
                ],
                "query-semantics.allow.typed"
            )

            try Expect.equal(
                headers.allowedMethods,
                [
                    .get,
                    .query,
                    .options,
                ],
                "query-semantics.allow.methods"
            )

            try Expect.equal(
                headers.accept,
                "application/json",
                "query-semantics.accept"
            )

            try Expect.equal(
                headers.location,
                "/queries/123",
                "query-semantics.location"
            )

            try Expect.equal(
                headers.contentLocation,
                "/results/123",
                "query-semantics.content-location"
            )
        }

        Step("Accept-Query parses Structured Fields media ranges") {
            guard let value = HTTPAcceptQuery(
                rawValue:
                    "application/sql;charset=utf-8, \"application/sparql-query\""
            ) else {
                throw HTTPQueryMethodSemanticsTestError.invalidAcceptQuery
            }

            try Expect.equal(
                value.mediaRanges.count,
                2,
                "query-semantics.accept-query.count"
            )

            try Expect.equal(
                value.mediaRanges[0].value,
                "application/sql",
                "query-semantics.accept-query.first"
            )

            try Expect.equal(
                value.mediaRanges[0].parameters.count,
                1,
                "query-semantics.accept-query.parameters"
            )

            try Expect.equal(
                value.mediaRanges[0].parameters[0].name,
                "charset",
                "query-semantics.accept-query.parameter-name"
            )

            try Expect.equal(
                value.mediaRanges[0].parameters[0].value,
                "utf-8",
                "query-semantics.accept-query.parameter-value"
            )
        }

        Step("Accept-Query serializes and round-trips through HTTPHeaders") {
            guard let value = HTTPAcceptQuery(
                rawValue:
                    "application/sql;charset=utf-8, application/sparql-query"
            ) else {
                throw HTTPQueryMethodSemanticsTestError.invalidAcceptQuery
            }

            var headers = HTTPHeaders()
            headers.acceptQuery = value

            try Expect.equal(
                headers.get(
                    "Accept-Query"
                ),
                "\"application/sql\";charset=\"utf-8\", \"application/sparql-query\"",
                "query-semantics.accept-query.serialized"
            )

            try Expect.equal(
                headers.acceptQuery,
                value,
                "query-semantics.accept-query.round-trip"
            )
        }

        Step("Accept-Query preserves multiple field lines as one list") {
            let headers = HTTPHeaders(
                [
                    (
                        "Accept-Query",
                        "application/sql"
                    ),
                    (
                        "accept-query",
                        "\"application/sparql-query\""
                    ),
                ]
            )

            try Expect.equal(
                headers.acceptQuery?.mediaRanges.count,
                2,
                "query-semantics.accept-query.multiline"
            )
        }

        Step("QUERY requires Content-Type") {
            let body = #"{"term":"dogs"}"#

            let raw = httpRawMessage(
                headLines: [
                    "QUERY /search HTTP/1.1",
                    "Host: localhost",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            var rejected = false

            do {
                _ = try HTTPRequest(
                    parsing: raw
                )
            } catch HTTPValidationError.missingContentType(
                let method
            ) {
                rejected = method == .query
            }

            try Expect.equal(
                rejected,
                true,
                "query-semantics.content-type.required"
            )
        }

        Step("QUERY with Content-Type remains valid") {
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
                "query-semantics.valid.method"
            )

            try Expect.equal(
                request.headers.contentType,
                "application/json",
                "query-semantics.valid.content-type"
            )
        }

        Step("other content-bearing methods do not inherit QUERY requirement") {
            let body = "value"

            let raw = httpRawMessage(
                headLines: [
                    "POST /submit HTTP/1.1",
                    "Host: localhost",
                    "Content-Length: \(body.utf8.count)",
                ],
                body: body
            )

            let request = try HTTPRequest(
                parsing: raw
            )

            try Expect.equal(
                request.method,
                .post,
                "query-semantics.post.unaffected"
            )
        }
    }
}

private enum HTTPQueryMethodSemanticsTestError: Error {
    case invalidAcceptQuery
}
