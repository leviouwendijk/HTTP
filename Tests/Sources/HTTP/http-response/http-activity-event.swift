import Foundation

public struct HTTPActivityEvent: Sendable {
    public let serviceName: String

    /// Time at which the request completed.
    public let timestamp: Date

    public let method: HTTPMethod
    public let path: String
    public let status: HTTPStatus

    /// Matched route declaration, when one exists.
    public let routePattern: String?

    /// UTF-8 body size before HTTP framing and headers.
    public let responseBytes: Int?

    /// Structured operational failure metadata attached to the response.
    public let failure: HTTPFailure?

    /// Optional request metadata.
    public let clientDescription: String?
    public let requestId: String?
    public let userAgent: String?
    public let duration: TimeInterval?

    public init(
        serviceName: String? = nil,
        timestamp: Date,
        method: HTTPMethod,
        path: String,
        status: HTTPStatus,
        clientDescription: String?,
        requestId: String?,
        userAgent: String?,
        duration: TimeInterval?,
        routePattern: String? = nil,
        responseBytes: Int? = nil,
        failure: HTTPFailure? = nil
    ) {
        self.serviceName = serviceName ?? "<< 'config.name' ('ServerConfig') or 'APP_NAME' has not been set >>"
        self.timestamp = timestamp
        self.method = method
        self.path = path
        self.status = status
        self.routePattern = routePattern
        self.responseBytes = responseBytes
        self.failure = failure
        self.clientDescription = clientDescription
        self.requestId = requestId
        self.userAgent = userAgent
        self.duration = duration
    }
}

public typealias HTTPActivityCallback = @Sendable (_ event: HTTPActivityEvent) -> Void
