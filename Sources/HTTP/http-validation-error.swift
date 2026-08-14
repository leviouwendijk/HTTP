import Foundation

public enum HTTPValidationError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedMethod(String)
    case unsupportedHTTPVersion(String)
    case invalidStatusCode(String)
    case invalidRequestTarget(String)
    case invalidHeaderName(String)
    case invalidHeaderValue(name: String, value: String)
    case duplicateHeader(String)
    case forbiddenHeader(String)
    case invalidContentLength(String)
    case contentLengthTooLarge(value: String, maximumBytes: Int)
    case contentTooLarge(actualBytes: Int, maximumBytes: Int)
    case requestTargetTooLong(maximumBytes: Int)
    case ambiguousRequestTarget(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedMethod(let method):
            return "Unsupported HTTP method: \(method)"

        case .unsupportedHTTPVersion(let version):
            return "Unsupported HTTP version: \(version)"

        case .invalidStatusCode(let code):
            return "Invalid HTTP status code: \(code)"

        case .invalidRequestTarget(let target):
            return "Invalid HTTP request target: \(target.debugDescription)"

        case .invalidHeaderName(let name):
            return "Invalid HTTP header name: \(name.debugDescription)"

        case .invalidHeaderValue(let name, let value):
            return "Invalid HTTP header value for \(name.debugDescription): \(value.debugDescription)"

        case .duplicateHeader(let name):
            return "Duplicate HTTP header is not accepted: \(name)"

        case .forbiddenHeader(let name):
            return "HTTP header is not accepted: \(name)"

        case .invalidContentLength(let value):
            return "Invalid Content-Length: \(value)"

        case .contentLengthTooLarge(let value, let maximumBytes):
            return "Content-Length exceeds configured maximum: \(value) > \(maximumBytes)"

        case .contentTooLarge(let actualBytes, let maximumBytes):
            return "HTTP content exceeds configured maximum: \(actualBytes) > \(maximumBytes)"

        case .requestTargetTooLong(let maximumBytes):
            return "HTTP request target exceeds configured maximum: \(maximumBytes)"

        case .ambiguousRequestTarget(let target):
            return "Ambiguous HTTP request target: \(target)"
        }
    }
}
