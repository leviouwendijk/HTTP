import Foundation

public enum HTTPBodySize {
    public static func bytes(
        _ value: Int
    ) -> Int {
        max(0, value)
    }

    public static func kb(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_000
        )
    }

    public static func mb(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_000_000
        )
    }

    public static func gb(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_000_000_000
        )
    }

    public static func kib(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_024
        )
    }

    public static func mib(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_024 * 1_024
        )
    }

    public static func gib(
        _ value: Int
    ) -> Int {
        multiply(
            value,
            by: 1_024 * 1_024 * 1_024
        )
    }

    private static func multiply(
        _ value: Int,
        by multiplier: Int
    ) -> Int {
        guard value > 0 else {
            return 0
        }

        guard value <= Int.max / multiplier else {
            return Int.max
        }

        return value * multiplier
    }
}

public extension Int {
    var bytes: Int {
        HTTPBodySize.bytes(self)
    }

    var kb: Int {
        HTTPBodySize.kb(self)
    }

    var mb: Int {
        HTTPBodySize.mb(self)
    }

    var gb: Int {
        HTTPBodySize.gb(self)
    }

    var kib: Int {
        HTTPBodySize.kib(self)
    }

    var mib: Int {
        HTTPBodySize.mib(self)
    }

    var gib: Int {
        HTTPBodySize.gib(self)
    }
}

public struct HTTPContentPolicy: Sendable, Hashable, Equatable {
    public let maximumBytes: Int

    public init(
        maximumBytes: Int = 64.mib
    ) {
        self.maximumBytes = max(
            0,
            maximumBytes
        )
    }

    public static let `default` = Self(
        maximumBytes: 64.mib
    )

    public static let formAPI = Self(
        maximumBytes: 256.kib
    )

    public static let tinyJSONAPI = Self(
        maximumBytes: 512.kib
    )

    public static let smallJSONAPI = Self(
        maximumBytes: 1.mib
    )

    public static let standardJSONAPI = Self(
        maximumBytes: 8.mib
    )

    public static let largeJSONAPI = Self(
        maximumBytes: 64.mib
    )

    public static let uploadAPI = Self(
        maximumBytes: 512.mib
    )

    public static let internalBulkAPI = Self(
        maximumBytes: 1.gib
    )

    public static func custom(
        _ maximumBytes: Int
    ) -> Self {
        Self(
            maximumBytes: maximumBytes
        )
    }
}

@available(
    *,
    deprecated,
    renamed: "HTTPContentPolicy"
)
public typealias HTTPContentLengthPolicy = HTTPContentPolicy

public enum HTTPFraming {
    public enum Body: Sendable, Hashable, Equatable {
        case none
        case contentLength(Int)
        case chunked
        case closeDelimited
        case tunnel
    }

    public static let defaultContentPolicy = HTTPContentPolicy.default

    @available(
        *,
        deprecated,
        renamed: "defaultContentPolicy"
    )
    public static let defaultContentLengthPolicy = defaultContentPolicy

    public static func extractContentLength(
        from headerData: Data,
        policy: HTTPContentPolicy = defaultContentPolicy
    ) throws -> Int? {
        guard let text = String(
            data: headerData,
            encoding: .utf8
        ) else {
            throw HTTPParsingError.malformedHeaders
        }

        let head: String

        if let separatorRange = text.range(
            of: HTTPConstants.crlfCrLf
        ) {
            head = String(
                text[..<separatorRange.lowerBound]
            )
        } else {
            head = text
        }

        let lines = head.components(
            separatedBy: HTTPConstants.crlf
        )

        var headers = HTTPHeaders()

        for line in lines {
            guard !line.isEmpty,
                  let separatorIndex = line.firstIndex(
                    of: Character(
                        HTTPConstants.headerSeparator
                    )
                  )
            else {
                continue
            }

            let name = String(
                line[..<separatorIndex]
            )
            .trimmingCharacters(
                in: .whitespaces
            )

            guard name.caseInsensitiveCompare(
                HTTPConstants.contentLengthHeader
            ) == .orderedSame else {
                continue
            }

            let value = String(
                line[line.index(after: separatorIndex)...]
            )
            .trimmingCharacters(
                in: .whitespaces
            )

            headers.append(
                name,
                value
            )
        }

        return try extractContentLength(
            from: headers,
            policy: policy
        )
    }

    public static func extractContentLength(
        from headers: HTTPHeaders,
        policy: HTTPContentPolicy = defaultContentPolicy
    ) throws -> Int? {
        let rawValues = headers.values(
            for: HTTPConstants.contentLengthHeader
        )

        var values: [Int] = []
        values.reserveCapacity(
            rawValues.count
        )

        for rawValue in rawValues {
            values.append(
                try parseContentLengthValue(
                    rawValue,
                    policy: policy
                )
            )
        }

        guard let first = values.first else {
            return nil
        }

        guard values.allSatisfy({
            $0 == first
        }) else {
            throw HTTPParsingError.conflictingContentLength(
                values
            )
        }

        return first
    }

    public static func parseContentLengthValue(
        _ rawValue: String,
        policy: HTTPContentPolicy = defaultContentPolicy
    ) throws -> Int {
        let trimmed = rawValue.trimmingCharacters(
            in: .whitespaces
        )

        guard !trimmed.isEmpty else {
            throw HTTPParsingError.invalidContentLength(
                rawValue
            )
        }

        guard trimmed.utf8.allSatisfy({
            (48...57).contains($0)
        }) else {
            throw HTTPParsingError.invalidContentLength(
                rawValue
            )
        }

        var value: UInt64 = 0

        let maximum = UInt64(
            max(
                0,
                policy.maximumBytes
            )
        )

        for byte in trimmed.utf8 {
            let digit = UInt64(
                byte - 48
            )

            guard digit <= maximum,
                  value <= (maximum - digit) / 10
            else {
                throw HTTPParsingError.contentLengthTooLarge(
                    value: rawValue,
                    maximumBytes: policy.maximumBytes
                )
            }

            value = (value * 10) + digit
        }

        guard value <= maximum else {
            throw HTTPParsingError.contentLengthTooLarge(
                value: rawValue,
                maximumBytes: policy.maximumBytes
            )
        }

        return Int(
            value
        )
    }

    public static func responseBody(
        requestMethod: HTTPMethod,
        status: HTTPStatus,
        headers: HTTPHeaders
    ) throws -> Body {
        if requestMethod == .head
            || (100...199).contains(status.code)
            || status.code == 204
            || status.code == 304 {
            return .none
        }

        if requestMethod == .connect,
           (200...299).contains(
            status.code
           ) {
            return .tunnel
        }

        let transferCodings = try parseTransferCodings(
            from: headers
        )

        let contentLengthValues = headers.values(
            for: HTTPConstants.contentLengthHeader
        )

        if !transferCodings.isEmpty,
           !contentLengthValues.isEmpty {
            throw HTTPParsingError.ambiguousMessageFraming
        }

        if let finalCoding = transferCodings.last {
            if finalCoding.name == "chunked" {
                return .chunked
            }

            return .closeDelimited
        }

        let protocolMaximum = HTTPContentPolicy(
            maximumBytes: Int.max
        )

        if let contentLength = try extractContentLength(
            from: headers,
            policy: protocolMaximum
        ) {
            return .contentLength(
                contentLength
            )
        }

        return .closeDelimited
    }

    private struct TransferCoding {
        let name: String
        let rawValue: String
    }

    private static func parseTransferCodings(
        from headers: HTTPHeaders
    ) throws -> [TransferCoding] {
        let values = headers.values(
            for: HTTPConstants.transferEncodingHeader
        )

        guard !values.isEmpty else {
            return []
        }

        var codings: [TransferCoding] = []

        for value in values {
            for rawCoding in try splitTransferCodingList(
                value
            ) {
                let trimmed = rawCoding.trimmingCharacters(
                    in: .whitespaces
                )

                guard !trimmed.isEmpty else {
                    throw HTTPParsingError.invalidTransferEncoding(
                        value
                    )
                }

                let semicolon = trimmed.firstIndex(
                    of: ";"
                )

                let namePart: Substring

                if let semicolon {
                    namePart = trimmed[
                        ..<semicolon
                    ]
                } else {
                    namePart = trimmed[
                        trimmed.startIndex...
                    ]
                }

                let name = String(
                    namePart
                )
                .trimmingCharacters(
                    in: .whitespaces
                )
                .lowercased()

                do {
                    try HTTPWireValidation.validateHeaderName(
                        name
                    )
                } catch {
                    throw HTTPParsingError.invalidTransferEncoding(
                        value
                    )
                }

                if name == "chunked",
                   semicolon != nil {
                    throw HTTPParsingError.invalidTransferEncoding(
                        value
                    )
                }

                codings.append(
                    TransferCoding(
                        name: name,
                        rawValue: trimmed
                    )
                )
            }
        }

        let chunkedCount = codings.reduce(
            into: 0
        ) { count, coding in
            if coding.name == "chunked" {
                count += 1
            }
        }

        guard chunkedCount <= 1 else {
            throw HTTPParsingError.invalidTransferEncoding(
                values.joined(
                    separator: ", "
                )
            )
        }

        return codings
    }

    private static func splitTransferCodingList(
        _ value: String
    ) throws -> [String] {
        var parts: [String] = []
        var current = ""
        var quoted = false
        var escaped = false

        for character in value {
            if escaped {
                current.append(
                    character
                )
                escaped = false
                continue
            }

            if quoted,
               character == "\\" {
                current.append(
                    character
                )
                escaped = true
                continue
            }

            if character == "\"" {
                current.append(
                    character
                )
                quoted.toggle()
                continue
            }

            if character == ",",
               !quoted {
                parts.append(
                    current
                )
                current = ""
                continue
            }

            current.append(
                character
            )
        }

        guard !quoted,
              !escaped
        else {
            throw HTTPParsingError.invalidTransferEncoding(
                value
            )
        }

        parts.append(
            current
        )

        return parts
    }
}
