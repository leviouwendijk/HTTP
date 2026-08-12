import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpTypedTransportRegressionFlow = TestFlow(
        "http.typed-transport.regression",
        title: "Typed HTTP request and response models preserve transport behavior",
        tags: [
            "http",
            "request",
            "response",
            "typed",
            "transport",
            "regression",
        ]
    ) {
        Step("Decodable HTTPRequestable parses request body") {
            let request = HTTPRequest(
                method: .post,
                path: "/typed",
                headers: [
                    "Content-Type": "application/json",
                ],
                body: """
                {
                    "requestId": "request-123",
                    "count": 3
                }
                """
            )

            let parsed = try HTTPTransportRequest.parse(
                request
            )

            try Expect.equal(
                parsed.requestId,
                "request-123",
                "typed-transport.request.request-id"
            )

            try Expect.equal(
                parsed.count,
                3,
                "typed-transport.request.count"
            )
        }

        Step("HTTPRequestable supports custom non-body parsing") {
            let request = HTTPRequest(
                method: .get,
                path: "/typed",
                headers: [
                    "X-Transport-Value": "custom-value",
                ]
            )

            let parsed = try HTTPTransportHeaderRequest.parse(
                request
            )

            try Expect.equal(
                parsed.value,
                "custom-value",
                "typed-transport.request.custom"
            )
        }

        Step("Encodable HTTPRespondable creates JSON response") {
            let response = try HTTPTransportResponse(
                responseValue: "response-123",
                accepted: true
            ).response()

            try Expect.equal(
                response.status.code,
                200,
                "typed-transport.response.status"
            )

            try Expect.equal(
                response.header(
                    "Content-Type"
                ),
                "application/json; charset=utf-8",
                "typed-transport.response.content-type"
            )

            try Expect.contains(
                response.body,
                #""responseValue":"response-123""#,
                "typed-transport.response.value"
            )

            try Expect.contains(
                response.body,
                #""accepted":true"#,
                "typed-transport.response.accepted"
            )
        }

        Step("HTTPRespondable preserves explicit status") {
            let response = try HTTPTransportResponse(
                responseValue: "invalid",
                accepted: false
            ).response(
                status: .badRequest
            )

            try Expect.equal(
                response.status.code,
                400,
                "typed-transport.response.explicit-status"
            )
        }

        Step("HTTPRespondable supports custom response construction") {
            let response = try HTTPTransportCustomResponse(
                body: "custom-response"
            ).response()

            try Expect.equal(
                response.status.code,
                200,
                "typed-transport.response.custom-status"
            )

            try Expect.equal(
                response.body,
                "custom-response",
                "typed-transport.response.custom-body"
            )
        }
    }
}

private struct HTTPTransportRequest:
    Decodable,
    Sendable,
    HTTPRequestable
{
    let requestId: String
    let count: Int
}

private struct HTTPTransportHeaderRequest:
    Sendable,
    HTTPRequestable
{
    let value: String

    static func parse(
        _ request: HTTPRequest
    ) throws -> Self {
        guard let value = request.header(
            "X-Transport-Value"
        ) else {
            throw HTTPTransportError.missingValue
        }

        return Self(
            value: value
        )
    }
}

private struct HTTPTransportResponse:
    Encodable,
    Sendable,
    HTTPRespondable
{
    let responseValue: String
    let accepted: Bool
}

private struct HTTPTransportCustomResponse:
    Sendable,
    HTTPRespondable
{
    let body: String

    func response(
        status: HTTPStatus
    ) throws -> HTTPResponse {
        HTTPResponse(
            status: status,
            body: body
        )
    }
}

private enum HTTPTransportError: Error {
    case missingValue
}
