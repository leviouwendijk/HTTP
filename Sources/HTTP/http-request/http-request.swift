import Foundation
import Primitives

public struct HTTPRequest: Sendable {
    public let method: HTTPMethod

    private let requestTarget:
        HTTPGrammar.RequestTarget.Output

    public var target: String {
        requestTarget.raw
    }

    public var path: HTTPPath {
        requestTarget.path
    }

    public var query: HTTPQuery? {
        requestTarget.query
    }

    public let headers: HTTPHeaders
    public let body: String

    public init(
        method: HTTPMethod,
        path: String,
        headers: [String: String],
        body: String = ""
    ) {
        self.init(
            method: method,
            path: path,
            headers: HTTPHeaders(headers),
            body: body
        )
    }

    public init(
        method: HTTPMethod,
        path: String,
        headers: HTTPHeaders = HTTPHeaders(),
        body: String = ""
    ) {
        self.method = method
        self.requestTarget =
            HTTPGrammar.RequestTarget.Output(
                raw: path
            )
        self.headers = headers
        self.body = body
    }

    public func bearerToken() -> String? {
        guard let header = headers.authorization else {
            return nil
        }

        let prefix = "bearer "
        let lower = header.lowercased()

        guard lower.hasPrefix(prefix),
              header.count > prefix.count
        else {
            return nil
        }

        let tokenStart = header.index(
            header.startIndex,
            offsetBy: prefix.count
        )

        let token = header[tokenStart...].trimmingCharacters(
            in: .whitespaces
        )

        return token.isEmpty ? nil : token
    }

    public func authorizationHeader() -> String? {
        headers.authorization
    }

    public func header(
        _ name: String
    ) -> String? {
        headers.get(name)
    }

    public func headerValues(
        _ name: String
    ) -> [String] {
        headers.values(
            for: name
        )
    }
}

extension HTTPRequest {
    public func decode<T: Decodable>(
        _ type: T.Type,
        using decoder: JSONDecoder = HTTPJSONCoding.current.decoder()
    ) throws -> T {
        guard let data = body.data(
            using: .utf8
        ) else {
            throw HTTPParsingError.malformedHeaders
        }

        return try decoder.decode(
            T.self,
            from: data
        )
    }

    public func extract<T: Decodable>(
        _ type: T.Type,
        using decoder: JSONDecoder = HTTPJSONCoding.current.decoder()
    ) throws -> T {
        try self.decode(
            T.self,
            using: decoder
        )
    }

    public func key<T: Decodable>(
        _ key: String,
        as type: T.Type,
        using decoder: JSONDecoder = HTTPJSONCoding.current.decoder()
    ) throws -> T {
        guard let data = body.data(
            using: .utf8
        ) else {
            throw HTTPParsingError.malformedHeaders
        }

        let json = try decoder.decode(
            [String: JSONValue].self,
            from: data
        )

        guard let value = json[key] else {
            throw HTTPParsingError.malformedHeaders
        }

        let valueData = try JSONEncoder().encode(
            value
        )

        return try decoder.decode(
            T.self,
            from: valueData
        )
    }

    public func keys(
        _ keys: [String],
        using decoder: JSONDecoder = HTTPJSONCoding.current.decoder()
    ) throws -> [String: JSONValue] {
        guard let data = body.data(
            using: .utf8
        ) else {
            throw HTTPParsingError.malformedHeaders
        }

        let json = try decoder.decode(
            [String: JSONValue].self,
            from: data
        )

        var result: [String: JSONValue] = [:]

        for key in keys {
            if let value = json[key] {
                result[key] = value
            }
        }

        return result
    }
}
