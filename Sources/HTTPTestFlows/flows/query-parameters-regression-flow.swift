import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpQueryParametersRegressionFlow =
        TestFlow(
            "http.query-parameters.regression",
            title:
                "HTTPQuery.Parameters parses parameter syntax without applying endpoint policy",
            tags: [
                "http",
                "query",
                "parameters",
                "parsing",
                "regression",
            ]
        ) {
            Step(
                "empty query produces an empty parameter sequence"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw: ""
                            )
                    )

                try Expect.equal(
                    parameters.raw,
                    "",
                    "query-parameters.empty.raw"
                )

                try Expect.equal(
                    parameters.items.count,
                    0,
                    "query-parameters.empty.count"
                )
            }

            Step(
                "parameter parsing retains duplicate names and order"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw:
                                    "a=1"
                                    + "&a=2"
                                    + "&b=3"
                            )
                    )

                try Expect.equal(
                    parameters.items.count,
                    3,
                    "query-parameters.duplicates.count"
                )

                try Expect.equal(
                    parameters.items[0].name.decoded,
                    "a",
                    "query-parameters.duplicates.first-name"
                )

                try Expect.equal(
                    parameters.items[0].value?.decoded,
                    "1",
                    "query-parameters.duplicates.first-value"
                )

                try Expect.equal(
                    parameters.items[1].name.decoded,
                    "a",
                    "query-parameters.duplicates.second-name"
                )

                try Expect.equal(
                    parameters.items[1].value?.decoded,
                    "2",
                    "query-parameters.duplicates.second-value"
                )

                try Expect.equal(
                    parameters.items[2].name.decoded,
                    "b",
                    "query-parameters.duplicates.third-name"
                )
            }

            Step(
                "parameter parsing distinguishes absent and empty values"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw:
                                    "flag"
                                    + "&empty="
                                    + "&=value"
                            )
                    )

                try Expect.equal(
                    parameters.items.count,
                    3,
                    "query-parameters.value-shapes.count"
                )

                try Expect.isNil(
                    parameters.items[0].value,
                    "query-parameters.value-shapes.absent"
                )

                try Expect.equal(
                    parameters.items[1].value?.raw,
                    "",
                    "query-parameters.value-shapes.empty"
                )

                try Expect.equal(
                    parameters.items[2].name.raw,
                    "",
                    "query-parameters.value-shapes.empty-name"
                )

                try Expect.equal(
                    parameters.items[2].value?.decoded,
                    "value",
                    "query-parameters.value-shapes.empty-name-value"
                )
            }

            Step(
                "parameter parsing retains empty segments"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw:
                                    "first"
                                    + "&&"
                                    + "last&"
                            )
                    )

                try Expect.equal(
                    parameters.items.count,
                    4,
                    "query-parameters.empty-segments.count"
                )

                try Expect.equal(
                    parameters.items[1].raw,
                    "",
                    "query-parameters.empty-segments.middle"
                )

                try Expect.equal(
                    parameters.items[3].raw,
                    "",
                    "query-parameters.empty-segments.trailing"
                )
            }

            Step(
                "only the first equals sign separates name and value"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw: "expression=a=b=c"
                            )
                    )

                try Expect.equal(
                    parameters.items[0].name.decoded,
                    "expression",
                    "query-parameters.equals.name"
                )

                try Expect.equal(
                    parameters.items[0].value?.decoded,
                    "a=b=c",
                    "query-parameters.equals.value"
                )
            }

            Step(
                "components retain raw and percent-decoded spellings"
            ) {
                let parameters =
                    try HTTPQuery.Parameters(
                        parsing:
                            HTTPQuery(
                                raw:
                                    "q=dog%20training"
                                    + "&literal=a+b"
                                    + "&encoded=a%26b%3Dc"
                            )
                    )

                try Expect.equal(
                    parameters.items[0].value?.raw,
                    "dog%20training",
                    "query-parameters.percent.raw"
                )

                try Expect.equal(
                    parameters.items[0].value?.decoded,
                    "dog training",
                    "query-parameters.percent.decoded"
                )

                try Expect.equal(
                    parameters.items[1].value?.decoded,
                    "a+b",
                    "query-parameters.plus-remains-plus"
                )

                try Expect.equal(
                    parameters.items[2].value?.decoded,
                    "a&b=c",
                    "query-parameters.encoded-separators"
                )
            }

            Step(
                "malformed percent encoding fails parameter interpretation"
            ) {
                try Expect.throwsError(
                    "query-parameters.invalid-percent"
                ) {
                    _ =
                        try HTTPQuery.Parameters(
                            parsing:
                                HTTPQuery(
                                    raw: "q=%ZZ"
                                )
                        )
                }
            }
        }
}
