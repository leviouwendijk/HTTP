import Foundation

public extension HTTPRequest {
    struct Parsed: Sendable, Equatable {
        public let requestLineSource: String
        public let requestLine: HTTPGrammar.RequestLine.Output
        public let headerFields: [HTTPGrammar.HeaderField.Output]
        public let body: String

        public init(
            requestLineSource: String,
            requestLine: HTTPGrammar.RequestLine.Output,
            headerFields: [HTTPGrammar.HeaderField.Output],
            body: String
        ) {
            self.requestLineSource = requestLineSource
            self.requestLine = requestLine
            self.headerFields = headerFields
            self.body = body
        }
    }

    struct Parser: Sendable {
        public let maximumHeaderBytes: Int
        public let maximumHeaderLineBytes: Int
        public let maximumHeaderCount: Int

        public init(
            maximumHeaderBytes: Int = HTTPHeaderPolicy.request.default.maximumHeaderBytes,
            maximumHeaderLineBytes: Int = HTTPHeaderPolicy.request.default.maximumHeaderLineBytes,
            maximumHeaderCount: Int = HTTPHeaderPolicy.request.default.maximumHeaderCount
        ) {
            self.maximumHeaderBytes = max(
                0,
                maximumHeaderBytes
            )
            self.maximumHeaderLineBytes = max(
                0,
                maximumHeaderLineBytes
            )
            self.maximumHeaderCount = max(
                0,
                maximumHeaderCount
            )
        }

        public func parse(
            _ raw: String
        ) throws -> Parsed {
            guard let separatorRange = raw.range(
                of: HTTPConstants.crlfCrLf
            ) else {
                throw HTTPParsingError.incompleteRequest
            }

            let head = String(
                raw[..<separatorRange.lowerBound]
            )

            guard head.utf8.count <= maximumHeaderBytes else {
                throw HTTPParsingError.headerSectionTooLarge(
                    maximumBytes: maximumHeaderBytes
                )
            }

            let body = String(
                raw[separatorRange.upperBound...]
            )

            let headLines = head.components(
                separatedBy: HTTPConstants.crlf
            )

            guard
                let requestLineSource = headLines.first,
                !requestLineSource.isEmpty
            else {
                throw HTTPParsingError.incompleteRequest
            }

            guard let requestLine = HTTPGrammar.RequestLine.parse(
                requestLineSource
            ) else {
                throw HTTPParsingError.invalidRequestLine(
                    requestLineSource
                )
            }

            let headerLines = headLines
                .dropFirst()
                .filter {
                    !$0.isEmpty
                }

            guard headerLines.count <= maximumHeaderCount else {
                throw HTTPParsingError.tooManyHeaders(
                    maximumCount: maximumHeaderCount
                )
            }

            var headerFields: [HTTPGrammar.HeaderField.Output] = []
            headerFields.reserveCapacity(
                headerLines.count
            )

            for line in headerLines {
                guard line.utf8.count <= maximumHeaderLineBytes else {
                    throw HTTPParsingError.headerLineTooLarge(
                        name: nil,
                        maximumBytes: maximumHeaderLineBytes
                    )
                }

                // Previous header-field syntax extraction:
                // guard let separatorIndex = line.firstIndex(
                //     of: Character(
                //         HTTPConstants.headerSeparator
                //     )
                // ) else {
                //     throw HTTPParsingError.malformedHeaders
                // }
                //
                // let name = String(
                //     line[..<separatorIndex]
                // )
                // .trimmingCharacters(
                //     in: .whitespaces
                // )
                //
                // let value = String(
                //     line[line.index(after: separatorIndex)...]
                // )
                // .trimmingCharacters(
                //     in: .whitespaces
                // )
                //
                // headers.append(
                //     HTTPHeader(
                //         name,
                //         value
                //     )
                // )

                guard let headerField = HTTPGrammar.HeaderField.parse(
                    line
                ) else {
                    throw HTTPParsingError.malformedHeaders
                }

                headerFields.append(
                    headerField
                )
            }

            return Parsed(
                requestLineSource: requestLineSource,
                requestLine: requestLine,
                headerFields: headerFields,
                body: body
            )
        }
    }

    init(
        parsing raw: String,
        headerPolicy: HTTPHeaderPolicy = HTTPHeaderPolicy.request.default,
        requestTargetPolicy: HTTPRequestTargetPolicy = .default
    ) throws {
        let parsed = try Parser(
            maximumHeaderBytes: headerPolicy.maximumHeaderBytes,
            maximumHeaderLineBytes: headerPolicy.maximumHeaderLineBytes,
            maximumHeaderCount: headerPolicy.maximumHeaderCount
        ).parse(
            raw
        )

        self = try Validator(
            headerPolicy: headerPolicy,
            requestTargetPolicy: requestTargetPolicy
        ).validate(
            parsed
        )
    }

    static func extractContentLength(
        from headerData: Data
    ) -> Int? {
        try? HTTPFraming.extractContentLength(
            from: headerData
        )
    }
}
