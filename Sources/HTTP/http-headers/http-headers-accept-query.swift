import Foundation

public struct HTTPAcceptQuery: Sendable, Hashable, Equatable {
    public struct Parameter: Sendable, Hashable, Equatable {
        public let name: String
        public let value: String

        public init?(
            name: String,
            value: String
        ) {
            let name = name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard HTTPAcceptQuery.isValidParameterName(
                name
            ) else {
                return nil
            }

            self.name = name
            self.value = value
        }
    }

    public struct MediaRange: Sendable, Hashable, Equatable {
        public let value: String
        public let parameters: [Parameter]

        public init?(
            _ value: String,
            parameters: [Parameter] = []
        ) {
            let value = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard HTTPAcceptQuery.isValidMediaRange(
                value
            ) else {
                return nil
            }

            self.value = value
            self.parameters = parameters
        }
    }

    public let mediaRanges: [MediaRange]

    public init(
        _ mediaRanges: [MediaRange]
    ) {
        self.mediaRanges = mediaRanges
    }

    public init?(
        rawValue: String
    ) {
        var parser = Parser(
            rawValue
        )

        guard let mediaRanges = parser.parse(),
              !mediaRanges.isEmpty
        else {
            return nil
        }

        self.mediaRanges = mediaRanges
    }

    public var rawValue: String {
        mediaRanges
            .map { mediaRange in
                var output = Self.quoted(
                    mediaRange.value
                )

                for parameter in mediaRange.parameters {
                    output += ";"
                    output += parameter.name
                    output += "="
                    output += Self.quoted(
                        parameter.value
                    )
                }

                return output
            }
            .joined(
                separator: ", "
            )
    }

    private static func quoted(
        _ value: String
    ) -> String {
        let escaped = value
            .replacingOccurrences(
                of: "\\",
                with: "\\\\"
            )
            .replacingOccurrences(
                of: "\"",
                with: "\\\""
            )

        return "\"\(escaped)\""
    }

    private static func isValidMediaRange(
        _ value: String
    ) -> Bool {
        let components = value.split(
            separator: "/",
            omittingEmptySubsequences: false
        )

        guard components.count == 2 else {
            return false
        }

        let type = String(
            components[0]
        )

        let subtype = String(
            components[1]
        )

        guard !type.isEmpty,
              !subtype.isEmpty
        else {
            return false
        }

        if type == "*" {
            return subtype == "*"
        }

        guard isValidMediaToken(
            type
        ) else {
            return false
        }

        if subtype == "*" {
            return true
        }

        return isValidMediaToken(
            subtype
        )
    }

    private static func isValidMediaToken(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        return value.unicodeScalars.allSatisfy { scalar in
            let value = scalar.value

            if (48...57).contains(value)
                || (65...90).contains(value)
                || (97...122).contains(value)
            {
                return true
            }

            switch value {
            case 33,
                 35,
                 36,
                 37,
                 38,
                 39,
                 43,
                 45,
                 46,
                 94,
                 95,
                 96,
                 124,
                 126:
                return true

            default:
                return false
            }
        }
    }

    private static func isValidParameterName(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty,
              value == value.lowercased()
        else {
            return false
        }

        for (
            index,
            scalar
        ) in value.unicodeScalars.enumerated() {
            let value = scalar.value

            if index == 0 {
                guard (97...122).contains(value)
                        || value == 42
                else {
                    return false
                }

                continue
            }

            if (97...122).contains(value)
                || (48...57).contains(value)
            {
                continue
            }

            switch value {
            case 42,
                 45,
                 46,
                 95:
                continue

            default:
                return false
            }
        }

        return true
    }
}

private extension HTTPAcceptQuery {
    struct Parser {
        private let characters: [Character]
        private var index = 0

        init(
            _ source: String
        ) {
            self.characters = Array(
                source
            )
        }

        mutating func parse() -> [MediaRange]? {
            skipWhitespace()

            var output: [MediaRange] = []

            while index < characters.count {
                guard let mediaRange = parseMediaRange() else {
                    return nil
                }

                output.append(
                    mediaRange
                )

                skipWhitespace()

                guard index < characters.count else {
                    break
                }

                guard characters[index] == "," else {
                    return nil
                }

                index += 1
                skipWhitespace()

                guard index < characters.count else {
                    return nil
                }
            }

            return output
        }

        private mutating func parseMediaRange() -> MediaRange? {
            guard let value = parseItemValue() else {
                return nil
            }

            var parameters: [Parameter] = []
            var parameterNames: Set<String> = []

            skipWhitespace()

            while index < characters.count,
                  characters[index] == ";"
            {
                index += 1
                skipWhitespace()

                guard let name = parseParameterName() else {
                    return nil
                }

                guard parameterNames.insert(
                    name
                ).inserted else {
                    return nil
                }

                skipWhitespace()

                guard index < characters.count,
                      characters[index] == "="
                else {
                    return nil
                }

                index += 1
                skipWhitespace()

                guard let value = parseItemValue(),
                      let parameter = Parameter(
                        name: name,
                        value: value
                      )
                else {
                    return nil
                }

                parameters.append(
                    parameter
                )

                skipWhitespace()
            }

            return MediaRange(
                value,
                parameters: parameters
            )
        }

        private mutating func parseParameterName() -> String? {
            let start = index

            while index < characters.count {
                let character = characters[index]

                if character == "="
                    || character == ";"
                    || character == ","
                    || character == " "
                    || character == "\t"
                {
                    break
                }

                index += 1
            }

            guard index > start else {
                return nil
            }

            return String(
                characters[start..<index]
            )
        }

        private mutating func parseItemValue() -> String? {
            guard index < characters.count else {
                return nil
            }

            if characters[index] == "\"" {
                return parseString()
            }

            let start = index

            while index < characters.count {
                let character = characters[index]

                if character == ";"
                    || character == ","
                    || character == " "
                    || character == "\t"
                {
                    break
                }

                index += 1
            }

            guard index > start else {
                return nil
            }

            return String(
                characters[start..<index]
            )
        }

        private mutating func parseString() -> String? {
            guard index < characters.count,
                  characters[index] == "\""
            else {
                return nil
            }

            index += 1

            var output = ""

            while index < characters.count {
                let character = characters[index]
                index += 1

                if character == "\"" {
                    return output
                }

                if character == "\\" {
                    guard index < characters.count else {
                        return nil
                    }

                    let escaped = characters[index]
                    index += 1

                    guard escaped == "\\"
                            || escaped == "\""
                    else {
                        return nil
                    }

                    output.append(
                        escaped
                    )
                    continue
                }

                output.append(
                    character
                )
            }

            return nil
        }

        private mutating func skipWhitespace() {
            while index < characters.count {
                let character = characters[index]

                guard character == " "
                        || character == "\t"
                else {
                    return
                }

                index += 1
            }
        }
    }
}

public extension HTTPHeaders {
    var acceptQuery: HTTPAcceptQuery? {
        get {
            let headerValues = values(
                for: "Accept-Query"
            )

            guard !headerValues.isEmpty else {
                return nil
            }

            return HTTPAcceptQuery(
                rawValue: headerValues.joined(
                    separator: ", "
                )
            )
        }
        set {
            guard let newValue else {
                remove(
                    "Accept-Query"
                )
                return
            }

            set(
                "Accept-Query",
                newValue.rawValue
            )
        }
    }
}
