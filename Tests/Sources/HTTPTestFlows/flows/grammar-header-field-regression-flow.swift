import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpHeaderFieldGrammarRegressionFlow = TestFlow(
        "http.grammar.header-field.regression",
        title: "HTTPGrammar.HeaderField retains header syntax without applying HTTP policy",
        tags: [
            "http",
            "grammar",
            "headers",
            "parsing",
            "regression",
        ]
    ) {
        Step("header-field grammar extracts name and value") {
            let output = HTTPGrammar.HeaderField.parse(
                "Content-Type: application/json"
            )

            try Expect.equal(
                output?.name,
                "Content-Type",
                "header-field.name"
            )

            try Expect.equal(
                output?.value,
                " application/json",
                "header-field.value"
            )
        }

        Step("header-field grammar preserves ordinary whitespace") {
            let output = HTTPGrammar.HeaderField.parse(
                " Content-Type :   text/plain   "
            )

            try Expect.equal(
                output?.name,
                " Content-Type ",
                "header-field.raw-name"
            )

            try Expect.equal(
                output?.value,
                "   text/plain   ",
                "header-field.raw-value"
            )
        }

        Step("header-field grammar preserves colons inside value") {
            let output = HTTPGrammar.HeaderField.parse(
                "Location: https://example.test/a:b?token=c:d"
            )

            try Expect.equal(
                output?.name,
                "Location",
                "header-field.colon.name"
            )

            try Expect.equal(
                output?.value,
                " https://example.test/a:b?token=c:d",
                "header-field.colon.value"
            )
        }

        Step("header-field grammar does not apply field-name policy") {
            let output = HTTPGrammar.HeaderField.parse(
                "Bad Header Name: value"
            )

            try Expect.equal(
                output?.name,
                "Bad Header Name",
                "header-field.raw-invalid-name"
            )
        }

        Step("header-field grammar accepts empty raw field name for later validation") {
            let output = HTTPGrammar.HeaderField.parse(
                ": value"
            )

            try Expect.equal(
                output?.name,
                "",
                "header-field.empty-name"
            )

            try Expect.equal(
                output?.value,
                " value",
                "header-field.empty-name-value"
            )
        }

        Step("header-field grammar accepts empty value") {
            let output = HTTPGrammar.HeaderField.parse(
                "X-Empty:"
            )

            try Expect.equal(
                output?.name,
                "X-Empty",
                "header-field.empty-value-name"
            )

            try Expect.equal(
                output?.value,
                "",
                "header-field.empty-value"
            )
        }

        Step("header-field grammar requires separator") {
            try Expect.isNil(
                HTTPGrammar.HeaderField.parse(
                    "Content-Type text/plain"
                ),
                "header-field.missing-separator"
            )
        }
    }
}
