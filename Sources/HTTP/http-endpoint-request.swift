public typealias HTTPReachable = HTTPRequestableEndpoint

public protocol HTTPRequestableEndpoint: HTTPRequestable {
    static var endpoint: HTTPEndpoint { get }
}
