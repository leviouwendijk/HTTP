import Foundation
import Parsers

public enum HTTPClientIPSource: Sendable {
    case trustedForwardedHeaders
}

extension HTTPRequest {
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

    private var _forwardedClientIPCandidate: String? {
        if let xff = header("X-Forwarded-For"),
           let first = xff.split(separator: ",", maxSplits: 1).first {
            let ip = first.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if let cleaned = Self._cleanIPToken(ip) {
                return cleaned
            }
        }

        if let xrip = header("X-Real-IP") {
            let ip = xrip.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if let cleaned = Self._cleanIPToken(ip) {
                return cleaned
            }
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

    private static func _parseForwardedFor(
        _ header: String
    ) -> String? {
        for part in header.split(separator: ",") {
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
