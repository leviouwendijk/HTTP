import Foundation
import HTTP
import TestFlows

private func resolved(
    peer: String,
    trusting trusted: HTTPTrustedProxies,
    headers: [String: String]
) -> String? {
    HTTPRequest(
        method: .get,
        path: "/",
        headers: headers
    )
    .resolvingClient(
        peer: peer,
        trustedProxies: trusted
    )
    .clientIP
}

extension HTTPFlowSuite {
    static let httpClientIPRegressionFlow = TestFlow(
        "http.client-ip.regression",
        title: "Client IP resolves from the socket peer through trusted proxies",
        tags: [
            "http",
            "request",
            "headers",
            "client-ip",
            "forwarded",
            "regression"
        ]
    ) {
        Step("a request that did not come through a server has no client IP") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "X-Forwarded-For": "203.0.113.10"
                ]
            )

            try Expect.isNil(
                request.clientIP,
                "client-ip.unresolved.nil"
            )

            try Expect.throwsError(
                "client-ip.unresolved.parse-throws"
            ) {
                _ = try request.parseClientIP()
            }
        }

        Step("an untrusted peer is the client and its headers are ignored") {
            try Expect.equal(
                resolved(
                    peer: "198.51.100.9",
                    trusting: .loopback,
                    headers: [
                        "X-Forwarded-For": "6.6.6.6",
                        "X-Real-IP": "6.6.6.6"
                    ]
                ),
                "198.51.100.9",
                "client-ip.untrusted-peer"
            )

            try Expect.equal(
                resolved(
                    peer: "10.60.10.147",
                    trusting: .loopback,
                    headers: [
                        "X-Forwarded-For": "6.6.6.6"
                    ]
                ),
                "10.60.10.147",
                "client-ip.untrusted-lan-peer"
            )
        }

        Step("public traffic through moxy, proxy-box and malinois resolves to the client") {
            // Service behind malinois nginx on loopback; nginx appends to XFF.
            try Expect.equal(
                resolved(
                    peer: "127.0.0.1",
                    trusting: try HTTPTrustedProxies([
                        "127.0.0.1",
                        "10.90.20.15",
                        "10.100.0.0/24",
                    ]),
                    headers: [
                        "X-Forwarded-For": "203.0.113.10, 10.100.0.1, 10.90.20.15",
                        "X-Real-IP": "10.90.20.15"
                    ]
                ),
                "203.0.113.10",
                "client-ip.chain.public"
            )
        }

        Step("client-written entries left of the first untrusted hop are ignored") {
            try Expect.equal(
                resolved(
                    peer: "127.0.0.1",
                    trusting: try HTTPTrustedProxies([
                        "127.0.0.1",
                        "10.90.20.15",
                    ]),
                    headers: [
                        "X-Forwarded-For": "6.6.6.6, 203.0.113.10, 10.90.20.15"
                    ]
                ),
                "203.0.113.10",
                "client-ip.chain.spoofed-prefix"
            )
        }

        Step("nginx realip: loopback trust is enough once nginx resolves the client") {
            // realip on malinois rewrites $remote_addr, so it appends the client itself.
            try Expect.equal(
                resolved(
                    peer: "127.0.0.1",
                    trusting: .loopback,
                    headers: [
                        "X-Forwarded-For": "203.0.113.10, 10.100.0.1, 203.0.113.10",
                        "X-Real-IP": "203.0.113.10"
                    ]
                ),
                "203.0.113.10",
                "client-ip.chain.realip"
            )
        }

        Step("a trusted peer without X-Forwarded-For falls back to X-Real-IP, then itself") {
            try Expect.equal(
                resolved(
                    peer: "127.0.0.1",
                    trusting: .loopback,
                    headers: [
                        "X-Real-IP": "198.51.100.44"
                    ]
                ),
                "198.51.100.44",
                "client-ip.trusted.x-real-ip"
            )

            try Expect.equal(
                resolved(
                    peer: "::1",
                    trusting: .loopback,
                    headers: [:]
                ),
                "::1",
                "client-ip.trusted.peer"
            )
        }

        Step("peer addresses are normalized before matching") {
            try Expect.equal(
                resolved(
                    peer: "::ffff:127.0.0.1",
                    trusting: .loopback,
                    headers: [
                        "X-Forwarded-For": "[2001:db8::7]:4711"
                    ]
                ),
                "2001:db8::7",
                "client-ip.normalize.mapped-and-bracketed"
            )
        }

        Step("CIDR ranges match IPv4 and IPv6 and reject malformed input") {
            let trusted = try HTTPTrustedProxies([
                "10.100.0.0/24",
                "fd00::/8",
            ])

            try Expect.true(
                trusted.contains("10.100.0.77"),
                "client-ip.cidr.v4-in"
            )

            try Expect.false(
                trusted.contains("10.100.1.1"),
                "client-ip.cidr.v4-out"
            )

            try Expect.true(
                trusted.contains("fd12::1"),
                "client-ip.cidr.v6-in"
            )

            try Expect.false(
                trusted.contains("not-an-ip"),
                "client-ip.cidr.garbage"
            )

            try Expect.throwsError(
                "client-ip.cidr.invalid-prefix"
            ) {
                _ = try HTTPTrustedProxies([
                    "10.0.0.0/33"
                ])
            }

            try Expect.equal(
                try HTTPTrustedProxies.parsing(
                    "127.0.0.1, 10.90.20.15 ,"
                ),
                try HTTPTrustedProxies([
                    "127.0.0.1",
                    "10.90.20.15",
                ]),
                "client-ip.cidr.parsing"
            )
        }

        Step("parseClientIP validates the resolved address") {
            let request = HTTPRequest(
                method: .get,
                path: "/"
            )
            .resolvingClient(
                peer: "127.0.0.1",
                trustedProxies: .loopback
            )

            try Expect.equal(
                try request.client().ipValue,
                "127.0.0.1",
                "client-ip.context"
            )
        }
    }
}
