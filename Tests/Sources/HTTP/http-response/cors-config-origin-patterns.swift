import Foundation
import Parsers

public extension CORSConfig.AllowedOrigin {
    static func pattern(
        _ pattern: Prebuilt.CORSOriginPattern,
        schemes: Set<Prebuilt.Origin.Scheme> = [.https],
        port: Prebuilt.CORSOriginMatcher.PortRule = .any
    ) -> Self {
        .matcher(
            pattern.matcher(
                schemes: schemes,
                port: port
            )
        )
    }

    static func patterns(
        _ patterns: [Prebuilt.CORSOriginPattern],
        schemes: Set<Prebuilt.Origin.Scheme> = [.https],
        port: Prebuilt.CORSOriginMatcher.PortRule = .any
    ) -> Self {
        let rules = patterns.flatMap { pattern in
            pattern.rules(
                schemes: schemes,
                port: port
            )
        }

        return .matcher(
            Prebuilt.CORSOriginMatcher(
                rules: rules
            )
        )
    }
}
