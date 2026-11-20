import Foundation

public extension HTTPResponse {
    struct Validator: Sendable {
        public let policies: HTTPResponsePolicies

        public init(
            policies: HTTPResponsePolicies = HTTPPolicies.response.default
        ) {
            self.policies = policies
        }

        public func validate(
            _ parsed: Parsed
        ) throws -> HTTPResponse {
            let statusLine = parsed.statusLine

            guard statusLine.version == HTTPConstants.httpVersion else {
                throw HTTPValidationError.unsupportedHTTPVersion(
                    statusLine.version
                )
            }

            guard let statusCode = Int(
                statusLine.statusCode
            ) else {
                throw HTTPValidationError.invalidStatusCode(
                    statusLine.statusCode
                )
            }

            let status = HTTPStatus.resolve(
                code: statusCode
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

            return HTTPResponse(
                status: status,
                headers: headers,
                body: parsed.body
            )
        }
    }
}
