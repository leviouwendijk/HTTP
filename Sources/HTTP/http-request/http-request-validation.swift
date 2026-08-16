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
            let requestTarget = requestLine.requestTarget
            let target = requestTarget.raw
            let version = requestLine.version

            guard let method = HTTPMethod(
                rawValue: methodString
            ) else {
                throw HTTPValidationError.unsupportedMethod(
                    methodString
                )
            }

            guard version == HTTPConstants.httpVersion else {
                throw HTTPValidationError.unsupportedHTTPVersion(
                    version
                )
            }

            do {
                try HTTPWireValidation.validateRequestTarget(
                    target
                )
            } catch HTTPWireValidationError.invalidRequestTarget(let target) {
                throw HTTPValidationError.invalidRequestTarget(
                    target
                )
            }

            try policies.target.validate(
                requestTarget
            )

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

                do {
                    try HTTPWireValidation.validateHeader(
                        name: name,
                        value: value
                    )
                } catch HTTPWireValidationError.invalidHeaderName(let name) {
                    throw HTTPValidationError.invalidHeaderName(
                        name
                    )
                } catch HTTPWireValidationError.invalidHeaderValue(let name, let value) {
                    throw HTTPValidationError.invalidHeaderValue(
                        name: name,
                        value: value
                    )
                }

                if lowercasedName == "transfer-encoding",
                   policies.headers.rejectTransferEncoding {
                    throw HTTPValidationError.forbiddenHeader(
                        name
                    )
                }

                if lowercasedName == HTTPConstants.contentLengthHeader.lowercased() {
                    do {
                        _ = try HTTPFraming.parseContentLengthValue(
                            value,
                            policy: policies.content
                        )
                    } catch HTTPParsingError.invalidContentLength(let value) {
                        throw HTTPValidationError.invalidContentLength(
                            value
                        )
                    } catch HTTPParsingError.contentLengthTooLarge(
                        let value,
                        let maximumBytes
                    ) {
                        throw HTTPValidationError.contentLengthTooLarge(
                            value: value,
                            maximumBytes: maximumBytes
                        )
                    }
                }

                if policies.headers.singletonHeaderNames.contains(
                    lowercasedName
                ) {
                    guard !seenSingletonHeaders.contains(
                        lowercasedName
                    ) else {
                        throw HTTPValidationError.duplicateHeader(
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

            let bodyBytes =
                parsed.body.utf8.count

            guard bodyBytes <= policies.content.maximumBytes else {
                throw HTTPValidationError.contentTooLarge(
                    actualBytes: bodyBytes,
                    maximumBytes: policies.content.maximumBytes
                )
            }

            return HTTPRequest(
                method: method,
                path: target,
                headers: headers,
                body: parsed.body
            )
        }
    }
}
