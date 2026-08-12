import Parsing

public extension HTTPGrammar {
    struct RequestLine: Parser {
        public struct Output: Sendable, Equatable {
            public let method: String
            public let target: String
            public let version: String

            public init(
                method: String,
                target: String,
                version: String
            ) {
                self.method = method
                self.target = target
                self.version = version
            }
        }

        public init() {}

        public func parse(
            _ cursor: Cursor
        ) -> ParseResult<Output> {
            var cursor = cursor
            let start = cursor.mark()

            guard let method = Self.component(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected HTTP method",
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
                        "expected space after HTTP method",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            guard let target = Self.component(
                from: &cursor
            ) else {
                return .failure(
                    Diagnostic(
                        "expected HTTP request target",
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
                        "expected space after HTTP request target",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

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

            guard cursor.isEOF else {
                return .failure(
                    Diagnostic(
                        "unexpected request-line input",
                        range: cursor.range(
                            from: start
                        )
                    )
                )
            }

            return .success(
                Output(
                    method: method,
                    target: target,
                    version: version
                ),
                cursor
            )
        }

        public static func parse(
            _ input: String
        ) -> Output? {
            switch RequestLine().parse(
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
