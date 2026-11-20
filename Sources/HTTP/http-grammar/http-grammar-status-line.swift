import Parsing

public extension HTTPGrammar {
    struct StatusLine: Parser {
        public struct Output: Sendable, Equatable {
            public let version: String
            public let statusCode: String
            public let reasonPhrase: String?

            public init(
                version: String,
                statusCode: String,
                reasonPhrase: String?
            ) {
                self.version = version
                self.statusCode = statusCode
                self.reasonPhrase = reasonPhrase
            }
        }

        public init() {}

        public func parse(
            _ cursor: Cursor
        ) -> ParseResult<Output> {
            let version = TakeWhile(
                where: {
                    !$0.isWhitespace
                },
                minimumCount: 1,
                expectation: "HTTP version"
            )

            let versionSpace = Char(
                where: {
                    $0 == " "
                },
                want: "space after HTTP version"
            )
            .map {
                _ in ()
            }

            let statusCode = TakeWhile(
                where: {
                    !$0.isWhitespace
                },
                minimumCount: 1,
                expectation: "HTTP status code"
            )

            let reasonPhrase = Char(
                where: {
                    $0 == " "
                },
                want: "space before HTTP reason phrase"
            )
            .map {
                _ in ()
            }
            .keep(
                Remainder()
            )
            .optional()

            let parser = version
                .skip(
                    versionSpace
                )
                .then(
                    statusCode
                )
                .then(
                    reasonPhrase
                )
                .skip(
                    EndOfInput()
                )
                .map {
                    parsed in

                    let (
                        (
                            version,
                            statusCode
                        ),
                        reasonPhrase
                    ) = parsed

                    return Output(
                        version: version,
                        statusCode: statusCode,
                        reasonPhrase: reasonPhrase
                    )
                }

            return parser.parse(
                cursor
            )
        }

        public static func parse(
            _ input: String
        ) -> Output? {
            switch StatusLine().parse(
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

        // private static func component(
        //     from cursor: inout Cursor
        // ) -> String? {
        //     let start = cursor.mark()

        //     cursor.advance {
        //         !$0.isWhitespace
        //     }

        //     guard cursor.index != start else {
        //         return nil
        //     }

        //     return cursor.slice(
        //         from: start
        //     )
        // }

        // private static func space(
        //     from cursor: inout Cursor
        // ) -> Bool {
        //     guard cursor.peek() == " " else {
        //         return false
        //     }

        //     cursor.advance()

        //     return true
        // }
    }
}
