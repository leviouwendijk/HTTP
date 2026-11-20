import Foundation

public extension HTTPResponse {
    func header(
        _ name: String
    ) -> String? {
        headers.get(name)
    }

    func headerValues(
        _ name: String
    ) -> [String] {
        headers.values(
            for: name
        )
    }

    mutating func setHeader(
        _ name: String,
        _ value: String?
    ) {
        headers[name] = value
    }

    mutating func appendHeader(
        _ name: String,
        _ value: String
    ) {
        headers.append(
            name,
            value
        )
    }

    func hasHeader(
        _ name: String
    ) -> Bool {
        header(name) != nil
    }
}
