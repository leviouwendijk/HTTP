import Foundation

@available(
    *,
    deprecated,
    message: "Use HTTPResponse(parsing:policies:) instead."
)
public struct HTTPResponseParser {
    public static func parse(
        _ raw: String,
        headerPolicy: HTTPHeaderPolicy = HTTPHeaderPolicy.response.default
    ) throws -> HTTPResponse {
        let defaults = HTTPPolicies.response.default

        return try HTTPResponse(
            parsing: raw,
            policies: HTTPResponsePolicies(
                headers: headerPolicy,
                content: defaults.content
            )
        )
    }

    public static func extractContentLength(
        from headerData: Data
    ) -> Int? {
        HTTPResponse.extractContentLength(
            from: headerData
        )
    }
}

// public struct HTTPResponseParser {
//     public static func parse(
//         _ raw: String,
//         headerPolicy: HTTPHeaderPolicy = HTTPHeaderPolicy.response.default
//     ) throws -> HTTPResponse {
//         guard let separatorRange = raw.range(
//             of: HTTPConstants.crlfCrLf
//         ) else {
//             throw HTTPParsingError.incompleteResponse
//         }

//         let head = String(
//             raw[..<separatorRange.lowerBound]
//         )

//         guard head.utf8.count <= headerPolicy.maximumHeaderBytes else {
//             throw HTTPParsingError.headerSectionTooLarge(
//                 maximumBytes: headerPolicy.maximumHeaderBytes
//             )
//         }

//         let body = String(
//             raw[separatorRange.upperBound...]
//         )

//         let headLines = head.components(
//             separatedBy: HTTPConstants.crlf
//         )

//         guard
//             let statusLine = headLines.first,
//             !statusLine.isEmpty
//         else {
//             throw HTTPParsingError.incompleteResponse
//         }

//         let status = try parseStatus(
//             from: statusLine
//         )

//         let headers = try parseHeaders(
//             from: headLines.dropFirst(),
//             policy: headerPolicy
//         )

//         return HTTPResponse(
//             status: status,
//             headers: headers,
//             body: body
//         )
//     }

//     private static func parseStatus(
//         from line: String
//     ) throws -> HTTPStatus {
//         let parts = line.split(
//             separator: " ",
//             maxSplits: 2,
//             omittingEmptySubsequences: true
//         )

//         guard
//             parts.count >= 2,
//             String(parts[0]) == HTTPConstants.httpVersion
//         else {
//             throw HTTPParsingError.invalidStatusLine(line)
//         }

//         guard let code = Int(parts[1]) else {
//             throw HTTPParsingError.invalidStatusCode(
//                 String(parts[1])
//             )
//         }

//         return HTTPStatus.resolve(
//             code: code
//         )
//     }

//     private static func parseHeaders(
//         from lines: ArraySlice<String>,
//         policy: HTTPHeaderPolicy
//     ) throws -> HTTPHeaders {
//         let nonEmptyLines = lines.filter {
//             !$0.isEmpty
//         }

//         guard nonEmptyLines.count <= policy.maximumHeaderCount else {
//             throw HTTPParsingError.tooManyHeaders(
//                 maximumCount: policy.maximumHeaderCount
//             )
//         }

//         var headers = HTTPHeaders()
//         var seenSingletonHeaders = Set<String>()

//         for line in nonEmptyLines {
//             guard line.utf8.count <= policy.maximumHeaderLineBytes else {
//                 throw HTTPParsingError.headerLineTooLarge(
//                     name: nil,
//                     maximumBytes: policy.maximumHeaderLineBytes
//                 )
//             }

//             guard let separatorIndex = line.firstIndex(
//                 of: Character(HTTPConstants.headerSeparator)
//             ) else {
//                 throw HTTPParsingError.malformedHeaders
//             }

//             let name = String(
//                 line[..<separatorIndex]
//             )
//             .trimmingCharacters(
//                 in: .whitespaces
//             )

//             let value = String(
//                 line[line.index(after: separatorIndex)...]
//             )
//             .trimmingCharacters(
//                 in: .whitespaces
//             )

//             let lowercasedName = name.lowercased()

//             try HTTPWireValidation.validateHeader(
//                 name: name,
//                 value: value
//             )

//             if lowercasedName == HTTPConstants.contentLengthHeader.lowercased() {
//                 _ = try HTTPFraming.parseContentLengthValue(value)
//             }

//             if policy.singletonHeaderNames.contains(lowercasedName) {
//                 guard !seenSingletonHeaders.contains(lowercasedName) else {
//                     throw HTTPParsingError.duplicateHeader(name)
//                 }

//                 seenSingletonHeaders.insert(lowercasedName)
//             }

//             headers.append(
//                 name,
//                 value
//             )
//         }

//         return headers
//     }

//     public static func extractContentLength(
//         from headerData: Data
//     ) -> Int? {
//         try? HTTPFraming.extractContentLength(
//             from: headerData
//         )
//     }
// }
