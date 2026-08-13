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
        _ target: HTTPGrammar.RequestTarget.Output
    ) throws {
        guard target.raw.utf8.count <= maximumBytes else {
            throw HTTPValidationError.requestTargetTooLong(
                maximumBytes: maximumBytes
            )
        }

        let path = target.path

        if rejectBackslash && path.contains("\\") {
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

        if rejectEncodedDotSegments,
           containsEncodedDotSegment(path) {
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
