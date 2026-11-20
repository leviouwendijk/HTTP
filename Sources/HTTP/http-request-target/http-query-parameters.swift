import Foundation
import Parsing

public extension HTTPQuery {
    struct Parameters:
        Sendable,
        Equatable
    {
        public let query: HTTPQuery
        public let items: [Item]

        public var raw: String {
            query.raw
        }

        public init(
            parsing query: HTTPQuery
        ) throws {
            self =
                try Parser.parse(
                    query
                )
        }

        init(
            query: HTTPQuery,
            items: [Item]
        ) {
            self.query = query
            self.items = items
        }

        public struct Item:
            Sendable,
            Equatable
        {
            public let raw: String
            public let name: Component
            public let value: Component?

            init(
                raw: String,
                name: Component,
                value: Component?
            ) {
                self.raw = raw
                self.name = name
                self.value = value
            }
        }

        public struct Component:
            Sendable,
            Equatable
        {
            public let raw: String
            public let decoded: String

            init(
                raw: String,
                decoded: String
            ) {
                self.raw = raw
                self.decoded = decoded
            }
        }

        public enum ParsingError:
            Error,
            LocalizedError,
            Sendable,
            Equatable
        {
            case invalidPercentEncoding(String)

            public var errorDescription: String? {
                switch self {
                case .invalidPercentEncoding(
                    let raw
                ):
                    return
                        "Invalid percent encoding in HTTP query component '\(raw)'"
                }
            }
        }

        struct Parser:
            Parsing.Parser
        {
            typealias Output =
                HTTPQuery.Parameters

            func parse(
                _ cursor: Cursor
            ) -> ParseResult<Output> {
                var cursor = cursor
                let start = cursor.mark()

                do {
                    let output =
                        try Self.parse(
                            &cursor
                        )

                    return .success(
                        output,
                        cursor
                    )
                } catch let error as ParsingError {
                    return .failure(
                        Diagnostic(
                            error.localizedDescription,
                            range:
                                cursor.range(
                                    from: start
                                )
                        )
                    )
                } catch {
                    return .failure(
                        Diagnostic(
                            "HTTP query parameter parsing failed: \(error.localizedDescription)",
                            range:
                                cursor.range(
                                    from: start
                                )
                        )
                    )
                }
            }

            static func parse(
                _ query: HTTPQuery
            ) throws -> Output {
                var cursor =
                    Cursor(
                        query.raw
                    )

                return try parse(
                    &cursor
                )
            }

            private static func parse(
                _ cursor: inout Cursor
            ) throws -> Output {
                let queryStart =
                    cursor.mark()

                guard !cursor.isEOF else {
                    return Output(
                        query:
                            HTTPQuery(
                                raw: ""
                            ),
                        items: []
                    )
                }

                var items: [Item] = []

                while true {
                    let itemStart =
                        cursor.mark()

                    cursor.advance {
                        $0 != "&"
                    }

                    let rawItem =
                        cursor.slice(
                            from: itemStart
                        )

                    items.append(
                        try item(
                            rawItem
                        )
                    )

                    guard !cursor.isEOF else {
                        break
                    }

                    cursor.advance()

                    if cursor.isEOF {
                        items.append(
                            try item(
                                ""
                            )
                        )

                        break
                    }
                }

                let raw =
                    cursor.slice(
                        from: queryStart
                    )

                return Output(
                    query:
                        HTTPQuery(
                            raw: raw
                        ),
                    items: items
                )
            }

            private static func item(
                _ raw: String
            ) throws -> Item {
                guard let separator =
                    raw.firstIndex(
                        of: "="
                    )
                else {
                    return Item(
                        raw: raw,
                        name:
                            try component(
                                raw
                            ),
                        value: nil
                    )
                }

                let name =
                    String(
                        raw[..<separator]
                    )

                let valueStart =
                    raw.index(
                        after: separator
                    )

                let value =
                    String(
                        raw[valueStart...]
                    )

                return Item(
                    raw: raw,
                    name:
                        try component(
                            name
                        ),
                    value:
                        try component(
                            value
                        )
                )
            }

            private static func component(
                _ raw: String
            ) throws -> Component {
                guard let decoded =
                    raw.removingPercentEncoding
                else {
                    throw ParsingError
                        .invalidPercentEncoding(
                            raw
                        )
                }

                return Component(
                    raw: raw,
                    decoded: decoded
                )
            }
        }
    }
}
