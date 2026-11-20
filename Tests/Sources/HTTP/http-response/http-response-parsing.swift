import Foundation

public extension HTTPResponse {
    struct Parsed: Sendable, Equatable {
        public let statusLineSource: String
        public let statusLine: HTTPGrammar.StatusLine.Output
        public let headerFields: [HTTPGrammar.HeaderField.Output]
        public let body: String

        public init(
            statusLineSource: String,
            statusLine: HTTPGrammar.StatusLine.Output,
            headerFields: [HTTPGrammar.HeaderField.Output],
            body: String
        ) {
            self.statusLineSource = statusLineSource
            self.statusLine = statusLine
            self.headerFields = headerFields
            self.body = body
        }
    }

    struct Parser: Sendable {
        public let maximumHeaderBytes: Int
        public let maximumHeaderLineBytes: Int
        public let maximumHeaderCount: Int

        public init(
            maximumHeaderBytes: Int = HTTPHeaderPolicy.response.default.maximumHeaderBytes,
            maximumHeaderLineBytes: Int = HTTPHeaderPolicy.response.default.maximumHeaderLineBytes,
            maximumHeaderCount: Int = HTTPHeaderPolicy.response.default.maximumHeaderCount
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
                throw HTTPParsingError.incompleteResponse
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
                let statusLineSource = headLines.first,
                !statusLineSource.isEmpty
            else {
                throw HTTPParsingError.incompleteResponse
            }

            guard let statusLine = HTTPGrammar.StatusLine.parse(
                statusLineSource
            ) else {
                throw HTTPParsingError.invalidStatusLine(
                    statusLineSource
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
                statusLineSource: statusLineSource,
                statusLine: statusLine,
                headerFields: headerFields,
                body: body
            )
        }
    }

    init(
        parsing raw: String,
        policies: HTTPResponsePolicies = HTTPPolicies.response.default
    ) throws {
        let parsed = try Parser(
            maximumHeaderBytes: policies.headers.maximumHeaderBytes,
            maximumHeaderLineBytes: policies.headers.maximumHeaderLineBytes,
            maximumHeaderCount: policies.headers.maximumHeaderCount
        ).parse(
            raw
        )

        self = try Validator(
            policies: policies
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
