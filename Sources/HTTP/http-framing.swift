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

public struct HTTPContentLengthPolicy: Sendable, Hashable, Equatable {
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

public enum HTTPFraming {
    public static let defaultContentLengthPolicy = HTTPContentLengthPolicy.default

    public static func extractContentLength(
        from headerData: Data,
        policy: HTTPContentLengthPolicy = defaultContentLengthPolicy
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

        var values: [Int] = []

        for line in lines {
            guard !line.isEmpty else {
                continue
            }

            guard let separatorIndex = line.firstIndex(
                of: Character(HTTPConstants.headerSeparator)
            ) else {
                continue
            }

            let name = String(
                line[..<separatorIndex]
            )
            .trimmingCharacters(
                in: .whitespaces
            )
            .lowercased()

            guard name == HTTPConstants.contentLengthHeader.lowercased() else {
                continue
            }

            let rawValue = String(
                line[line.index(after: separatorIndex)...]
            )
            .trimmingCharacters(
                in: .whitespaces
            )

            let value = try parseContentLengthValue(
                rawValue,
                policy: policy
            )

            values.append(value)
        }

        guard let first = values.first else {
            return nil
        }

        guard values.allSatisfy({ $0 == first }) else {
            throw HTTPParsingError.conflictingContentLength(values)
        }

        return first
    }

    public static func parseContentLengthValue(
        _ rawValue: String,
        policy: HTTPContentLengthPolicy = defaultContentLengthPolicy
    ) throws -> Int {
        let trimmed = rawValue.trimmingCharacters(
            in: .whitespaces
        )

        guard !trimmed.isEmpty else {
            throw HTTPParsingError.invalidContentLength(rawValue)
        }

        guard trimmed.utf8.allSatisfy({ (48...57).contains($0) }) else {
            throw HTTPParsingError.invalidContentLength(rawValue)
        }

        var value: UInt64 = 0
        let maximum = UInt64(
            max(
                0,
                policy.maximumBytes
            )
        )

        for byte in trimmed.utf8 {
            let digit = UInt64(byte - 48)

            guard digit <= maximum,
                  value <= (maximum - digit) / 10
            else {
                throw HTTPParsingError.invalidContentLength(rawValue)
            }

            value = (value * 10) + digit
        }

        guard value <= maximum else {
            throw HTTPParsingError.invalidContentLength(rawValue)
        }

        return Int(value)
    }
}
