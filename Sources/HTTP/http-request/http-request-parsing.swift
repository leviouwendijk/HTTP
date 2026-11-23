import Foundation

public extension HTTPRequest {
    struct Parsed: Sendable, Equatable {
        public let requestLineSource: String
        public let requestLine: HTTPGrammar.RequestLine.Output
        public let headerFields: [HTTPGrammar.HeaderField.Output]
        public let bodyData: Data

        public var body: String {
            String(
                decoding: bodyData,
                as: UTF8.self
            )
        }

        public init(
            requestLineSource: String,
            requestLine: HTTPGrammar.RequestLine.Output,
            headerFields: [HTTPGrammar.HeaderField.Output],
            bodyData: Data
        ) {
            self.requestLineSource = requestLineSource
            self.requestLine = requestLine
            self.headerFields = headerFields
            self.bodyData = bodyData
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
            try parse(
                Data(
                    raw.utf8
                )
            )
        }

        /// Parses a complete request. The head must be UTF-8; the body is kept as bytes.
        public func parse(
            _ raw: Data
        ) throws -> Parsed {
            guard let separatorRange = raw.range(
                of: Data(
                    HTTPConstants.crlfCrLf.utf8
                )
            ) else {
                throw HTTPParsingError.incompleteRequest
            }

            guard separatorRange.lowerBound - raw.startIndex <= maximumHeaderBytes else {
                throw HTTPParsingError.headerSectionTooLarge(
                    maximumBytes: maximumHeaderBytes
                )
            }

            guard let head = String(
                data: raw[raw.startIndex..<separatorRange.lowerBound],
                encoding: .utf8
            ) else {
                throw HTTPParsingError.malformedHeaders
            }

            let bodyData = Data(
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
                // obs-fold (RFC 9112 §5.2): a line starting with whitespace continues
                // the previous field. Rejected rather than folded or read as a new field.
                if let first = line.unicodeScalars.first,
                   first == " " || first == "\t" {
                    throw HTTPParsingError.malformedHeaders
                }

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
                requestLineSource: requestLineSource,
                requestLine: requestLine,
                headerFields: headerFields,
                bodyData: bodyData
            )
        }
    }

    init(
        parsing raw: String,
        policies: HTTPRequestPolicies = HTTPPolicies.request.default
    ) throws {
        try self.init(
            parsing: Data(
                raw.utf8
            ),
            policies: policies
        )
    }

    init(
        parsing raw: Data,
        policies: HTTPRequestPolicies = HTTPPolicies.request.default
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
