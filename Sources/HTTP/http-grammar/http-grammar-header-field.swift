import Parsing

public extension HTTPGrammar {
    struct HeaderField: Parser {
        public struct Output: Sendable, Equatable {
            public let name: String
            public let value: String

            public init(
                name: String,
                value: String
            ) {
                self.name = name
                self.value = value
            }
        }

        public init() {}

        public func parse(
            _ cursor: Cursor
        ) -> ParseResult<Output> {
            let name = TakeWhile(
                where: {
                    $0 != ":"
                }
            )

            let separator = Char(
                where: {
                    $0 == ":"
                },
                want: "HTTP header separator"
            )
            .map {
                _ in ()
            }

            let parser = name
                .skip(
                    separator
                )
                .then(
                    Remainder()
                )
                .map {
                    parsed in

                    Output(
                        name: parsed.0,
                        value: parsed.1
                    )
                }

            return parser.parse(
                cursor
            )
        }

        public static func parse(
            _ input: String
        ) -> Output? {
            switch HeaderField().parse(
                Cursor(
                    input
                )
            ) {
            case .success(let output, _):
                output

            case .failure:
                nil
            }
        }
    }
}
