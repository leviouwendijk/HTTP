import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpRequestTargetGrammarRegressionFlow = TestFlow(
        "http.grammar.request-target.regression",
        title: "HTTPGrammar.RequestTarget retains request-target structure without applying HTTP policy",
        tags: [
            "http",
            "grammar",
            "request-target",
            "parsing",
            "regression",
        ]
    ) {
        Step("request-target grammar retains an ordinary path") {
            let output = HTTPGrammar.RequestTarget.parse(
                "/auth/session"
            )

            try Expect.equal(
                output?.raw,
                "/auth/session",
                "request-target.raw"
            )

            try Expect.equal(
                output?.path,
                "/auth/session",
                "request-target.path"
            )

            try Expect.isNil(
                output?.query,
                "request-target.query-absent"
            )
        }

        Step("request-target grammar separates query while preserving raw target") {
            let output = HTTPGrammar.RequestTarget.parse(
                "/search?q=dog%20training&page=2"
            )

            try Expect.equal(
                output?.raw,
                "/search?q=dog%20training&page=2",
                "request-target.query.raw"
            )

            try Expect.equal(
                output?.path,
                "/search",
                "request-target.query.path"
            )

            try Expect.equal(
                output?.query,
                "q=dog%20training&page=2",
                "request-target.query.value"
            )
        }

        Step("request-target grammar splits only the first query separator") {
            let output = HTTPGrammar.RequestTarget.parse(
                "/search?first?second"
            )

            try Expect.equal(
                output?.path,
                "/search",
                "request-target.first-separator.path"
            )

            try Expect.equal(
                output?.query,
                "first?second",
                "request-target.first-separator.query"
            )
        }

        Step("request-target grammar retains an explicitly empty query") {
            let output = HTTPGrammar.RequestTarget.parse(
                "/search?"
            )

            try Expect.equal(
                output?.path,
                "/search",
                "request-target.empty-query.path"
            )

            try Expect.equal(
                output?.query,
                "",
                "request-target.empty-query.value"
            )
        }

        Step("request-target grammar does not apply origin-form or ambiguity policy") {
            let asterisk = HTTPGrammar.RequestTarget.parse(
                "*"
            )

            let authority = HTTPGrammar.RequestTarget.parse(
                "example.com:443"
            )

            let ambiguous = HTTPGrammar.RequestTarget.parse(
                "/a//b"
            )

            try Expect.equal(
                asterisk?.raw,
                "*",
                "request-target.policy.asterisk"
            )

            try Expect.equal(
                authority?.raw,
                "example.com:443",
                "request-target.policy.authority"
            )

            try Expect.equal(
                ambiguous?.raw,
                "/a//b",
                "request-target.policy.ambiguous"
            )
        }

        Step("standalone request-target grammar requires exactly one complete token") {
            try Expect.isNil(
                HTTPGrammar.RequestTarget.parse(
                    ""
                ),
                "request-target.empty"
            )

            try Expect.isNil(
                HTTPGrammar.RequestTarget.parse(
                    "/first second"
                ),
                "request-target.space"
            )

            try Expect.isNil(
                HTTPGrammar.RequestTarget.parse(
                    "/first\tsecond"
                ),
                "request-target.tab"
            )
        }
    }
}
