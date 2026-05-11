import Foundation

public struct HTTPRequestParser {
    public static func parse(
        _ raw: String,
        headerPolicy: HTTPHeaderPolicy = .requestDefault,
        requestTargetPolicy: HTTPRequestTargetPolicy = .default
    ) throws -> HTTPRequest {
        guard let separatorRange = raw.range(
            of: HTTPConstants.crlfCrLf
        ) else {
            throw HTTPParsingError.incompleteRequest
        }

        let head = String(
            raw[..<separatorRange.lowerBound]
        )

        guard head.utf8.count <= headerPolicy.maximumHeaderBytes else {
            throw HTTPParsingError.headerSectionTooLarge(
                maximumBytes: headerPolicy.maximumHeaderBytes
            )
        }

        let body = String(
            raw[separatorRange.upperBound...]
        )

        let headLines = head.components(
            separatedBy: HTTPConstants.crlf
        )

        guard
            let requestLine = headLines.first,
            !requestLine.isEmpty
        else {
            throw HTTPParsingError.incompleteRequest
        }

        let parsedLine = try parseRequestLine(
            from: requestLine,
            requestTargetPolicy: requestTargetPolicy
        )

        let headers = try parseHeaders(
            from: headLines.dropFirst(),
            policy: headerPolicy
        )

        return HTTPRequest(
            method: parsedLine.method,
            path: parsedLine.path,
            headers: headers,
            body: body
        )
    }

    private static func parseRequestLine(
        from line: String,
        requestTargetPolicy: HTTPRequestTargetPolicy
    ) throws -> (method: HTTPMethod, path: String) {
        let parts = line.split(
            separator: " ",
            omittingEmptySubsequences: true
        )

        guard parts.count == 3 else {
            throw HTTPParsingError.invalidRequestLine(line)
        }

        let methodString = String(parts[0])
        let path = String(parts[1])
        let version = String(parts[2])

        guard let method = HTTPMethod(rawValue: methodString) else {
            throw HTTPParsingError.invalidMethod(methodString)
        }

        guard version == HTTPConstants.httpVersion else {
            throw HTTPParsingError.invalidHTTPVersion(version)
        }

        do {
            try HTTPWireValidation.validateRequestTarget(path)
            try requestTargetPolicy.validate(path)
        } catch let error as HTTPParsingError {
            throw error
        } catch {
            throw HTTPParsingError.invalidRequestLine(line)
        }

        return (
            method,
            path
        )
    }

    private static func parseHeaders(
        from lines: ArraySlice<String>,
        policy: HTTPHeaderPolicy
    ) throws -> HTTPHeaders {
        let nonEmptyLines = lines.filter {
            !$0.isEmpty
        }

        guard nonEmptyLines.count <= policy.maximumHeaderCount else {
            throw HTTPParsingError.tooManyHeaders(
                maximumCount: policy.maximumHeaderCount
            )
        }

        var headers = HTTPHeaders()
        var seenSingletonHeaders = Set<String>()

        for line in nonEmptyLines {
            guard line.utf8.count <= policy.maximumHeaderLineBytes else {
                throw HTTPParsingError.headerLineTooLarge(
                    name: nil,
                    maximumBytes: policy.maximumHeaderLineBytes
                )
            }

            guard let separatorIndex = line.firstIndex(
                of: Character(HTTPConstants.headerSeparator)
            ) else {
                throw HTTPParsingError.malformedHeaders
            }

            let name = String(
                line[..<separatorIndex]
            )
            .trimmingCharacters(
                in: .whitespaces
            )

            let value = String(
                line[line.index(after: separatorIndex)...]
            )
            .trimmingCharacters(
                in: .whitespaces
            )

            let lowercasedName = name.lowercased()

            try HTTPWireValidation.validateHeader(
                name: name,
                value: value
            )

            guard line.utf8.count <= policy.maximumHeaderLineBytes else {
                throw HTTPParsingError.headerLineTooLarge(
                    name: name,
                    maximumBytes: policy.maximumHeaderLineBytes
                )
            }

            if lowercasedName == "transfer-encoding",
               policy.rejectTransferEncoding {
                throw HTTPParsingError.forbiddenHeader(name)
            }

            if lowercasedName == HTTPConstants.contentLengthHeader.lowercased() {
                _ = try HTTPFraming.parseContentLengthValue(value)
            }

            if policy.singletonHeaderNames.contains(lowercasedName) {
                guard !seenSingletonHeaders.contains(lowercasedName) else {
                    throw HTTPParsingError.duplicateHeader(name)
                }

                seenSingletonHeaders.insert(lowercasedName)
            }

            headers.append(
                name,
                value
            )
        }

        return headers
    }

    public static func extractContentLength(
        from headerData: Data
    ) -> Int? {
        try? HTTPFraming.extractContentLength(
            from: headerData
        )
    }
}

// public struct HTTPRequestParser {
//     public static func parse(_ raw: String) throws -> HTTPRequest {
//         let parts = raw.components(separatedBy: HTTPConstants.crlfCrLf)
//         guard !parts.isEmpty else {
//             throw HTTPParsingError.incompleteRequest
//         }
        
//         let head = parts[0]
//         let body = parts.count > 1 ? parts[1] : ""
        
//         let headLines = head.split(
//             separator: Character(extendedGraphemeClusterLiteral: HTTPConstants.crlf.first ?? "\n"),
//             omittingEmptySubsequences: false
//         )
        
//         guard let requestLine = headLines.first else {
//             throw HTTPParsingError.incompleteRequest
//         }
        
//         let method = try parseMethod(from: requestLine)
//         let path = try parsePath(from: requestLine)
//         let headers = try parseHeaders(from: headLines.dropFirst())
        
//         return HTTPRequest(method: method, path: path, headers: headers, body: body)
//     }
    
//     private static func parseMethod(from line: Substring) throws -> HTTPMethod {
//         let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
//         guard parts.count >= 1 else {
//             throw HTTPParsingError.invalidRequestLine(String(line))
//         }
        
//         let methodStr = String(parts[0])
//         guard let method = HTTPMethod(rawValue: methodStr) else {
//             throw HTTPParsingError.invalidMethod(methodStr)
//         }
        
//         return method
//     }
    
//     private static func parsePath(from line: Substring) throws -> String {
//         let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
//         guard parts.count >= 2 else {
//             throw HTTPParsingError.invalidRequestLine(String(line))
//         }
        
//         return String(parts[1])
//     }
    
//     private static func parseHeaders(from lines: ArraySlice<Substring>) throws -> [String: String] {
//         var headers: [String: String] = [:]
        
//         for line in lines {
//             guard !line.isEmpty else { continue }
            
//             guard let idx = line.firstIndex(of: Character(HTTPConstants.headerSeparator)) else {
//                 throw HTTPParsingError.malformedHeaders
//             }
            
//             let key = String(line[..<idx]).trimmingCharacters(in: .whitespaces)
//             let value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            
//             headers[key] = value
//         }
        
//         return headers
//     }

//     public static func extractContentLength(from headerData: Data) -> Int? {
//         guard let text = String(data: headerData, encoding: .utf8) else { return nil }
        
//         let lines = text.split(separator: "\r\n")
//         for line in lines {
//             let lower = line.lowercased()
//             if lower.hasPrefix("content-length:") {
//                 let parts = line.split(separator: ":")
//                 if parts.count > 1 {
//                     let value = parts[1].trimmingCharacters(in: .whitespaces)
//                     return Int(value)
//                 }
//             }
//         }
//         return nil
//     }
// }
