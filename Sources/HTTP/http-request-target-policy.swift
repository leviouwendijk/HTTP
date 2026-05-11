import Foundation

public struct HTTPRequestTargetPolicy: Sendable, Hashable, Equatable {
    public let maximumBytes: Int
    public let rejectEncodedDotSegments: Bool
    public let rejectDoubleSlash: Bool
    public let rejectBackslash: Bool

    public init(
        maximumBytes: Int = 8.kib,
        rejectEncodedDotSegments: Bool = true,
        rejectDoubleSlash: Bool = true,
        rejectBackslash: Bool = true
    ) {
        self.maximumBytes = max(
            0,
            maximumBytes
        )
        self.rejectEncodedDotSegments = rejectEncodedDotSegments
        self.rejectDoubleSlash = rejectDoubleSlash
        self.rejectBackslash = rejectBackslash
    }

    public static let `default` = Self()

    public static let permissive = Self(
        maximumBytes: 64.kib,
        rejectEncodedDotSegments: false,
        rejectDoubleSlash: false,
        rejectBackslash: false
    )

    public func validate(
        _ target: String
    ) throws {
        guard target.utf8.count <= maximumBytes else {
            throw HTTPParsingError.requestTargetTooLong(
                maximumBytes: maximumBytes
            )
        }

        let path = pathPart(
            of: target
        )

        if rejectBackslash && path.contains("\\") {
            throw HTTPParsingError.ambiguousRequestTarget(target)
        }

        if rejectDoubleSlash,
           path != "/",
           path.contains("//") {
            throw HTTPParsingError.ambiguousRequestTarget(target)
        }

        if rejectEncodedDotSegments,
           containsEncodedDotSegment(path) {
            throw HTTPParsingError.ambiguousRequestTarget(target)
        }
    }

    private func pathPart(
        of target: String
    ) -> String {
        guard let queryIndex = target.firstIndex(
            of: "?"
        ) else {
            return target
        }

        return String(
            target[..<queryIndex]
        )
    }

    private func containsEncodedDotSegment(
        _ path: String
    ) -> Bool {
        let lowercased = path.lowercased()

        return lowercased.contains("%2e")
            || lowercased.contains("%2e%2e")
            || lowercased.contains(".%2e")
            || lowercased.contains("%2e.")
    }
}
