import Foundation

public extension HTTPRequest {
    struct Validator: Sendable {
        public let policies: HTTPRequestPolicies

        public init(
            policies: HTTPRequestPolicies = HTTPPolicies.request.default
        ) {
            self.policies = policies
        }

        public func validate(
            _ parsed: Parsed
        ) throws -> HTTPRequest {
            let requestLine = parsed.requestLine
            let methodString = requestLine.method
            let path = requestLine.target
            let version = requestLine.version

            guard let method = HTTPMethod(
                rawValue: methodString
            ) else {
                throw HTTPParsingError.invalidMethod(
                    methodString
                )
            }

            guard version == HTTPConstants.httpVersion else {
                throw HTTPParsingError.invalidHTTPVersion(
                    version
                )
            }

            do {
                try HTTPWireValidation.validateRequestTarget(
                    path
                )

                try policies.target.validate(
                    path
                )
            } catch let error as HTTPParsingError {
                throw error
            } catch {
                throw HTTPParsingError.invalidRequestLine(
                    parsed.requestLineSource
                )
            }

            var headers = HTTPHeaders()
            var seenSingletonHeaders = Set<String>()

            for headerField in parsed.headerFields {
                let name = headerField.name.trimmingCharacters(
                    in: .whitespaces
                )

                let value = headerField.value.trimmingCharacters(
                    in: .whitespaces
                )

                let lowercasedName = name.lowercased()

                try HTTPWireValidation.validateHeader(
                    name: name,
                    value: value
                )

                if lowercasedName == "transfer-encoding",
                   policies.headers.rejectTransferEncoding {
                    throw HTTPParsingError.forbiddenHeader(
                        name
                    )
                }

                if lowercasedName == HTTPConstants.contentLengthHeader.lowercased() {
                    _ = try HTTPFraming.parseContentLengthValue(
                        value,
                        policy: policies.content
                    )
                }

                if policies.headers.singletonHeaderNames.contains(
                    lowercasedName
                ) {
                    guard !seenSingletonHeaders.contains(
                        lowercasedName
                    ) else {
                        throw HTTPParsingError.duplicateHeader(
                            name
                        )
                    }

                    seenSingletonHeaders.insert(
                        lowercasedName
                    )
                }

                headers.append(
                    name,
                    value
                )
            }

            return HTTPRequest(
                method: method,
                path: path,
                headers: headers,
                body: parsed.body
            )
        }
    }
}
