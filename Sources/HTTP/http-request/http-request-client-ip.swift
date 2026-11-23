import Foundation
import Parsers

public enum HTTPClientIPSource: Sendable {
    case trustedForwardedHeaders
}

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
    /// client context
    public func client(
        from source: HTTPClientIPSource = .trustedForwardedHeaders
    ) throws -> HTTPClientContext {
        HTTPClientContext(
            ip: try parseClientIP(from: source),
            requestID: header("X-Request-ID"),
            userAgent: header("User-Agent")
        )
    }

    /// Safe-by-default client IP.
    ///
    /// There is no peer socket address on HTTPRequest, and forwarding headers
    /// are only trustworthy after a trusted proxy boundary has overwritten them.
    public var clientIP: String? {
        nil
    }

    /// Safe-by-default client IP chain.
    ///
    /// There is no trusted peer chain available unless the request came through
    /// a trusted forwarding boundary.
    public var clientIPChain: [String] {
        []
    }

    /// Compatibility/raw-ish forwarded client IP.
    ///
    /// Prefer `parseClientIP(from:)` in application code.
    public var forwardedClientIP: String? {
        guard let candidate = _forwardedClientIPCandidate else {
            return nil
        }

        return try? Prebuilt.ForwardedClientIP(candidate).rawValue
    }

    public func parseClientIP(
        from source: HTTPClientIPSource = .trustedForwardedHeaders
    ) throws -> Prebuilt.ForwardedClientIP {
        switch source {
        case .trustedForwardedHeaders:
            return try Prebuilt.ForwardedClientIP(
                _forwardedClientIPCandidate
            )
        }
    }

    /// Compatibility/raw-ish chain.
    ///
    /// Prefer `parseClientIPChain(from:)` if consumers need typed IPs.
    public var forwardedClientIPChain: [String] {
        _forwardedClientIPChainCandidates.compactMap {
            try? Prebuilt.IPAddress($0).rawValue
        }
    }

    public func parseClientIPChain(
        from source: HTTPClientIPSource = .trustedForwardedHeaders
    ) throws -> [Prebuilt.IPAddress] {
        switch source {
        case .trustedForwardedHeaders:
            return try _forwardedClientIPChainCandidates.map {
                try Prebuilt.IPAddress($0)
            }
        }
    }

    /// The client address as recorded by the nearest trusted proxy.
    ///
    /// Order: `X-Real-IP` (overwritten by our edge), then `X-Forwarded-For` read
    /// right to left, then the last `Forwarded for=`. Each proxy appends the address
    /// it saw, so entries left of the first public hop are client-written. Private,
    /// loopback and link-local hops are our own proxies and are skipped.
    private var _forwardedClientIPCandidate: String? {
        if let xrip = header("X-Real-IP"),
           let cleaned = Self._cleanIPToken(xrip) {
            return cleaned
        }

        let chain = _forwardedClientIPChainCandidates

        if let nearestPublic = chain.last(where: {
            !Self._isInternalAddress($0)
        }) {
            return nearestPublic
        }

        if let nearest = chain.last {
            return nearest
        }

        if let fwd = header("Forwarded"),
           let ip = Self._parseForwardedFor(fwd),
           let cleaned = Self._cleanIPToken(ip) {
            return cleaned
        }

        return nil
    }

    private var _forwardedClientIPChainCandidates: [String] {
        guard let xff = header("X-Forwarded-For") else {
            return []
        }

        return xff
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .compactMap(Self._cleanIPToken)
    }

    /// The `for=` value of the last forwarded element (the hop nearest to us).
    private static func _parseForwardedFor(
        _ header: String
    ) -> String? {
        for part in header.split(separator: ",").reversed() {
            for keyValue in part.split(separator: ";") {
                let token = keyValue.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if token.count >= 4,
                   token.lowercased().hasPrefix("for=") {
                    let value = token.dropFirst(4)

                    return String(value).trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
            }
        }

        return nil
    }

    /// Private (RFC 1918, ULA), CGNAT, loopback and link-local addresses.
    private static func _isInternalAddress(
        _ value: String
    ) -> Bool {
        let lowercased = value.lowercased()

        if lowercased.contains(":") {
            return lowercased == "::1"
                || lowercased.hasPrefix("fc")
                || lowercased.hasPrefix("fd")
                || lowercased.hasPrefix("fe8")
                || lowercased.hasPrefix("fe9")
                || lowercased.hasPrefix("fea")
                || lowercased.hasPrefix("feb")
        }

        let octets = value
            .split(separator: ".")
            .compactMap { UInt8($0) }

        guard octets.count == 4 else {
            return false
        }

        switch (octets[0], octets[1]) {
        case (10, _), (127, _):
            return true
        case (172, 16...31), (192, 168), (169, 254), (100, 64...127):
            return true
        default:
            return false
        }
    }

    private static func _cleanIPToken(
        _ raw: String
    ) -> String? {
        var value = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if value.isEmpty {
            return nil
        }

        if value.first == "\"",
           value.last == "\"",
           value.count >= 2 {
            value = String(
                value.dropFirst().dropLast()
            )
        }

        if value.first == "[",
           let end = value.firstIndex(of: "]") {
            let inner = value[
                value.index(after: value.startIndex)..<end
            ]

            return inner.isEmpty ? nil : String(inner)
        }

        let colonCount = value.reduce(0) {
            $0 + ($1 == ":" ? 1 : 0)
        }

        if colonCount == 1,
           let index = value.firstIndex(of: ":") {
            let host = value[..<index]

            return host.isEmpty ? nil : String(host)
        }

        return value
    }
}
