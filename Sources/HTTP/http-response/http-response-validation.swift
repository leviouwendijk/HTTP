import Foundation

public extension HTTPResponse {
    struct Validator: Sendable {
        public let headerPolicy: HTTPHeaderPolicy

        public init(
            headerPolicy: HTTPHeaderPolicy = HTTPHeaderPolicy.response.default
        ) {
            self.headerPolicy = headerPolicy
        }

        public func validate(
            _ parsed: Parsed
        ) throws -> HTTPResponse {
            let statusLine = parsed.statusLine

            guard statusLine.version == HTTPConstants.httpVersion else {
                throw HTTPParsingError.invalidStatusLine(
                    parsed.statusLineSource
                )
            }

            guard let statusCode = Int(
                statusLine.statusCode
            ) else {
                throw HTTPParsingError.invalidStatusCode(
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

                try HTTPWireValidation.validateHeader(
                    name: name,
                    value: value
                )

                if lowercasedName == HTTPConstants.contentLengthHeader.lowercased() {
                    _ = try HTTPFraming.parseContentLengthValue(
                        value
                    )
                }

                if headerPolicy.singletonHeaderNames.contains(
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

            return HTTPResponse(
                status: status,
                headers: headers,
                body: parsed.body
            )
        }
    }
}
