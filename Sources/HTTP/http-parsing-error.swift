import Foundation

public enum HTTPParsingError: Error, LocalizedError, Sendable, Equatable {
    case invalidRequestLine(String)
    case invalidMethod(String)
    case invalidHTTPVersion(String)
    case invalidStatusLine(String)
    case invalidStatusCode(String)
    case malformedHeaders
    case duplicateHeader(String)
    case invalidContentLength(String)
    case contentLengthTooLarge(value: String, maximumBytes: Int)
    case conflictingContentLength([Int])
    case incompleteRequest
    case incompleteResponse

    public var errorDescription: String? {
        switch self {
        case .invalidRequestLine(let line):
            return "Invalid request line: \(line)"

        case .invalidMethod(let method):
            return "Invalid HTTP method: \(method)"

        case .invalidHTTPVersion(let version):
            return "Invalid HTTP version: \(version)"

        case .invalidStatusLine(let line):
            return "Invalid status line: \(line)"

        case .invalidStatusCode(let code):
            return "Invalid status code: \(code)"

        case .malformedHeaders:
            return "Headers are malformed"

        case .duplicateHeader(let name):
            return "Duplicate HTTP header is not accepted: \(name)"

        case .invalidContentLength(let value):
            return "Invalid Content-Length: \(value)"

        case .contentLengthTooLarge(let value, let maximumBytes):
            return "Content-Length exceeds configured maximum: \(value) > \(maximumBytes)"

        case .conflictingContentLength(let values):
            return "Conflicting Content-Length values: \(values)"

        case .incompleteRequest:
            return "Request is incomplete"

        case .incompleteResponse:
            return "Response is incomplete"
        }
    }
}
