import Foundation

public enum HTTPChunkedBody {
    public struct Output: Sendable, Equatable {
        public let body: Data
        public let trailers: HTTPHeaders
        public let remainder: Data

        public init(
            body: Data,
            trailers: HTTPHeaders,
            remainder: Data
        ) {
            self.body = body
            self.trailers = trailers
            self.remainder = remainder
        }
    }

    public enum Progress: Sendable, Equatable {
        case incomplete
        case complete(Output)
    }

    public struct Decoder: Sendable {
        private enum State: Sendable {
            case size
            case data(Int)
            case trailers
            case complete(Output)
        }

        private var state: State = .size
        private var buffer = Data()
        private var decoded = Data()
        private var trailers = HTTPHeaders()
        private var trailerBytes = 0

        public let maximumDecodedBytes: Int
        public let trailerPolicy: HTTPHeaderPolicy

        public init(
            maximumDecodedBytes: Int = HTTPContentPolicy.default.maximumBytes,
            trailerPolicy: HTTPHeaderPolicy = HTTPHeaderPolicy.response.default
        ) {
            self.maximumDecodedBytes = max(
                0,
                maximumDecodedBytes
            )
            self.trailerPolicy = trailerPolicy
        }

        public mutating func receive(
            _ data: Data
        ) throws -> Progress {
            if case .complete(let output) = state {
                return .complete(
                    output
                )
            }

            if !data.isEmpty {
                buffer.append(
                    data
                )
            }

            return try process()
        }

        public func finish() throws -> Output {
            guard case .complete(let output) = state else {
                throw HTTPParsingError.incompleteChunkedBody
            }

            return output
        }

        private mutating func process() throws -> Progress {
            while true {
                switch state {
                case .size:
                    guard let line = try readLine(
                        maximumBytes: trailerPolicy.maximumHeaderLineBytes
                    ) else {
                        return .incomplete
                    }

                    let size = try parseChunkSize(
                        line
                    )

                    if size == 0 {
                        state = .trailers
                    } else {
                        guard size <= Int.max - decoded.count else {
                            throw HTTPParsingError.contentTooLarge(
                                actualBytes: Int.max,
                                maximumBytes: maximumDecodedBytes
                            )
                        }

                        let prospectiveCount =
                            decoded.count + size

                        guard prospectiveCount <= maximumDecodedBytes else {
                            throw HTTPParsingError.contentTooLarge(
                                actualBytes: prospectiveCount,
                                maximumBytes: maximumDecodedBytes
                            )
                        }

                        state = .data(
                            size
                        )
                    }

                case .data(let size):
                    guard size <= Int.max - 2 else {
                        throw HTTPParsingError.invalidChunkSize(
                            String(
                                size
                            )
                        )
                    }

                    let needed =
                        size + 2

                    guard buffer.count >= needed else {
                        return .incomplete
                    }

                    let dataEnd =
                        buffer.startIndex + size

                    let terminatorEnd =
                        dataEnd + 2

                    guard buffer[dataEnd] == 0x0D,
                          buffer[dataEnd + 1] == 0x0A
                    else {
                        throw HTTPParsingError.invalidChunkTerminator
                    }

                    decoded.append(
                        buffer.subdata(
                            in: buffer.startIndex..<dataEnd
                        )
                    )

                    buffer.removeSubrange(
                        buffer.startIndex..<terminatorEnd
                    )

                    state = .size

                case .trailers:
                    guard let line = try readLine(
                        maximumBytes: trailerPolicy.maximumHeaderLineBytes
                    ) else {
                        return .incomplete
                    }

                    let lineWireBytes =
                        line.count + 2

                    guard lineWireBytes <= Int.max - trailerBytes else {
                        throw HTTPParsingError.chunkTrailerSectionTooLarge(
                            maximumBytes: trailerPolicy.maximumHeaderBytes
                        )
                    }

                    trailerBytes +=
                        lineWireBytes

                    guard trailerBytes <= trailerPolicy.maximumHeaderBytes else {
                        throw HTTPParsingError.chunkTrailerSectionTooLarge(
                            maximumBytes: trailerPolicy.maximumHeaderBytes
                        )
                    }

                    if line.isEmpty {
                        let output = Output(
                            body: decoded,
                            trailers: trailers,
                            remainder: buffer
                        )

                        state = .complete(
                            output
                        )

                        return .complete(
                            output
                        )
                    }

                    guard trailers.count < trailerPolicy.maximumHeaderCount else {
                        throw HTTPParsingError.tooManyChunkTrailers(
                            maximumCount: trailerPolicy.maximumHeaderCount
                        )
                    }

                    guard let lineText = String(
                        data: line,
                        encoding: .utf8
                    ),
                    let field = HTTPGrammar.HeaderField.parse(
                        lineText
                    )
                    else {
                        throw HTTPParsingError.malformedHeaders
                    }

                    let name = field.name.trimmingCharacters(
                        in: .whitespaces
                    )

                    let value = field.value.trimmingCharacters(
                        in: .whitespaces
                    )

                    do {
                        try HTTPWireValidation.validateHeader(
                            name: name,
                            value: value
                        )
                    } catch {
                        throw HTTPParsingError.malformedHeaders
                    }

                    trailers.append(
                        name,
                        value
                    )

                case .complete(let output):
                    return .complete(
                        output
                    )
                }
            }
        }

        private mutating func readLine(
            maximumBytes: Int
        ) throws -> Data? {
            let marker = Data(
                HTTPConstants.crlf.utf8
            )

            guard let range = buffer.range(
                of: marker
            ) else {
                guard buffer.count <= maximumBytes else {
                    throw HTTPParsingError.headerLineTooLarge(
                        name: nil,
                        maximumBytes: maximumBytes
                    )
                }

                return nil
            }

            let line = buffer.subdata(
                in: buffer.startIndex..<range.lowerBound
            )

            guard line.count <= maximumBytes else {
                throw HTTPParsingError.headerLineTooLarge(
                    name: nil,
                    maximumBytes: maximumBytes
                )
            }

            buffer.removeSubrange(
                buffer.startIndex..<range.upperBound
            )

            return line
        }

        private func parseChunkSize(
            _ line: Data
        ) throws -> Int {
            guard let rawLine = String(
                data: line,
                encoding: .utf8
            ) else {
                throw HTTPParsingError.invalidChunkSize(
                    "<non-UTF8>"
                )
            }

            let sizeSource: String

            if let semicolon = rawLine.firstIndex(
                of: ";"
            ) {
                sizeSource = String(
                    rawLine[..<semicolon]
                )
            } else {
                sizeSource = rawLine
            }

            let digits = sizeSource.trimmingCharacters(
                in: .whitespaces
            )

            guard !digits.isEmpty else {
                throw HTTPParsingError.invalidChunkSize(
                    rawLine
                )
            }

            var value = 0

            for byte in digits.utf8 {
                let digit: Int

                switch byte {
                case 48...57:
                    digit = Int(
                        byte - 48
                    )

                case 65...70:
                    digit = Int(
                        byte - 65
                    ) + 10

                case 97...102:
                    digit = Int(
                        byte - 97
                    ) + 10

                default:
                    throw HTTPParsingError.invalidChunkSize(
                        rawLine
                    )
                }

                guard value <= (Int.max - digit) / 16 else {
                    throw HTTPParsingError.invalidChunkSize(
                        rawLine
                    )
                }

                value =
                    (value * 16) + digit
            }

            return value
        }
    }
}
