import Parsing

public extension HTTPGrammar {
    struct RequestLine: Parser {
        public struct Output: Sendable, Equatable {
            public let method: String
            public let requestTarget: HTTPGrammar.RequestTarget.Output
            public let version: String

            public var target: String {
                requestTarget.raw
            }

            // Previous request-target representation:
            // public let target: String

            public init(
                method: String,
                target: String,
                version: String
            ) {
                self.init(
                    method: method,
                    requestTarget: HTTPGrammar.RequestTarget.Output(
                        raw: target
                    ),
                    version: version
                )
            }

            public init(
                method: String,
                requestTarget: HTTPGrammar.RequestTarget.Output,
                version: String
            ) {
                self.method = method
                self.requestTarget = requestTarget
                self.version = version
            }
        }

        public init() {}

        public func parse(
            _ cursor: Cursor
        ) -> ParseResult<Output> {
            let method = TakeWhile(
                where: {
                    !$0.isWhitespace
                },
                minimumCount: 1,
                expectation: "HTTP method"
            )

            let methodSpace = Char(
                where: {
                    $0 == " "
                },
                want: "space after HTTP method"
            )
            .map {
                _ in ()
            }

            let requestTargetSpace = Char(
                where: {
                    $0 == " "
                },
                want: "space after HTTP request target"
            )
            .map {
                _ in ()
            }

            let version = TakeWhile(
                where: {
                    !$0.isWhitespace
                },
                minimumCount: 1,
                expectation: "HTTP version"
            )

            let parser = method
                .skip(
                    methodSpace
                )
                .then(
                    HTTPGrammar.RequestTarget()
                )
                .skip(
                    requestTargetSpace
                )
                .then(
                    version
                )
                .skip(
                    EndOfInput()
                )
                .map {
                    parsed in

                    let (
                        (
                            method,
                            requestTarget
                        ),
                        version
                    ) = parsed

                    return Output(
                        method: method,
                        requestTarget: requestTarget,
                        version: version
                    )
                }

            return parser.parse(
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
