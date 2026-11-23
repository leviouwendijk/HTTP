import Foundation

public struct HTTPRequestTargetPolicy: Sendable, Hashable, Equatable {
    public let maximumBytes: Int

    /// Reject `.` and `..` path segments, literal or percent-encoded (`%2e`).
    public let rejectDotSegments: Bool
    public let rejectDoubleSlash: Bool

    /// Reject `\\` and the encoded separators `%2f` and `%5c`, which decode to a
    /// different path than the one routed.
    public let rejectBackslash: Bool

    public init(
        maximumBytes: Int = 8.kib,
        rejectDotSegments: Bool = true,
        rejectDoubleSlash: Bool = true,
        rejectBackslash: Bool = true
    ) {
        self.maximumBytes = max(
            0,
            maximumBytes
        )
        self.rejectDotSegments = rejectDotSegments
        self.rejectDoubleSlash = rejectDoubleSlash
        self.rejectBackslash = rejectBackslash
    }

    public static let `default` = Self()

    public static let permissive = Self(
        maximumBytes: 64.kib,
        rejectDotSegments: false,
        rejectDoubleSlash: false,
        rejectBackslash: false
    )

    public func validate(
        _ target: HTTPGrammar.RequestTarget.Output
    ) throws {
        guard target.raw.utf8.count <= maximumBytes else {
            throw HTTPValidationError.requestTargetTooLong(
                maximumBytes: maximumBytes
            )
        }

        let path = target.path.raw

        if rejectBackslash,
           containsSeparatorAmbiguity(path) {
            throw HTTPValidationError.ambiguousRequestTarget(
                target.raw
            )
        }

        if rejectDoubleSlash,
           path != "/",
           path.contains("//") {
            throw HTTPValidationError.ambiguousRequestTarget(
                target.raw
            )
        }

        if rejectDotSegments,
           containsDotSegment(path) {
            throw HTTPValidationError.ambiguousRequestTarget(
                target.raw
            )
        }
    }

    public func validate(
        _ target: String
    ) throws {
        try validate(
            HTTPGrammar.RequestTarget.Output(
                raw: target
            )
        )
    }

    private func containsSeparatorAmbiguity(
        _ path: String
    ) -> Bool {
        let lowercased = path.lowercased()

        return lowercased.contains("\\")
            || lowercased.contains("%2f")
            || lowercased.contains("%5c")
    }

    private func containsDotSegment(
        _ path: String
    ) -> Bool {
        path
            .split(
                separator: "/",
                omittingEmptySubsequences: false
            )
            .contains { segment in
                let decoded = segment
                    .lowercased()
                    .replacingOccurrences(
                        of: "%2e",
                        with: "."
                    )

                return decoded == "."
                    || decoded == ".."
            }
    }
}
