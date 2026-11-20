import Foundation

public enum HTTPFailureKind: String, Sendable, Codable, CaseIterable {
    case validation
    case authentication
    case authorization
    case rateLimit
    case dependency
    case database
    case tls
    case configuration
    case internalFailure
}

public enum HTTPFailureSeverity: String, Sendable, Codable, CaseIterable {
    case warning
    case error
    case critical
}

public struct HTTPFailure: Sendable, Codable, Equatable {
    public let code: String
    public let kind: HTTPFailureKind
    public let severity: HTTPFailureSeverity
    public let message: String
    public let dependency: String?
    public let retryable: Bool?

    public init(
        code: String,
        kind: HTTPFailureKind,
        severity: HTTPFailureSeverity = .error,
        message: String,
        dependency: String? = nil,
        retryable: Bool? = nil
    ) {
        self.code = code
        self.kind = kind
        self.severity = severity
        self.message = message
        self.dependency = dependency
        self.retryable = retryable
    }
}

public protocol HTTPReportableError: Error, Sendable {
    var httpStatus: HTTPStatus { get }
    var publicMessage: String { get }
    var httpFailure: HTTPFailure { get }
}

public extension HTTPReportableError {
    func response(
        headers: [String: String] = [:]
    ) -> HTTPResponse {
        HTTPResponse(
            status: httpStatus,
            headers: headers,
            body: publicMessage,
            failure: httpFailure
        )
    }
}
