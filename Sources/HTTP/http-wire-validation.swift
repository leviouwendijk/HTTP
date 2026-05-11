import Foundation

public enum HTTPWireValidationError: Error, LocalizedError, Sendable, Equatable {
    case invalidRequestTarget(String)
    case invalidHeaderName(String)
    case invalidHeaderValue(name: String, value: String)
    case invalidStatusCode(Int)
    case invalidStatusReason(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequestTarget(let target):
            return "Invalid HTTP request target: \(target.debugDescription)"

        case .invalidHeaderName(let name):
            return "Invalid HTTP header name: \(name.debugDescription)"

        case .invalidHeaderValue(let name, let value):
            return "Invalid HTTP header value for \(name.debugDescription): \(value.debugDescription)"

        case .invalidStatusCode(let code):
            return "Invalid HTTP status code: \(code)"

        case .invalidStatusReason(let reason):
            return "Invalid HTTP status reason: \(reason.debugDescription)"
        }
    }
}

public enum HTTPWireValidation {
    public static func validateRequestTarget(
        _ target: String
    ) throws {
        guard !target.isEmpty,
              target.first == "/",
              !containsLineBreakOrNUL(target),
              !target.contains(" "),
              !target.contains("\t")
        else {
            throw HTTPWireValidationError.invalidRequestTarget(target)
        }
    }

    public static func validateHeaderName(
        _ name: String
    ) throws {
        guard !name.isEmpty else {
            throw HTTPWireValidationError.invalidHeaderName(name)
        }

        for scalar in name.unicodeScalars {
            guard isHeaderTokenScalar(scalar) else {
                throw HTTPWireValidationError.invalidHeaderName(name)
            }
        }
    }

    public static func validateHeaderValue(
        _ value: String,
        name: String
    ) throws {
        for scalar in value.unicodeScalars {
            guard isHeaderValueScalar(scalar) else {
                throw HTTPWireValidationError.invalidHeaderValue(
                    name: name,
                    value: value
                )
            }
        }
    }

    public static func validateHeader(
        name: String,
        value: String
    ) throws {
        try validateHeaderName(name)
        try validateHeaderValue(
            value,
            name: name
        )
    }

    public static func validateHeaders<S: Sequence>(
        _ headers: S
    ) throws where S.Element == (String, String) {
        for (name, value) in headers {
            try validateHeader(
                name: name,
                value: value
            )
        }
    }

    public static func validateStatusCode(
        _ code: Int
    ) throws {
        guard (100...999).contains(code) else {
            throw HTTPWireValidationError.invalidStatusCode(code)
        }
    }

    public static func validateStatusReason(
        _ reason: String
    ) throws {
        guard !containsLineBreakOrNUL(reason) else {
            throw HTTPWireValidationError.invalidStatusReason(reason)
        }

        for scalar in reason.unicodeScalars {
            let value = scalar.value

            guard value == 0x09 || value >= 0x20, value != 0x7F else {
                throw HTTPWireValidationError.invalidStatusReason(reason)
            }
        }
    }

    public static func headerLine(
        name: String,
        value: String
    ) throws -> String {
        try validateHeader(
            name: name,
            value: value
        )

        return "\(name): \(value)"
    }

    public static func headerLines<S: Sequence>(
        _ headers: S
    ) throws -> [String] where S.Element == (String, String) {
        try headers.map {
            try headerLine(
                name: $0.0,
                value: $0.1
            )
        }
    }

    private static func containsLineBreakOrNUL(
        _ value: String
    ) -> Bool {
        value.unicodeScalars.contains {
            $0.value == 0x00 || $0.value == 0x0A || $0.value == 0x0D
        }
    }

    private static func isHeaderTokenScalar(
        _ scalar: Unicode.Scalar
    ) -> Bool {
        let value = scalar.value

        if (48...57).contains(value) {
            return true
        }

        if (65...90).contains(value) {
            return true
        }

        if (97...122).contains(value) {
            return true
        }

        switch scalar {
        case "!", "#", "$", "%", "&", "'", "*", "+", "-", ".", "^", "_", "`", "|", "~":
            return true

        default:
            return false
        }
    }

    private static func isHeaderValueScalar(
        _ scalar: Unicode.Scalar
    ) -> Bool {
        let value = scalar.value

        if value == 0x09 {
            return true
        }

        if value == 0x00 || value == 0x0A || value == 0x0D {
            return false
        }

        if value < 0x20 || value == 0x7F {
            return false
        }

        return true
    }
}
