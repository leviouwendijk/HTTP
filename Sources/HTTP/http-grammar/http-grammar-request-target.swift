import Parsing

public extension HTTPGrammar {
    struct RequestTarget: Parser {
        public struct Output: Sendable, Equatable {
            public let raw: String
            public let path: String
            public let query: String?

            public init(
                raw: String
            ) {
                self.raw = raw

                guard let queryIndex = raw.firstIndex(
                    of: "?"
                ) else {
                    self.path = raw
                    self.query = nil
                    return
                }

                self.path = String(
                    raw[..<queryIndex]
                )

                self.query = String(
                    raw[
                        raw.index(
                            after: queryIndex
                        )...
                    ]
                )
            }
        }

        public init() {}

        public func parse(
            _ cursor: Cursor
        ) -> ParseResult<Output> {
            let parser = TakeWhile(
                where: {
                    !$0.isWhitespace
                },
                minimumCount: 1,
                expectation: "HTTP request target"
            )

            switch parser.parse(
                cursor
            ) {
            case .failure(let diagnostic):
                return .failure(
                    diagnostic
                )

            case .success(let raw, let next):
                return .success(
                    Output(
                        raw: raw
                    ),
                    next
                )
            }
        }

        public static func parse(
            _ input: String
        ) -> Output? {
            let parser = RequestTarget()
                .skip(
                    EndOfInput()
                )

            switch parser.parse(
                Cursor(
                    input
                )
            ) {
            case .success(let output, _):
                return output

            case .failure:
                return nil
            }
        }
    }
}
