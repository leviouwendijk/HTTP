public struct HTTPPolicies: Sendable {
    public struct RequestAPI: Sendable {
        public var `default`: HTTPRequestPolicies {
            HTTPRequestPolicies(
                headers: HTTPHeaderPolicy.request.default,
                content: .default,
                target: .default
            )
        }
    }

    public struct ResponseAPI: Sendable {
        public var `default`: HTTPResponsePolicies {
            HTTPResponsePolicies(
                headers: HTTPHeaderPolicy.response.default,
                content: .default
            )
        }
    }

    public static var request: RequestAPI {
        .init()
    }

    public static var response: ResponseAPI {
        .init()
    }
}
