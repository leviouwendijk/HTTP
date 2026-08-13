import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpRequestLineGrammarRegressionFlow = TestFlow(
        "http.grammar.request-line.regression",
        title: "HTTPGrammar.RequestLine parses request-line syntax without applying HTTP policy",
        tags: [
            "http",
            "grammar",
            "request-line",
            "parsing",
            "regression",
        ]
    ) {
        Step("request-line grammar extracts raw syntax components") {
            let output = HTTPGrammar.RequestLine.parse(
                "POST /auth/session HTTP/1.1"
            )

            try Expect.equal(
                output?.method,
                "POST",
                "request-line.method"
            )

            try Expect.equal(
                output?.target,
                "/auth/session",
                "request-line.target"
            )

            try Expect.equal(
                output?.version,
                "HTTP/1.1",
                "request-line.version"
            )
        }

        Step("request-line grammar preserves request target unchanged") {
            let output = HTTPGrammar.RequestLine.parse(
                "GET /search?q=dog%20training&page=2 HTTP/1.1"
            )

            try Expect.equal(
                output?.target,
                "/search?q=dog%20training&page=2",
                "request-line.target-preserved"
            )

            try Expect.equal(
                output?.requestTarget.path,
                "/search",
                "request-line.request-target.path"
            )

            try Expect.equal(
                output?.requestTarget.query,
                "q=dog%20training&page=2",
                "request-line.request-target.query"
            )
        }

        Step("request-line grammar does not apply method or version policy") {
            let output = HTTPGrammar.RequestLine.parse(
                "BREW /coffee HTTP/9.9"
            )

            try Expect.equal(
                output?.method,
                "BREW",
                "request-line.raw-method"
            )

            try Expect.equal(
                output?.version,
                "HTTP/9.9",
                "request-line.raw-version"
            )
        }

        Step("request-line grammar rejects missing component") {
            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    "GET /health"
                ),
                "request-line.missing-component"
            )
        }

        Step("request-line grammar rejects extra component") {
            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    "GET /health HTTP/1.1 extra"
                ),
                "request-line.extra-component"
            )
        }

        Step("request-line grammar rejects ambiguous whitespace") {
            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    "GET  /health HTTP/1.1"
                ),
                "request-line.double-space"
            )

            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    " GET /health HTTP/1.1"
                ),
                "request-line.leading-space"
            )

            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    "GET /health HTTP/1.1 "
                ),
                "request-line.trailing-space"
            )

            try Expect.isNil(
                HTTPGrammar.RequestLine.parse(
                    "GET\t/health HTTP/1.1"
                ),
                "request-line.tab"
            )
        }
    }
}
