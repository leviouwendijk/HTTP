import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpStatusLineGrammarRegressionFlow = TestFlow(
        "http.grammar.status-line.regression",
        title: "HTTPGrammar.StatusLine retains response syntax without applying HTTP policy",
        tags: [
            "http",
            "grammar",
            "status-line",
            "parsing",
            "regression",
        ]
    ) {
        Step("status-line grammar extracts raw components") {
            let output = HTTPGrammar.StatusLine.parse(
                "HTTP/1.1 200 OK"
            )

            try Expect.equal(
                output?.version,
                "HTTP/1.1",
                "status-line.version"
            )

            try Expect.equal(
                output?.statusCode,
                "200",
                "status-line.code"
            )

            try Expect.equal(
                output?.reasonPhrase,
                "OK",
                "status-line.reason"
            )
        }

        Step("status-line grammar accepts missing reason phrase") {
            let output = HTTPGrammar.StatusLine.parse(
                "HTTP/1.1 204"
            )

            try Expect.equal(
                output?.statusCode,
                "204",
                "status-line.reason-optional.code"
            )

            try Expect.isNil(
                output?.reasonPhrase,
                "status-line.reason-optional.reason"
            )
        }

        Step("status-line grammar does not apply version or status policy") {
            let output = HTTPGrammar.StatusLine.parse(
                "HTTP/9.9 nope Whatever"
            )

            try Expect.equal(
                output?.version,
                "HTTP/9.9",
                "status-line.raw-version"
            )

            try Expect.equal(
                output?.statusCode,
                "nope",
                "status-line.raw-code"
            )
        }

        Step("status-line grammar preserves reason phrase contents") {
            let output = HTTPGrammar.StatusLine.parse(
                "HTTP/1.1 500 Internal Server Error"
            )

            try Expect.equal(
                output?.reasonPhrase,
                "Internal Server Error",
                "status-line.reason-preserved"
            )
        }

        Step("status-line grammar rejects missing status code") {
            try Expect.isNil(
                HTTPGrammar.StatusLine.parse(
                    "HTTP/1.1"
                ),
                "status-line.missing-code"
            )
        }

        Step("status-line grammar rejects ambiguous primary spacing") {
            try Expect.isNil(
                HTTPGrammar.StatusLine.parse(
                    "HTTP/1.1  200 OK"
                ),
                "status-line.double-space"
            )

            try Expect.isNil(
                HTTPGrammar.StatusLine.parse(
                    "HTTP/1.1\t200 OK"
                ),
                "status-line.tab-separator"
            )

            try Expect.isNil(
                HTTPGrammar.StatusLine.parse(
                    " HTTP/1.1 200 OK"
                ),
                "status-line.leading-space"
            )
        }
    }
}
