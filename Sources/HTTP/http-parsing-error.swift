import Foundation

public enum HTTPParsingError: Error, LocalizedError, Sendable, Equatable {
    case invalidRequestLine(String)
    case invalidStatusLine(String)
    case malformedHeaders
    case invalidContentLength(String)
    case contentLengthTooLarge(value: String, maximumBytes: Int)
    case conflictingContentLength([Int])
    case headerSectionTooLarge(maximumBytes: Int)
    case headerLineTooLarge(name: String?, maximumBytes: Int)
    case tooManyHeaders(maximumCount: Int)
    case incompleteRequest
    case incompleteResponse

    public var errorDescription: String? {
        switch self {
        case .invalidRequestLine(let line):
            return "Invalid request line: \(line)"

        case .invalidStatusLine(let line):
            return "Invalid status line: \(line)"

        case .malformedHeaders:
            return "Headers are malformed"

        case .invalidContentLength(let value):
            return "Invalid Content-Length: \(value)"

        case .contentLengthTooLarge(let value, let maximumBytes):
            return "Content-Length exceeds configured maximum: \(value) > \(maximumBytes)"

        case .conflictingContentLength(let values):
            return "Conflicting Content-Length values: \(values)"

        case .headerSectionTooLarge(let maximumBytes):
            return "HTTP header section exceeds configured maximum: \(maximumBytes)"

        case .headerLineTooLarge(let name, let maximumBytes):
            return "HTTP header line exceeds configured maximum: \(name ?? "<unknown>") > \(maximumBytes)"

        case .tooManyHeaders(let maximumCount):
            return "HTTP header count exceeds configured maximum: \(maximumCount)"

        case .incompleteRequest:
            return "Request is incomplete"

        case .incompleteResponse:
            return "Response is incomplete"
        }
    }
}
