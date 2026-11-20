import Foundation
// import Structures
import Primitives
// import plate

public extension HTTPResponse {
    /// Create a JSON response from a dictionary of JSONValue
    static func json(
        _ object: [String: JSONValue],
        status: HTTPStatus = .ok,
        headers: [String: String] = [:]
    ) throws -> HTTPResponse {
        let json = try JSONValue.object(object).toJSONString()
        
        var h = HTTPHeaders(
            headers
        )

        h.contentType = "application/json; charset=utf-8"

        return HTTPResponse(status: status, headers: h, body: json)
    }
    
    /// Create a JSON response from a single JSONValue
    static func json(
        _ value: JSONValue,
        status: HTTPStatus = .ok,
        headers: [String: String] = [:]
    ) throws -> HTTPResponse {
        let json = try value.toJSONString()
        
        var h = HTTPHeaders(
            headers
        )

        h.contentType = "application/json; charset=utf-8"

        return HTTPResponse(status: status, headers: h, body: json)
    }
    
    /// Create a JSON response from an array of JSONValue
    static func json(
        _ array: [JSONValue],
        status: HTTPStatus = .ok,
        headers: [String: String] = [:]
    ) throws -> HTTPResponse {
        let json = try JSONValue.array(array).toJSONString()
        
        var h = HTTPHeaders(
            headers
        )

        h.contentType = "application/json; charset=utf-8"

        return HTTPResponse(status: status, headers: h, body: json)
    }
}
