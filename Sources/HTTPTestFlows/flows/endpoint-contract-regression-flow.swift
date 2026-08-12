import HTTP
import TestFlows
import Path

extension HTTPFlowSuite {
    static let httpEndpointContractRegressionFlow = TestFlow(
        "http.endpoint-contract.regression",
        title: "HTTP endpoint contracts preserve path construction and request transport semantics",
        tags: [
            "http",
            "endpoint",
            "path",
            "request",
            "typed",
            "contract",
            "regression",
        ]
    ) {
        Step("endpoint preserves raw method and path") {
            let endpoint = HTTPEndpoint(
                method: .post,
                path: "/sessions"
            )

            try Expect.equal(
                endpoint.method,
                .post,
                "endpoint-contract.raw.method"
            )

            try Expect.equal(
                endpoint.path,
                "/sessions",
                "endpoint-contract.raw.path"
            )
        }

        Step("endpoint constructs path from variadic components") {
            let endpoint = HTTPEndpoint(
                method: .post,
                "auth",
                "sessions"
            )

            try Expect.equal(
                endpoint.path,
                "/auth/sessions",
                "endpoint-contract.variadic.path"
            )
        }

        Step("endpoint constructs path from component array") {
            let endpoint = HTTPEndpoint(
                method: .get,
                components: [
                    "accounts",
                    "current",
                ]
            )

            try Expect.equal(
                endpoint.path,
                "/accounts/current",
                "endpoint-contract.array.path"
            )
        }

        Step("endpoint constructs path from StandardPath") {
            let endpoint = HTTPEndpoint(
                method: .post,
                path: StandardPath(
                    [
                        "auth",
                        "sessions",
                    ]
                )
            )

            try Expect.equal(
                endpoint.path,
                "/auth/sessions",
                "endpoint-contract.standard-path.path"
            )
        }

        Step("empty path components represent root") {
            let endpoint = HTTPEndpoint(
                method: .get,
                components: []
            )

            try Expect.equal(
                endpoint.path,
                "/",
                "endpoint-contract.root.path"
            )
        }

        Step("equivalent endpoint constructions compare equal") {
            let raw = HTTPEndpoint(
                method: .post,
                path: "/auth/sessions"
            )

            let variadic = HTTPEndpoint(
                method: .post,
                "auth",
                "sessions"
            )

            let array = HTTPEndpoint(
                method: .post,
                components: [
                    "auth",
                    "sessions",
                ]
            )

            let standard = HTTPEndpoint(
                method: .post,
                path: StandardPath(
                    [
                        "auth",
                        "sessions",
                    ]
                )
            )

            try Expect.equal(
                raw,
                variadic,
                "endpoint-contract.equality.variadic"
            )

            try Expect.equal(
                raw,
                array,
                "endpoint-contract.equality.array"
            )

            try Expect.equal(
                raw,
                standard,
                "endpoint-contract.equality.standard-path"
            )
        }

        Step("endpoint contracts are hashable values") {
            let first = HTTPEndpoint(
                method: .get,
                "account"
            )

            let second = HTTPEndpoint(
                method: .get,
                path: "/account"
            )

            let third = HTTPEndpoint(
                method: .post,
                "account"
            )

            let endpoints: Set<HTTPEndpoint> = [
                first,
                second,
                third,
            ]

            try Expect.equal(
                endpoints.count,
                2,
                "endpoint-contract.hashable"
            )
        }

        Step("endpoint request exposes its declared endpoint") {
            try Expect.equal(
                HTTPEndpointContractRequest.endpoint.method,
                .post,
                "endpoint-contract.request.method"
            )

            try Expect.equal(
                HTTPEndpointContractRequest.endpoint.path,
                "/models/create",
                "endpoint-contract.request.path"
            )
        }

        Step("endpoint metadata does not alter HTTPRequestable parsing") {
            let request = HTTPRequest(
                method: .post,
                path: "/some-other-path",
                headers: [
                    "Content-Type": "application/json",
                ],
                body: """
                {
                    "value": "parsed"
                }
                """
            )

            let parsed = try HTTPEndpointContractRequest.parse(
                request
            )

            try Expect.equal(
                parsed.value,
                "parsed",
                "endpoint-contract.request.parse"
            )
        }
    }
}

private struct HTTPEndpointContractRequest:
    Decodable,
    Sendable,
    HTTPReachable
{
    static let endpoint = HTTPEndpoint(
        method: .post,
        "models",
        "create"
    )

    let value: String
}
