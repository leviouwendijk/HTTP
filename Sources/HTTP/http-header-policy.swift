import Foundation

public struct HTTPHeaderPolicy: Sendable, Hashable, Equatable {
    public let maximumHeaderBytes: Int
    public let maximumHeaderLineBytes: Int
    public let maximumHeaderCount: Int
    public let singletonHeaderNames: Set<String>
    public let rejectTransferEncoding: Bool

    public init(
        maximumHeaderBytes: Int = 32.kib,
        maximumHeaderLineBytes: Int = 8.kib,
        maximumHeaderCount: Int = 100,
        singletonHeaderNames: Set<String> = [],
        rejectTransferEncoding: Bool = false
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
        self.singletonHeaderNames = Set(
            singletonHeaderNames.map {
                $0.lowercased()
            }
        )
        self.rejectTransferEncoding = rejectTransferEncoding
    }
}

extension HTTPHeaderPolicy {
    public static var request: RequestAPI {
        .init()
    }

    public static var response: ResponseAPI {
        .init()
    }

    public static let permissive = Self(
        maximumHeaderBytes: 256.kib,
        maximumHeaderLineBytes: 64.kib,
        maximumHeaderCount: 1_000,
        singletonHeaderNames: [],
        rejectTransferEncoding: false
    )

    public static var `default`: Self {
        request.default
    }
}

extension HTTPHeaderPolicy {
    public struct RequestAPI: Sendable {
        public var `default`: HTTPHeaderPolicy {
            HTTPHeaderPolicy(
                maximumHeaderBytes: 32.kib,
                maximumHeaderLineBytes: 8.kib,
                maximumHeaderCount: 100,
                singletonHeaderNames: [
                    "host",
                    "authorization",
                    "content-length",
                    "transfer-encoding",
                    "content-type",
                    "origin",
                    "x-forwarded-for",
                    "x-real-ip",
                    "forwarded",
                    "access-control-request-method",
                    "access-control-request-headers",
                ],
                rejectTransferEncoding: true
            )
        }
    }

    public struct ResponseAPI: Sendable {
        public var `default`: HTTPHeaderPolicy {
            HTTPHeaderPolicy(
                maximumHeaderBytes: 32.kib,
                maximumHeaderLineBytes: 8.kib,
                maximumHeaderCount: 100,
                singletonHeaderNames: [
                    "content-length",
                ],
                rejectTransferEncoding: false
            )
        }
    }
}

extension HTTPHeaderPolicy {
    @available(
        *,
        deprecated,
        message: "Use HTTPHeaderPolicy.request.default instead."
    )
    public static var requestDefault: Self {
        request.default
    }

    @available(
        *,
        deprecated,
        message: "Use HTTPHeaderPolicy.response.default instead."
    )
    public static var responseDefault: Self {
        response.default
    }
}
