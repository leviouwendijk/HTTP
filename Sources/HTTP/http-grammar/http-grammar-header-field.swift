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
            var cursor = cursor
            let start = cursor.mark()
            let nameStart = cursor.mark()

            cursor.advance {
                $0 != ":"
            }

            guard cursor.peek() == ":" else {
                return .failure(
                    Diagnostic(
                        "expected HTTP header separator",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            let name = cursor.slice(
                from: nameStart
            )

            cursor.advance()

            let valueStart = cursor.mark()

            cursor.advance {
                _ in true
            }

            let value = cursor.slice(
                from: valueStart
            )

            return .success(
                Output(
                    name: name,
                    value: value
                ),
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
