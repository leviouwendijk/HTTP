import Foundation

public extension HTTPResponse {
    /// Get a response header value case-insensitively.
    func header(
        _ name: String
    ) -> String? {
        headers.first {
            $0.key.lowercased() == name.lowercased()
        }?.value
    }

    /// Set, replace, or remove a response header case-insensitively.
    ///
    /// Passing `nil` removes all existing headers with the same case-insensitive name.
    mutating func setHeader(
        _ name: String,
        _ value: String?
    ) {
        let lowercasedName = name.lowercased()

        headers = headers.filter {
            $0.key.lowercased() != lowercasedName
        }

        if let value {
            headers[name] = value
        }
    }

    /// Return true when a response header exists case-insensitively.
    func hasHeader(
        _ name: String
    ) -> Bool {
        header(name) != nil
    }
}
