import Foundation
import HTTP
import TestFlows

extension HTTPFlowSuite {
    static let httpFramingRegressionFlow = TestFlow(
        "http.framing.regression",
        title: "HTTP/1.1 response framing and chunked decoding remain explicit and incremental",
        tags: [
            "http",
            "framing",
            "chunked",
            "parser",
            "regression",
        ]
    ) {
        Step("response framing gives method and status semantics precedence") {
            let chunked = HTTPHeaders(
                [
                    (
                        HTTPConstants.transferEncodingHeader,
                        "chunked"
                    )
                ]
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .head,
                    status: .ok,
                    headers: chunked
                ),
                .none,
                "framing.head.none"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .noContent,
                    headers: chunked
                ),
                .none,
                "framing.204.none"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .notModified,
                    headers: chunked
                ),
                .none,
                "framing.304.none"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .connect,
                    status: .ok,
                    headers: HTTPHeaders()
                ),
                .tunnel,
                "framing.connect.tunnel"
            )
        }

        Step("response framing distinguishes fixed, chunked, and close-delimited bodies") {
            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .ok,
                    headers: HTTPHeaders(
                        [
                            (
                                HTTPConstants.contentLengthHeader,
                                "5"
                            )
                        ]
                    )
                ),
                .contentLength(
                    5
                ),
                "framing.content-length"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .ok,
                    headers: HTTPHeaders(
                        [
                            (
                                HTTPConstants.transferEncodingHeader,
                                "chunked"
                            )
                        ]
                    )
                ),
                .chunked,
                "framing.chunked"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .ok,
                    headers: HTTPHeaders()
                ),
                .closeDelimited,
                "framing.close-delimited"
            )

            try Expect.equal(
                try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .ok,
                    headers: HTTPHeaders(
                        [
                            (
                                HTTPConstants.transferEncodingHeader,
                                "gzip"
                            )
                        ]
                    )
                ),
                .closeDelimited,
                "framing.transfer-coding-close-delimited"
            )
        }

        Step("response framing rejects simultaneous Transfer-Encoding and Content-Length") {
            let headers = HTTPHeaders(
                [
                    (
                        HTTPConstants.transferEncodingHeader,
                        "chunked"
                    ),
                    (
                        HTTPConstants.contentLengthHeader,
                        "5"
                    ),
                ]
            )

            try Expect.throwsError(
                "framing.te-cl-ambiguous"
            ) {
                _ = try HTTPFraming.responseBody(
                    requestMethod: .get,
                    status: .ok,
                    headers: headers
                )
            }
        }

        Step("chunked decoder produces decoded content") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 1.kib
            )

            let progress = try decoder.receive(
                Data(
                    "4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n".utf8
                )
            )

            guard case .complete(let output) = progress else {
                try Expect.true(
                    false,
                    "chunked.simple.complete"
                )

                return
            }

            try Expect.equal(
                String(
                    decoding: output.body,
                    as: UTF8.self
                ),
                "Wikipedia",
                "chunked.simple.body"
            )

            try Expect.equal(
                output.remainder.count,
                0,
                "chunked.simple.remainder"
            )
        }

        Step("chunked decoder survives every two-window split") {
            let wire = Data(
                "4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n".utf8
            )

            for split in 0...wire.count {
                var decoder = HTTPChunkedBody.Decoder(
                    maximumDecodedBytes: 1.kib
                )

                let first = Data(
                    wire.prefix(
                        split
                    )
                )

                let second = Data(
                    wire.dropFirst(
                        split
                    )
                )

                let firstProgress = try decoder.receive(
                    first
                )

                let finalProgress: HTTPChunkedBody.Progress

                switch firstProgress {
                case .incomplete:
                    finalProgress = try decoder.receive(
                        second
                    )

                case .complete:
                    finalProgress =
                        firstProgress
                }

                guard case .complete(let output) = finalProgress else {
                    try Expect.true(
                        false,
                        "chunked.split.complete.\(split)"
                    )

                    return
                }

                try Expect.equal(
                    String(
                        decoding: output.body,
                        as: UTF8.self
                    ),
                    "Wikipedia",
                    "chunked.split.body.\(split)"
                )
            }
        }

        Step("chunked decoder accepts extensions and retains trailers separately") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 1.kib
            )

            let progress = try decoder.receive(
                Data(
                    "4;trace=abc\r\nWiki\r\n0\r\nX-Trace: done\r\n\r\n".utf8
                )
            )

            guard case .complete(let output) = progress else {
                try Expect.true(
                    false,
                    "chunked.trailers.complete"
                )

                return
            }

            try Expect.equal(
                String(
                    decoding: output.body,
                    as: UTF8.self
                ),
                "Wiki",
                "chunked.trailers.body"
            )

            try Expect.equal(
                output.trailers.get(
                    "X-Trace"
                ),
                "done",
                "chunked.trailers.retained"
            )
        }

        Step("chunked decoder rejects malformed chunk size") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 1.kib
            )

            try Expect.throwsError(
                "chunked.invalid-size"
            ) {
                _ = try decoder.receive(
                    Data(
                        "z\r\nvalue\r\n0\r\n\r\n".utf8
                    )
                )
            }
        }

        Step("chunked decoder rejects missing data terminator") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 1.kib
            )

            try Expect.throwsError(
                "chunked.invalid-terminator"
            ) {
                _ = try decoder.receive(
                    Data(
                        "1\r\naX0\r\n\r\n".utf8
                    )
                )
            }
        }

        Step("chunked decoder bounds decoded content independently of wire framing") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 4
            )

            try Expect.throwsError(
                "chunked.content-limit"
            ) {
                _ = try decoder.receive(
                    Data(
                        "5\r\nhello\r\n0\r\n\r\n".utf8
                    )
                )
            }
        }

        Step("chunked decoder reports incomplete terminal framing") {
            var decoder = HTTPChunkedBody.Decoder(
                maximumDecodedBytes: 1.kib
            )

            _ = try decoder.receive(
                Data(
                    "4\r\nWiki\r\n0\r\n".utf8
                )
            )

            try Expect.throwsError(
                "chunked.incomplete"
            ) {
                _ = try decoder.finish()
            }
        }
    }
}
