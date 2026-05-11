import Foundation

public enum HTTPMethod: String, Sendable, CaseIterable, Hashable {
    case get = "GET"
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

    public static let defaultServerAllowed: Set<HTTPMethod> = [
        .get,
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
