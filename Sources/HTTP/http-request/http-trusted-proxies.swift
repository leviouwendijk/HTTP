import Foundation

/// Address ranges of proxies whose forwarding headers are believed.
///
/// The client address is resolved from the socket peer: an untrusted peer is the client
/// and its forwarding headers are ignored; a trusted peer's `X-Forwarded-For` is read
/// right to left past trusted hops, and the first untrusted hop is the client.
public struct HTTPTrustedProxies: Sendable, Hashable {
    public enum Error: Swift.Error, LocalizedError, Sendable, Equatable {
        case invalidRange(String)

        public var errorDescription: String? {
            switch self {
            case .invalidRange(let value):
                return "Invalid trusted proxy address or CIDR range: \(value.debugDescription)"
            }
        }
    }

    struct Range: Sendable, Hashable {
        let network: [UInt8]
        let prefixLength: Int

        func contains(
            _ address: [UInt8]
        ) -> Bool {
            guard address.count == network.count else {
                return false
            }

            var remaining = prefixLength

            for index in network.indices where remaining > 0 {
                let bits = min(
                    8,
                    remaining
                )

                let mask = UInt8(
                    truncatingIfNeeded: 0xFF << (8 - bits)
                )

                guard address[index] & mask == network[index] & mask else {
                    return false
                }

                remaining -= bits
            }

            return true
        }
    }

    let ranges: [Range]

    /// Each value is an address (`10.90.20.15`, `::1`) or a CIDR range (`10.100.0.0/24`).
    public init(
        _ values: [String]
    ) throws {
        self.ranges = try values.map { value in
            let trimmed = value.trimmingCharacters(
                in: .whitespaces
            )

            let parts = trimmed.split(
                separator: "/",
                maxSplits: 1
            )

            guard let first = parts.first,
                  let network = Self.bytes(
                    String(first)
                  )
            else {
                throw Error.invalidRange(
                    value
                )
            }

            let maximum = network.count * 8
            var prefixLength = maximum

            if parts.count == 2 {
                guard let parsed = Int(parts[1]),
                      (0...maximum).contains(parsed)
                else {
                    throw Error.invalidRange(
                        value
                    )
                }

                prefixLength = parsed
            }

            return Range(
                network: network,
                prefixLength: prefixLength
            )
        }
    }

    /// Trust nothing: the socket peer is always the client.
    public static let none = try! Self([])

    /// Trust only a proxy on the same host, such as nginx in front of a service bound to 127.0.0.1.
    public static let loopback = try! Self([
        "127.0.0.0/8",
        "::1",
    ])

    /// Parses a comma-separated list, as in a `TRUSTED_PROXIES` environment variable.
    public static func parsing(
        _ list: String
    ) throws -> Self {
        try Self(
            list
                .split(separator: ",")
                .map(String.init)
                .filter {
                    !$0.trimmingCharacters(in: .whitespaces).isEmpty
                }
        )
    }

    public func contains(
        _ address: String
    ) -> Bool {
        guard let bytes = Self.bytes(
            address
        ) else {
            return false
        }

        return ranges.contains {
            $0.contains(
                bytes
            )
        }
    }

    /// The client address for a request that arrived from `peer` carrying `headers`.
    public func resolveClient(
        peer: String,
        headers: HTTPHeaders
    ) -> String {
        let peer = Self.normalize(
            peer
        )

        guard contains(
            peer
        ) else {
            return peer
        }

        let chain = (headers.get("X-Forwarded-For") ?? "")
            .split(separator: ",")
            .map {
                Self.normalize(
                    String($0)
                )
            }
            .filter {
                !$0.isEmpty
            }

        if !chain.isEmpty {
            if let nearestUntrusted = chain.last(where: {
                !contains($0)
            }) {
                return nearestUntrusted
            }

            return chain[0]
        }

        if let realIP = headers.get(
            "X-Real-IP"
        ) {
            let normalized = Self.normalize(
                realIP
            )

            if !normalized.isEmpty {
                return normalized
            }
        }

        return peer
    }

    /// Strips quotes, brackets, IPv6 zone ids and ports; maps IPv4-mapped IPv6 to IPv4.
    static func normalize(
        _ raw: String
    ) -> String {
        var value = raw.trimmingCharacters(
            in: .whitespaces
        )

        if value.hasPrefix("\""),
           value.hasSuffix("\""),
           value.count >= 2 {
            value = String(
                value.dropFirst().dropLast()
            )
        }

        if value.hasPrefix("["),
           let end = value.firstIndex(of: "]") {
            value = String(
                value[value.index(after: value.startIndex)..<end]
            )
        } else if value.filter({ $0 == ":" }).count == 1,
                  let colon = value.firstIndex(of: ":") {
            value = String(
                value[..<colon]
            )
        }

        if let zone = value.firstIndex(of: "%") {
            value = String(
                value[..<zone]
            )
        }

        let lowercased = value.lowercased()

        if lowercased.hasPrefix("::ffff:"),
           lowercased.contains(".") {
            return String(
                lowercased.dropFirst(7)
            )
        }

        return lowercased
    }

    static func bytes(
        _ raw: String
    ) -> [UInt8]? {
        let address = normalize(
            raw
        )

        var v4 = in_addr()

        if inet_pton(AF_INET, address, &v4) == 1 {
            return withUnsafeBytes(of: &v4) {
                Array($0)
            }
        }

        var v6 = in6_addr()

        if inet_pton(AF_INET6, address, &v6) == 1 {
            return withUnsafeBytes(of: &v6) {
                Array($0)
            }
        }

        return nil
    }
}
