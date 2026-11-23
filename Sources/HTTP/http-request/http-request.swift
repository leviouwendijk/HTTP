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

    /// Protocol version from the request line (`HTTP/1.1` or `HTTP/1.0`).
    public let version: String

    /// Body bytes as received. Binary payloads live here.
    public let bodyData: Data

    /// Address of the socket peer, set by the server.
    public private(set) var peerAddress: String?

    /// Client address resolved from the peer and trusted proxies, set by the server.
    public private(set) var clientAddress: String?

    /// UTF-8 view of `bodyData`, for textual bodies.
    public var body: String {
        String(
            decoding: bodyData,
            as: UTF8.self
        )
    }

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
        body: String = "",
        version: String = HTTPConstants.httpVersion
    ) {
        self.init(
            method: method,
            path: path,
            headers: headers,
            bodyData: Data(
                body.utf8
            ),
            version: version
        )
    }

    public init(
        method: HTTPMethod,
        path: String,
        headers: HTTPHeaders = HTTPHeaders(),
        bodyData: Data,
        version: String = HTTPConstants.httpVersion
    ) {
        self.method = method
        self.requestTarget =
            HTTPGrammar.RequestTarget.Output(
                raw: path
            )
        self.headers = headers
        self.bodyData = bodyData
        self.version = version
    }

    /// A copy carrying the socket peer and the client address resolved through `trustedProxies`.
    public func resolvingClient(
        peer: String,
        trustedProxies: HTTPTrustedProxies
    ) -> HTTPRequest {
        var copy = self
        copy.peerAddress = HTTPTrustedProxies.normalize(
            peer
        )
        copy.clientAddress = trustedProxies.resolveClient(
            peer: peer,
            headers: headers
        )
        return copy
    }

    /// Whether the connection may carry another request after this one.
    ///
    /// HTTP/1.1 persists unless `Connection: close`; HTTP/1.0 closes unless `Connection: keep-alive`.
    public var keepAlive: Bool {
        let tokens = connectionTokens

        if version == HTTPConstants.httpVersion10 {
            return tokens.contains(
                "keep-alive"
            ) && !tokens.contains(
                "close"
            )
        }

        return !tokens.contains(
            "close"
        )
    }

    /// Whether the client waits for `100 Continue` before sending the body.
    public var expectsContinue: Bool {
        guard let expect = header(
            "Expect"
        ) else {
            return false
        }

        return expect
            .trimmingCharacters(
                in: .whitespaces
            )
            .lowercased() == "100-continue"
    }

    private var connectionTokens: Set<String> {
        Set(
            headerValues(
                "Connection"
            )
            .flatMap {
                $0.split(
                    separator: ","
                )
            }
            .map {
                $0.trimmingCharacters(
                    in: .whitespaces
                )
                .lowercased()
            }
        )
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
        try decoder.decode(
            T.self,
            from: bodyData
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
        let json = try decoder.decode(
            [String: JSONValue].self,
            from: bodyData
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
        let json = try decoder.decode(
            [String: JSONValue].self,
            from: bodyData
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
