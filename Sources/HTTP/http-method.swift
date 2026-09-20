import Foundation

public enum HTTPMethod: String, Sendable, CaseIterable, Hashable {
    case get = "GET"
    case query = "QUERY"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"

    public init?(
        caseInsensitive rawValue: String
    ) {
        self.init(
            rawValue: rawValue.uppercased()
        )
    }

    public var isSafe: Bool {
        switch self {
        case .get, .head, .options, .query, .trace:
            return true
        case .connect, .delete, .patch, .post, .put:
            return false
        }
    }

    public var isIdempotent: Bool {
        switch self {
        case .delete, .get, .head, .options, .put, .query, .trace:
            return true
        case .connect, .patch, .post:
            return false
        }
    }

    public static let defaultServerAllowed: Set<HTTPMethod> = [
        .get,
        .query,
        .post,
        .put,
        .delete,
        .patch,
        .head,
        .options,
    ]

    public static let allServerMethods: Set<HTTPMethod> = Set(
        HTTPMethod.allCases
    )
}
