import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpClientIPRegressionFlow = TestFlow(
        "http.client-ip.regression",
        title: "HTTPRequest parses trusted forwarded client IP headers",
        tags: [
            "http",
            "request",
            "headers",
            "client-ip",
            "forwarded",
            "regression"
        ]
    ) {
        Step("safe defaults expose no direct client IP") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [:]
            )

            try Expect.isNil(
                request.clientIP,
                "client-ip.default.clientIP"
            )

            try Expect.equal(
                request.clientIPChain,
                [],
                "client-ip.default.clientIPChain"
            )

            try Expect.throwsError(
                "client-ip.default.parseClientIP.throws"
            ) {
                _ = try request.parseClientIP()
            }
        }

        Step("parses first X-Forwarded-For address") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "X-Forwarded-For": "203.0.113.10, 10.100.0.1, 10.90.20.15"
                ]
            )

            let parsed = try request.parseClientIP()

            try Expect.equal(
                parsed.rawValue,
                "203.0.113.10",
                "client-ip.xff.first.raw"
            )

            try Expect.equal(
                request.forwardedClientIP,
                "203.0.113.10",
                "client-ip.xff.compat"
            )

            try Expect.equal(
                request.forwardedClientIPChain,
                [
                    "203.0.113.10",
                    "10.100.0.1",
                    "10.90.20.15"
                ],
                "client-ip.xff.chain"
            )
        }

        Step("falls back to X-Real-IP when X-Forwarded-For is absent") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "X-Real-IP": "198.51.100.44"
                ]
            )

            let parsed = try request.parseClientIP()

            try Expect.equal(
                parsed.rawValue,
                "198.51.100.44",
                "client-ip.x-real-ip.raw"
            )
        }

        Step("falls back to Forwarded for value when legacy headers are absent") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "Forwarded": #"for="198.51.100.45";proto=https;host=api.depaix.systems"#
                ]
            )

            let parsed = try request.parseClientIP()

            try Expect.equal(
                parsed.rawValue,
                "198.51.100.45",
                "client-ip.forwarded.raw"
            )
        }

        Step("cleans bracketed IPv6 from Forwarded header") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "Forwarded": #"for="[2001:db8::17]";proto=https"#
                ]
            )

            let parsed = try request.parseClientIP()

            try Expect.equal(
                parsed.rawValue,
                "2001:db8::17",
                "client-ip.forwarded.ipv6"
            )
        }

        Step("rejects unspecified addresses") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "X-Forwarded-For": "0.0.0.0"
                ]
            )

            try Expect.throwsError(
                "client-ip.xff.unspecified.throws"
            ) {
                _ = try request.parseClientIP()
            }
        }

        Step("does not silently fall back when primary forwarded header is malformed") {
            let request = HTTPRequest(
                method: .get,
                path: "/",
                headers: [
                    "X-Forwarded-For": "not-an-ip",
                    "X-Real-IP": "198.51.100.46"
                ]
            )

            try Expect.throwsError(
                "client-ip.xff.invalid-does-not-fallback"
            ) {
                _ = try request.parseClientIP()
            }

            try Expect.isNil(
                request.forwardedClientIP,
                "client-ip.xff.invalid.compat-nil"
            )
        }
    }
}
