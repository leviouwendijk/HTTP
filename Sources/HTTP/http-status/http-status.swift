import Foundation

public struct HTTPStatus: Hashable, Sendable, Equatable {
    public let code: Int
    public let reason: String
    
    public init(code: Int, reason: String) {
        self.code = code
        self.reason = reason
    }
    
    // Standard 1xx Informational
    public static let `continue` = HTTPStatus(code: 100, reason: "Continue")
    public static let switchingProtocols = HTTPStatus(code: 101, reason: "Switching Protocols")
    public static let processing = HTTPStatus(code: 102, reason: "Processing")
    public static let earlyHints = HTTPStatus(code: 103, reason: "Early Hints")
    
    // Standard 2xx Success
    public static let ok = HTTPStatus(code: 200, reason: "OK")
    public static let created = HTTPStatus(code: 201, reason: "Created")
    public static let accepted = HTTPStatus(code: 202, reason: "Accepted")
    public static let nonAuthoritativeInformation = HTTPStatus(code: 203, reason: "Non-Authoritative Information")
    public static let noContent = HTTPStatus(code: 204, reason: "No Content")
    public static let resetContent = HTTPStatus(code: 205, reason: "Reset Content")
    public static let partialContent = HTTPStatus(code: 206, reason: "Partial Content")
    public static let multiStatus = HTTPStatus(code: 207, reason: "Multi-Status")
    public static let alreadyReported = HTTPStatus(code: 208, reason: "Already Reported")
    public static let imUsed = HTTPStatus(code: 226, reason: "IM Used")
    
    // Standard 3xx Redirection
    public static let multipleChoices = HTTPStatus(code: 300, reason: "Multiple Choices")
    public static let movedPermanently = HTTPStatus(code: 301, reason: "Moved Permanently")
    public static let found = HTTPStatus(code: 302, reason: "Found")
    public static let seeOther = HTTPStatus(code: 303, reason: "See Other")
    public static let notModified = HTTPStatus(code: 304, reason: "Not Modified")
    public static let useProxy = HTTPStatus(code: 305, reason: "Use Proxy")
    public static let temporaryRedirect = HTTPStatus(code: 307, reason: "Temporary Redirect")
    public static let permanentRedirect = HTTPStatus(code: 308, reason: "Permanent Redirect")
    
    // Standard 4xx Client Error
    public static let badRequest = HTTPStatus(code: 400, reason: "Bad Request")
    public static let unauthorized = HTTPStatus(code: 401, reason: "Unauthorized")
    public static let paymentRequired = HTTPStatus(code: 402, reason: "Payment Required")
    public static let forbidden = HTTPStatus(code: 403, reason: "Forbidden")
    public static let notFound = HTTPStatus(code: 404, reason: "Not Found")
    public static let methodNotAllowed = HTTPStatus(code: 405, reason: "Method Not Allowed")
    public static let notAcceptable = HTTPStatus(code: 406, reason: "Not Acceptable")
    public static let proxyAuthenticationRequired = HTTPStatus(code: 407, reason: "Proxy Authentication Required")
    public static let requestTimeout = HTTPStatus(code: 408, reason: "Request Timeout")
    public static let conflict = HTTPStatus(code: 409, reason: "Conflict")
    public static let gone = HTTPStatus(code: 410, reason: "Gone")
    public static let lengthRequired = HTTPStatus(code: 411, reason: "Length Required")
    public static let preconditionFailed = HTTPStatus(code: 412, reason: "Precondition Failed")
    public static let contentTooLarge = HTTPStatus(code: 413, reason: "Content Too Large")

    public static let uriTooLong = HTTPStatus(code: 414, reason: "URI Too Long")
    public static let unsupportedMediaType = HTTPStatus(code: 415, reason: "Unsupported Media Type")
    public static let rangeNotSatisfiable = HTTPStatus(code: 416, reason: "Range Not Satisfiable")
    public static let expectationFailed = HTTPStatus(code: 417, reason: "Expectation Failed")
    @available(*, deprecated, message: "418 is unused in the IANA HTTP Status Code Registry.")
    public static let teapot = HTTPStatus(code: 418, reason: "I'm a teapot")
    public static let misdirectedRequest = HTTPStatus(code: 421, reason: "Misdirected Request")
    public static let unprocessableContent = HTTPStatus(code: 422, reason: "Unprocessable Content")

    public static let locked = HTTPStatus(code: 423, reason: "Locked")
    public static let failedDependency = HTTPStatus(code: 424, reason: "Failed Dependency")
    public static let tooEarly = HTTPStatus(code: 425, reason: "Too Early")
    public static let upgradeRequired = HTTPStatus(code: 426, reason: "Upgrade Required")
    public static let preconditionRequired = HTTPStatus(code: 428, reason: "Precondition Required")
    public static let tooManyRequests = HTTPStatus(code: 429, reason: "Too Many Requests")
    public static let requestHeaderFieldsTooLarge = HTTPStatus(code: 431, reason: "Request Header Fields Too Large")
    public static let unavailableForLegalReasons = HTTPStatus(code: 451, reason: "Unavailable For Legal Reasons")
    
    // Standard 5xx Server Error
    public static let internalServerError = HTTPStatus(code: 500, reason: "Internal Server Error")
    public static let notImplemented = HTTPStatus(code: 501, reason: "Not Implemented")
    public static let badGateway = HTTPStatus(code: 502, reason: "Bad Gateway")
    public static let serviceUnavailable = HTTPStatus(code: 503, reason: "Service Unavailable")
    public static let gatewayTimeout = HTTPStatus(code: 504, reason: "Gateway Timeout")
    public static let httpVersionNotSupported = HTTPStatus(code: 505, reason: "HTTP Version Not Supported")
    public static let variantAlsoNegotiates = HTTPStatus(code: 506, reason: "Variant Also Negotiates")
    public static let insufficientStorage = HTTPStatus(code: 507, reason: "Insufficient Storage")
    public static let loopDetected = HTTPStatus(code: 508, reason: "Loop Detected")
    @available(*, deprecated, message: "510 Not Extended is obsolete in the IANA HTTP Status Code Registry.")
    public static let notExtended = HTTPStatus(code: 510, reason: "Not Extended")
    public static let networkAuthenticationRequired = HTTPStatus(code: 511, reason: "Network Authentication Required")
    
    // Default Fallbacks
    public static func defaultFor(code: Int) -> HTTPStatus {
        switch code {
        case 100..<200: return HTTPStatus(code: code, reason: "Informational")
        case 200..<300: return HTTPStatus(code: code, reason: "Success")
        case 300..<400: return HTTPStatus(code: code, reason: "Redirection")
        case 400..<500: return HTTPStatus(code: code, reason: "Client Error")
        case 500..<600: return HTTPStatus(code: code, reason: "Server Error")
        default: return HTTPStatus(code: code, reason: "Unknown")
        }
    }

    private static func standardFor(
        code: Int
    ) -> HTTPStatus? {
        switch code {
        case 100: return .continue
        case 101: return .switchingProtocols
        case 102: return .processing
        case 103: return .earlyHints

        case 200: return .ok
        case 201: return .created
        case 202: return .accepted
        case 203: return .nonAuthoritativeInformation
        case 204: return .noContent
        case 205: return .resetContent
        case 206: return .partialContent
        case 207: return .multiStatus
        case 208: return .alreadyReported
        case 226: return .imUsed

        case 300: return .multipleChoices
        case 301: return .movedPermanently
        case 302: return .found
        case 303: return .seeOther
        case 304: return .notModified
        case 305: return .useProxy
        case 307: return .temporaryRedirect
        case 308: return .permanentRedirect

        case 400: return .badRequest
        case 401: return .unauthorized
        case 402: return .paymentRequired
        case 403: return .forbidden
        case 404: return .notFound
        case 405: return .methodNotAllowed
        case 406: return .notAcceptable
        case 407: return .proxyAuthenticationRequired
        case 408: return .requestTimeout
        case 409: return .conflict
        case 410: return .gone
        case 411: return .lengthRequired
        case 412: return .preconditionFailed
        case 413: return .contentTooLarge
        case 414: return .uriTooLong
        case 415: return .unsupportedMediaType
        case 416: return .rangeNotSatisfiable
        case 417: return .expectationFailed
        case 421: return .misdirectedRequest
        case 422: return .unprocessableContent
        case 423: return .locked
        case 424: return .failedDependency
        case 425: return .tooEarly
        case 426: return .upgradeRequired
        case 428: return .preconditionRequired
        case 429: return .tooManyRequests
        case 431: return .requestHeaderFieldsTooLarge
        case 451: return .unavailableForLegalReasons

        case 500: return .internalServerError
        case 501: return .notImplemented
        case 502: return .badGateway
        case 503: return .serviceUnavailable
        case 504: return .gatewayTimeout
        case 505: return .httpVersionNotSupported
        case 506: return .variantAlsoNegotiates
        case 507: return .insufficientStorage
        case 508: return .loopDetected
        case 511: return .networkAuthenticationRequired

        default:
            return nil
        }
    }

    public static func resolve(code: Int) -> HTTPStatus {
        standardFor(
            code: code
        ) ?? defaultFor(
            code: code
        )
    }

    public var family: HTTPStatusFamily {
        return .init(from: self)
    }
}

extension HTTPStatus: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        reason = try container.decode(String.self, forKey: .reason)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(reason, forKey: .reason)
    }
    
    private enum CodingKeys: String, CodingKey {
        case code, reason
    }
}
