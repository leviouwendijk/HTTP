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
            var cursor = cursor
            let start = cursor.mark()

            guard let version = Self.component(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected HTTP version",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            guard Self.space(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected space after HTTP version",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            guard let statusCode = Self.component(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected HTTP status code",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            guard !cursor.isEOF else {
                return .success(
                    Output(
                        version: version,
                        statusCode: statusCode,
                        reasonPhrase: nil
                    ),
                    cursor
                )
            }

            guard Self.space(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected space before HTTP reason phrase",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            let reasonStart = cursor.mark()

            cursor.advance {
                _ in true
            }

            let reasonPhrase = cursor.slice(
                from: reasonStart
            )

            return .success(
                Output(
                    version: version,
                    statusCode: statusCode,
                    reasonPhrase: reasonPhrase
                ),
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

        private static func component(
            from cursor: inout Cursor
        ) -> String? {
            let start = cursor.mark()

            cursor.advance {
                !$0.isWhitespace
            }

            guard cursor.index != start else {
                return nil
            }

            return cursor.slice(
                from: start
            )
        }

        private static func space(
            from cursor: inout Cursor
        ) -> Bool {
            guard cursor.peek() == " " else {
                return false
            }

            cursor.advance()

            return true
        }
    }
}
