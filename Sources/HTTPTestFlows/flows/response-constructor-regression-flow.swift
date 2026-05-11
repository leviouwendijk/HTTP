import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpResponseConstructorRegressionFlow = TestFlow(
        "http.response-constructors.regression",
        title: "HTTPResponse constructors preserve content type and status behavior",
        tags: [
            "http",
            "response",
            "constructors",
            "regression"
        ]
    ) {
        Step("text response sets text/plain content type") {
            let response = HTTPResponse.text(
                "hello"
            )

            try Expect.equal(
                response.status.code,
                200,
                "response-constructors.text.status-code"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "text/plain; charset=utf-8",
                "response-constructors.text.content-type"
            )

            try Expect.equal(
                response.body,
                "hello",
                "response-constructors.text.body"
            )
        }

        Step("html response sets text/html content type") {
            let response = HTTPResponse.html(
                "<p>Hello</p>"
            )

            try Expect.equal(
                response.status.code,
                200,
                "response-constructors.html.status-code"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "text/html; charset=utf-8",
                "response-constructors.html.content-type"
            )
        }

        Step("json object response sets application/json content type") {
            let response = try HTTPResponse.json(
                [
                    "ok": .bool(true),
                    "message": .string("hello")
                ]
            )

            try Expect.equal(
                response.status.code,
                200,
                "response-constructors.json.status-code"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "application/json; charset=utf-8",
                "response-constructors.json.content-type"
            )

            try Expect.contains(
                response.body,
                #""ok""#,
                "response-constructors.json.body-ok-key"
            )
        }

        Step("pkl response sets text/pkl content type") {
            let response = HTTPResponse.pkl(
                "name = \"hello\""
            )

            try Expect.equal(
                response.status.code,
                200,
                "response-constructors.pkl.status-code"
            )

            try Expect.equal(
                response.header("Content-Type"),
                "text/pkl; charset=utf-8",
                "response-constructors.pkl.content-type"
            )
        }

        Step("unauthorized response sets WWW-Authenticate header") {
            let response = HTTPResponse.unauthorized(
                body: "Unauthorized"
            )

            try Expect.equal(
                response.status.code,
                401,
                "response-constructors.unauthorized.status-code"
            )

            try Expect.equal(
                response.header("WWW-Authenticate"),
                "Bearer realm=\"server\"",
                "response-constructors.unauthorized.www-authenticate"
            )
        }

        Step("no content response keeps body empty") {
            let response = HTTPResponse.noContent()

            try Expect.equal(
                response.status.code,
                204,
                "response-constructors.no-content.status-code"
            )

            try Expect.equal(
                response.body,
                "",
                "response-constructors.no-content.body"
            )
        }
    }
}
