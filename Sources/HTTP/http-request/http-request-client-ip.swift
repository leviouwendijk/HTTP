import Foundation
import Parsers

public struct HTTPClientContext: Sendable, Hashable {
    public let ip: Prebuilt.ForwardedClientIP
    public let requestID: String?
    public let userAgent: String?

    public var ipValue: String {
        ip.rawValue
    }

    public init(
        ip: Prebuilt.ForwardedClientIP,
        requestID: String?,
        userAgent: String?
    ) {
        self.ip = ip
        self.requestID = requestID
        self.userAgent = userAgent
    }
}

extension HTTPRequest {
    /// The client address the server resolved from the socket peer and its trusted
    /// proxies (`ServerConfig.trustedProxies`). `nil` for a request that did not come
    /// through a server, such as one built in a test.
    public var clientIP: String? {
        clientAddress
    }

    /// The resolved client address, validated as an IP.
    public func parseClientIP() throws -> Prebuilt.ForwardedClientIP {
        try Prebuilt.ForwardedClientIP(
            clientAddress
        )
    }

    public func client() throws -> HTTPClientContext {
        HTTPClientContext(
            ip: try parseClientIP(),
            requestID: header("X-Request-ID"),
            userAgent: header("User-Agent")
        )
    }
}
